// GymStatusHelper.swift
// Shared File (Targets Gym Tracker RC and Gym Tracker Widget)
//
// This helper determines the current gym status (open/closed) and provides
// the correct status string ("Until X:XX PM" or "Opens at X:XX AM").
// It also computes the next open day if the gym is currently closed.
//
// Changes made:
// - Improved logic when the gym is closed after its closing time:
//   Instead of always showing today's hours, it now fetches the next
//   open day's opening time.
// - If gym is closed but will open later today, it shows today's opening time.
// - Added a helper to compute a Date from a given weekday and time, allowing
//   correct handling of "next open day" scenarios.
// - The logic now ensures only the correct next open day is highlighted in the UI.
//

import Foundation

// Struct to hold gym status
struct GymStatus {
    let isOpen: Bool
    let status: String       // E.g., "Until 8:00 PM" or "Opens at 6:00 AM"
    let nextOpenDay: String? // If closed and not opening again today, the next open day
}

// Utility to handle gym open/close logic
struct GymStatusHelper {
    
    // Public method to get today's gym status
    static func getTodayGymStatus(
        for gymHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        currentTime: Date
    ) -> GymStatus {
        let calendar = Calendar.current
        let currentDay = getCurrentDayOfWeek(currentTime: currentTime)
        
        // weekdayIndex: Sunday = 0, Monday = 1, ... Saturday = 6
        // Adjusting since we have an ordered list of days (Mon-Sun)
        let weekdayIndex = calendar.component(.weekday, from: currentTime) - 1
        
        guard weekdayIndex >= 0 && weekdayIndex < gymHours.count else {
            return GymStatus(isOpen: false, status: "Invalid day index", nextOpenDay: nil)
        }
        
        // Find today's hours in the gymHours array
        // If not found, we consider today closed and look for the next open day
        guard let todayHours = gymHours.first(where: { $0.days == currentDay }) else {
            let nextOpenDay = getNextOpenDay(gymHours: gymHours, currentDay: currentDay)
            return GymStatus(isOpen: false, status: "Closed, reopens \(nextOpenDay ?? "soon")", nextOpenDay: nextOpenDay)
        }

        // Convert today's opening and closing times into Dates
        guard let openingDate = timeToDate(timeTuple: todayHours.openingTime, currentTime: currentTime),
              var closingDate = timeToDate(timeTuple: todayHours.closingTime, currentTime: currentTime) else {
            // If we can't determine today's hours, return a generic message
            return GymStatus(isOpen: false, status: "Hours unavailable", nextOpenDay: nil)
        }

        // If the closing time is earlier or equal to the opening time, it means the gym crosses midnight
        if closingDate <= openingDate {
            closingDate = calendar.date(byAdding: .day, value: 1, to: closingDate)!
        }
        
        // Determine if currently open
        let isOpen = currentTime >= openingDate && currentTime <= closingDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        if isOpen {
            // If open, show how long it's open until
            return GymStatus(
                isOpen: true,
                status: "Until \(dateFormatter.string(from: closingDate))",
                nextOpenDay: nil
            )
        } else {
            // Closed scenario:
            // Check if we are before today's opening time -> gym not opened yet today
            if currentTime < openingDate {
                // Gym will open later today
                return GymStatus(
                    isOpen: false,
                    status: "Opens at \(dateFormatter.string(from: openingDate))",
                    nextOpenDay: currentDay // Next open is actually today
                )
            } else {
                // It's after today's closing time, so we must find the next open day
                if let nextOpenDay = getNextOpenDay(gymHours: gymHours, currentDay: currentDay),
                   let nextOpenDayHours = gymHours.first(where: { $0.days == nextOpenDay }),
                   let nextOpeningDate = dateForDay(
                       dayName: nextOpenDay,
                       currentTime: currentTime,
                       hourMinute: nextOpenDayHours.openingTime
                   ) {
                    return GymStatus(
                        isOpen: false,
                        status: "Opens at \(dateFormatter.string(from: nextOpeningDate))",
                        nextOpenDay: nextOpenDay
                    )
                } else {
                    // No future open day found
                    return GymStatus(isOpen: false, status: "Closed, reopens soon", nextOpenDay: nil)
                }
            }
        }
    }

    // MARK: - Private Helper Methods

    // Convert (hour, minute) to a Date corresponding to today's date
    private static func timeToDate(timeTuple: (Int, Int), currentTime: Date) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentTime)
        components.hour = timeTuple.0
        components.minute = timeTuple.1
        return Calendar.current.date(from: components)
    }

    // Get the current day of the week (e.g., "Monday")
    static func getCurrentDayOfWeek(currentTime: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: currentTime)
    }

    // Determine the next open day if today is closed
    // Returns the next open day's name (e.g., "Tuesday") or nil if none found
    private static func getNextOpenDay(
        gymHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        currentDay: String
    ) -> String? {
        let orderedDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard let currentIndex = orderedDays.firstIndex(of: currentDay) else { return nil }

        for i in 1...orderedDays.count {
            let nextDayIndex = (currentIndex + i) % orderedDays.count
            let nextDay = orderedDays[nextDayIndex]
            if gymHours.contains(where: { $0.days == nextDay }) {
                return nextDay
            }
        }
        return nil // No next open day found
    }

    // Create a Date for the given dayName and time (hour, minute) relative to currentTime
    // This allows displaying the correct "Opens at" time for a future day
    private static func dateForDay(dayName: String, currentTime: Date, hourMinute: (Int, Int)) -> Date? {
        let orderedDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        guard let currentDayIndex = orderedDays.firstIndex(of: getCurrentDayOfWeek(currentTime: currentTime)),
              let targetDayIndex = orderedDays.firstIndex(of: dayName) else {
            return nil
        }

        // Compute how many days away the target day is from the current day
        var dayDifference = targetDayIndex - currentDayIndex
        if dayDifference < 0 {
            dayDifference += 7
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentTime)
        components.day = (components.day ?? 0) + dayDifference
        components.hour = hourMinute.0
        components.minute = hourMinute.1
        return Calendar.current.date(from: components)
    }
}

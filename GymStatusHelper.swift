import Foundation

// MARK: - Public Data Structures

struct GymStatus {
    let isOpen: Bool
    let status: String
    let nextOpenDay: String?
    let nextOpenTime: String?
}

enum NextOpening {
    case today(time: String)
    case tomorrow(time: String)
    case future(dayLabel: String, time: String)
    case noOpeningInTwoWeeks
}

// MARK: - Weekday Enum

enum Weekday: Int {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

struct GymStatusHelper {
    
    // MARK: - Private Types
    
    /// A unified representation of operating hours for a specific day.
    private struct OperatingHours {
        let openDate: Date
        let closeDate: Date
    }
    
    // MARK: - Static Properties
    
    private static let calendar: Calendar = {
        var c = Calendar.current
        // Uncomment and set if Monday should be the first day of the week
        // c.firstWeekday = 2
        return c
    }()
    
    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name, e.g., "Monday"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g., "Jan 31"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // e.g., "6:00 AM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // MARK: - Public Methods
    
    static func getTodayGymStatus(
        facilityId: String,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours],
        currentTime: Date
    ) -> GymStatus {
        
        let openStatus = isGymOpen(on: currentTime, facilityId: facilityId, defaultHours: defaultHours, adjustedHours: adjustedHours)
        
        if openStatus.isOpen {
            return GymStatus(
                isOpen: true,
                status: "Until \(openStatus.closingTime ?? "N/A")",
                nextOpenDay: nil,
                nextOpenTime: nil
            )
        } else {
            if let nextOpening = getNextOpeningDetails(facilityId: facilityId, defaultHours: defaultHours, adjustedHours: adjustedHours, currentTime: currentTime) {
                switch nextOpening {
                case .today(let time):
                    return GymStatus(
                        isOpen: false,
                        status: "Opens at \(time)",
                        nextOpenDay: "Today",
                        nextOpenTime: time
                    )
                case .tomorrow(let time):
                    return GymStatus(
                        isOpen: false,
                        status: "Opens at \(time)",
                        nextOpenDay: "Tomorrow",
                        nextOpenTime: time
                    )
                case .future(let dayLabel, let time):
                    return GymStatus(
                        isOpen: false,
                        status: "Opens \(dayLabel) at \(time)",
                        nextOpenDay: dayLabel,
                        nextOpenTime: time
                    )
                case .noOpeningInTwoWeeks:
                    return GymStatus(
                        isOpen: false,
                        status: "No openings in the next two weeks",
                        nextOpenDay: nil,
                        nextOpenTime: nil
                    )
                }
            } else {
                return GymStatus(
                    isOpen: false,
                    status: "Closed",
                    nextOpenDay: nil,
                    nextOpenTime: nil
                )
            }
        }
    }
    
    static func getWeeklyHoursAndDates(
        facilityId: String,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours],
        currentTime: Date
    ) -> [(label: String, hoursText: String, date: Date)] {
        
        var weeklyHours: [(label: String, hoursText: String, date: Date)] = []
        
        // Generate 14 days internally
        let totalDays = 14
        for offset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: currentTime) else { continue }
            let label = dayOfWeekFormatter.string(from: date)
            let hoursText = getHoursText(for: facilityId, date: date, defaultHours: defaultHours, adjustedHours: adjustedHours)
            weeklyHours.append((label: label, hoursText: hoursText, date: date))
        }
        
        // Keep only the first 7 days for display
        let displayDays = 7
        return Array(weeklyHours.prefix(displayDays))
    }
    
    static func computeEffectiveHighlightDate(
        facilityId: String,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours],
        currentTime: Date
    ) -> (date: Date, daysFromNow: Int)? {
        for dayOffset in 0..<14 {
            guard let candidate = calendar.date(byAdding: .day, value: dayOffset, to: currentTime) else { continue }
            if isGymOpen(on: candidate, facilityId: facilityId, defaultHours: defaultHours, adjustedHours: adjustedHours).isOpen {
                let daysFromNow = calendar.dateComponents([.day], from: calendar.startOfDay(for: currentTime), to: calendar.startOfDay(for: candidate)).day ?? 0
                return (candidate, daysFromNow)
            }
        }
        return nil
    }
    
    static func getNextOpeningDetails(
        facilityId: String,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours],
        currentTime: Date
    ) -> NextOpening? {
        
        // Check for a future opening time later today
        if let todayOpeningStr = getTodaysFutureOpeningTime(
            facilityId, defaultHours, adjustedHours, currentTime
        ) {
            return .today(time: todayOpeningStr)
        }
        
        // Search the next 14 days
        let startOfDay = calendar.startOfDay(for: currentTime)
        for dayOffset in 1..<14 { // 1 to 13 days ahead
            guard
                let candidate = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay),
                let openingStr = getOpeningTime(
                    facilityId: facilityId,
                    date: candidate,
                    defaultHours: defaultHours,
                    adjustedHours: adjustedHours
                )
            else {
                continue
            }
            
            let daysFromNow = calendar.dateComponents([.day], from: calendar.startOfDay(for: currentTime), to: calendar.startOfDay(for: candidate)).day ?? 0
            
            if daysFromNow == 1 {
                return .tomorrow(time: openingStr)
            } else {
                if dayOffset < 7 {
                    // Within the first 7 days, use day of week
                    let dayLabel = dayOfWeekFormatter.string(from: candidate)
                    return .future(dayLabel: dayLabel, time: openingStr)
                } else {
                    // Beyond 7 days, use abbreviated month and day
                    let dayLabel = monthDayFormatter.string(from: candidate)
                    return .future(dayLabel: dayLabel, time: openingStr)
                }
            }
        }
        
        // If no opening found in 14 days
        return .noOpeningInTwoWeeks
    }
    
    // MARK: - Private Helper Methods
    
    /// Returns the effective operating hours (open and close dates) for a given facility and day.
    private static func effectiveOperatingHours(
        for facilityId: String,
        on date: Date,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours]
    ) -> OperatingHours? {
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Check for an override first
        if let override = currentOverride(for: facilityId, on: normalizedDate, using: adjustedHours) {
            if override.isClosed {
                return nil
            }
            guard let (oH, oM) = override.openingTime,
                  let (cH, cM) = override.closingTime,
                  let (openDate, closeDate) = getOpenCloseDates(
                    openH: oH, openM: oM,
                    closeH: cH, closeM: cM,
                    currentTime: date
                  ) else {
                return nil
            }
            return OperatingHours(openDate: openDate, closeDate: closeDate)
        }
        
        // Use default hours based on the day of week
        let day = getDayOfWeekString(date).lowercased()
        guard let entry = defaultHours.first(where: { $0.days.lowercased() == day }),
              entry.hours.lowercased() != "closed",
              let (openDate, closeDate) = getOpenCloseDates(
                    openH: entry.openingTime.0, openM: entry.openingTime.1,
                    closeH: entry.closingTime.0, closeM: entry.closingTime.1,
                    currentTime: date
              ) else {
            return nil
        }
        return OperatingHours(openDate: openDate, closeDate: closeDate)
    }
    
    /// Determines if the gym is open at a specific date/time.
    private static func isGymOpen(
        on date: Date,
        facilityId: String,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours]
    ) -> (isOpen: Bool, closingTime: String?) {
        guard let hours = effectiveOperatingHours(for: facilityId, on: date, defaultHours: defaultHours, adjustedHours: adjustedHours) else {
            print("[DEBUG] Gym is closed.")
            return (false, nil)
        }
        
        print("[DEBUG] Operating hours -> open: \(hours.openDate), close: \(hours.closeDate)")
        
        if date >= hours.openDate && date < hours.closeDate {
            let formattedCloseTime = timeFormatter.string(from: hours.closeDate)
            print("[DEBUG] Gym is OPEN. Closing time: \(formattedCloseTime)")
            return (true, formattedCloseTime)
        }
        print("[DEBUG] Gym is CLOSED.")
        return (false, nil)
    }
    
    /// Returns a text representation of the operating hours for display.
    private static func getHoursText(
        for facilityId: String,
        date: Date,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours]
    ) -> String {
        if let hours = effectiveOperatingHours(for: facilityId, on: date, defaultHours: defaultHours, adjustedHours: adjustedHours) {
            return "\(formatTime(from: hours.openDate)) - \(formatTime(from: hours.closeDate))"
        }
        return "Closed"
    }
    
    /// If today’s opening time is still in the future, return it.
    private static func getTodaysFutureOpeningTime(
        _ facilityId: String,
        _ defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        _ adjustedHours: [AdjustedHours],
        _ currentTime: Date
    ) -> String? {
        if let hours = effectiveOperatingHours(for: facilityId, on: currentTime, defaultHours: defaultHours, adjustedHours: adjustedHours) {
            if hours.openDate > currentTime {
                return formatTime(from: hours.openDate)
            }
        }
        return nil
    }
    
    /// Returns the opening time for a given date.
    private static func getOpeningTime(
        facilityId: String,
        date: Date,
        defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))],
        adjustedHours: [AdjustedHours]
    ) -> String? {
        if let hours = effectiveOperatingHours(for: facilityId, on: date, defaultHours: defaultHours, adjustedHours: adjustedHours) {
            return formatTime(from: hours.openDate)
        }
        return nil
    }
    
    /// Formats a given hour and minute into a user-facing string.
    private static func formatTime(_ hour: Int, _ minute: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let date = calendar.date(from: comps) else { return "" }
        return timeFormatter.string(from: date)
    }
    
    /// Formats a Date into a user-facing string.
    private static func formatTime(from date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    /// Returns an active override for a given day (if any).
    private static func currentOverride(
        for facilityId: String,
        on date: Date,
        using overrides: [AdjustedHours]
    ) -> AdjustedHours? {
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard let todayOnlyDate = calendar.date(from: dayComponents) else { return nil }
        
        for override in overrides {
            guard override.facilityId == facilityId else { continue }
            
            // Convert the override’s start/end to actual Date
            guard
                let start = calendar.date(from: override.startDate),
                let end = calendar.date(from: override.endDate)
            else { continue }
            
            // Normalize to start of day
            let overrideStart = calendar.startOfDay(for: start)
            let overrideEnd = calendar.startOfDay(for: end)
            
            // Check if today is within the override range (inclusive)
            if (overrideStart...overrideEnd).contains(todayOnlyDate) {
                return override
            }
        }
        return nil
    }
    
    private static func getDayOfWeekString(_ date: Date) -> String {
        return dayOfWeekFormatter.string(from: date)
    }
    
    /// Returns open/close Date objects for the provided hours.
    private static func getOpenCloseDates(
        openH: Int,
        openM: Int,
        closeH: Int,
        closeM: Int,
        currentTime: Date
    ) -> (Date, Date)? {
        let startOfDay = calendar.startOfDay(for: currentTime)
        
        // Set opening time precisely
        guard let openDate = calendar.date(bySettingHour: openH, minute: openM, second: 0, of: startOfDay) else {
            return nil
        }
        
        // Set closing time precisely
        guard let closeDate = calendar.date(bySettingHour: closeH, minute: closeM, second: 0, of: startOfDay) else {
            return nil
        }
        
        // Handle cases where closing time is past midnight
        if closeDate <= openDate {
            guard let adjustedCloseDate = calendar.date(byAdding: .day, value: 1, to: closeDate) else {
                return nil
            }
            return (openDate, adjustedCloseDate)
        }
        
        return (openDate, closeDate)
    }
}

// MARK: - Private Extension for GymStatusHelper

private extension GymStatusHelper {
    func isGymOpen(on date: Date, facilityId: String, defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))], adjustedHours: [AdjustedHours]) -> (isOpen: Bool, closingTime: String?) {
        return GymStatusHelper.isGymOpen(on: date, facilityId: facilityId, defaultHours: defaultHours, adjustedHours: adjustedHours)
    }
}

//Constants.swift
//Shared File (Targets Gym Tracker RC and Gym Tracker Widget)

import Foundation

extension Int {
    /// e.g. 234 → "234", 1200 → "1.2k", 12345 → "12.3k"
    var abbreviatedCount: String {
        if self < 1000 { return "\(self)" }
        if self < 1_000_000 { return String(format: "%.1fk", Double(self) / 1000) }
        return String(format: "%.1fM", Double(self) / 1_000_000)
    }
}

struct Constants {
    // Facility IDs
    static let mcComasFacilityId = "da73849e-434d-415f-975a-4f9e799b9c39"
    static let warMemorialFacilityId = "55069633-b56e-43b7-a68a-64d79364988d"
    static let boulderingWallFacilityId = "da838218-ae53-4c6f-b744-2213299033fc"
    
    // Maximum capacities
    static let mcComasMaxCapacity = 600
    static let warMemorialMaxCapacity = 1200
    static let boulderingWallMaxCapacity = 8

    // VT Facility Occupancy API
    static let facilityDataAPIURL = URL(string: "https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData")!
    static let occupancyDisplayType = "00000000-0000-0000-0000-000000004490"

    // App Group (main app, widget, Watch)
    static let appGroupID = "group.VTGymApp.D8VXFBV8SJ"
    
    // MARK: - Date Formatters (cached to avoid expensive recreation)
    static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f
    }()
    
    static let eventDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.amSymbol = " AM"
        f.pmSymbol = " PM"
        return f
    }()
    
    static func formattedDateTwoWeeksAhead() -> String {
        let twoWeeksAhead = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return shortDateFormatter.string(from: twoWeeksAhead)
    }
    
    static func formattedEventStartDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        if calendar.isDateInToday(date) {
            eventDateFormatter.dateFormat = "'Today at' h:mma"
        } else if calendar.isDateInTomorrow(date) {
            eventDateFormatter.dateFormat = "'Tomorrow at' h:mma"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            eventDateFormatter.dateFormat = "EEEE 'at' h:mma"
        } else {
            eventDateFormatter.dateFormat = "EEEE, MMMM d 'at' h:mma"
        }
        return eventDateFormatter.string(from: date)
    }
}

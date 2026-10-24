import SwiftUI

/// Shared wording for class rows on the dashboard and in the schedule, so both read the same.
enum ClassRowText {
    /// "Now" (green) while the class runs, "In N min" (orange) shortly before, matching event rows.
    static func status(_ scheduled: ScheduledClass, now: Date) -> (text: String, color: Color)? {
        switch scheduled.status(at: now) {
        case .underway: return ("Now", Color("CustomGreen"))
        case .startingIn(let minutes): return ("In \(minutes) min", Color("CustomOrange"))
        case nil: return nil
        }
    }

    /// "Today", "Tomorrow", then "Sunday, Oct 25".
    static func dayTitle(_ day: Date, now: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(day, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    static func accessibilityLabel(_ scheduled: ScheduledClass, now: Date) -> String {
        let time = (scheduled.gymClass.start..<scheduled.gymClass.end).formatted(.interval.hour().minute())
        return [scheduled.gymClass.title, status(scheduled, now: now)?.text, time,
                scheduled.gymClass.room, scheduled.facility.name]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

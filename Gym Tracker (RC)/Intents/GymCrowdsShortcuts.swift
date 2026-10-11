import AppIntents

struct GymCrowdsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CurrentCrowdsIntent(), phrases: [
            "Check current crowds with \(.applicationName)",
            "Compare gyms with \(.applicationName)",
            "Check crowds at \(\.$facility) with \(.applicationName)",
            "How busy is \(\.$facility) in \(.applicationName)"
        ], shortTitle: "Current Crowds", systemImageName: "person.3")
        AppShortcut(intent: FindUpcomingEventsIntent(), phrases: [
            "Find upcoming events with \(.applicationName)",
            "Find recreation events with \(.applicationName)"
        ], shortTitle: "Upcoming Events", systemImageName: "calendar")
        AppShortcut(intent: GetEventDetailsIntent(), phrases: [
            "Get event details with \(.applicationName)",
            "Get details for \(\.$event) with \(.applicationName)"
        ], shortTitle: "Event Details", systemImageName: "calendar.badge.clock")
    }
}

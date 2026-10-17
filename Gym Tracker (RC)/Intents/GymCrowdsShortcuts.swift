import AppIntents

struct GymCrowdsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CurrentCrowdsIntent(), phrases: [
            "Check current crowds with \(.applicationName)",
            "Compare gyms with \(.applicationName)",
            "Check crowds at \(\.$facility) with \(.applicationName)",
            "How busy is \(\.$facility) in \(.applicationName)",
            "What are the crowds at \(\.$facility) with \(.applicationName)",
            "What are the crowds at \(\.$facility) in \(.applicationName)",
            "How crowded is \(\.$facility) with \(.applicationName)",
            "What is the occupancy at \(\.$facility) with \(.applicationName)",
            "Check the \(\.$facility) crowds with \(.applicationName)",
            "Check \(\.$facility) crowds with \(.applicationName)",
            "How busy is \(\.$facility) with \(.applicationName)",
            "What are the crowds like at \(\.$facility) using \(.applicationName)",
            "What are the crowds like at \(\.$facility) with \(.applicationName)",
            "How crowded is \(\.$facility) at \(.applicationName)",
            "What are the crowds like at \(.applicationName)",
            "How busy are the gyms at \(.applicationName)",
            "Check crowds at \(.applicationName)",
            "What are the crowds like using \(.applicationName)"
        ], shortTitle: "Current Crowds", systemImageName: "person.3")
        AppShortcut(intent: RecommendGymIntent(), phrases: [
            "Check which gym I should go to with \(.applicationName)",
            "Which gym should I go to with \(.applicationName)",
            "Which gym should I go to at \(.applicationName)",
            "Which gym is less crowded with \(.applicationName)",
            "Which gym is less crowded at \(.applicationName)",
            "Find a quieter gym with \(.applicationName)",
            "Help me choose a gym using \(.applicationName)"
        ], shortTitle: "Choose a Gym", systemImageName: "arrow.triangle.branch")
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

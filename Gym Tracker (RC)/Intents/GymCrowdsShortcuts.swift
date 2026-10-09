import AppIntents

struct GymCrowdsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CurrentCrowdsIntent(), phrases: [
            "Check current crowds with \(.applicationName)",
            "Compare gyms with \(.applicationName)",
            "Check crowds at \(\.$facility) with \(.applicationName)",
            "How busy is \(\.$facility) in \(.applicationName)"
        ], shortTitle: "Current Crowds", systemImageName: "person.3")
    }
}

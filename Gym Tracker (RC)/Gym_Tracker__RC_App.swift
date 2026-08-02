//
//  GymTrackerApp.swift
//  Gym Tracker
//
//  Created by Jack on 1/18/25.
//

import SwiftUI
import BackgroundTasks
import PostHog

enum PostHogEnv: String {
    case projectToken = "POSTHOG_PROJECT_TOKEN"
    case host = "POSTHOG_HOST"

    var value: String? {
        ProcessInfo.processInfo.environment[rawValue]?.nilIfEmpty
    }
}

@main
struct Gym_Tracker__RC_App: App {
    @StateObject private var alertManager = AlertManager()

    init() {
        configurePostHogIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alertManager)
        }
        .backgroundTask(.appRefresh("com.gymtracker.apprefresh")) { await runBackgroundRefresh() }
    }

    private func configurePostHogIfAvailable() {
        guard let projectToken = PostHogEnv.projectToken.value,
              let host = PostHogEnv.host.value
        else {
            return
        }

        let config = PostHogConfig(projectToken: projectToken, host: host)
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)
    }
}

private func runBackgroundRefresh() async {
    await GymService.shared.fetchAllGymOccupancy()
    scheduleAppRefresh()
}

func scheduleAppRefresh() {
    let req = BGAppRefreshTaskRequest(identifier: "com.gymtracker.apprefresh")
    req.earliestBeginDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
    try? BGTaskScheduler.shared.submit(req)
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

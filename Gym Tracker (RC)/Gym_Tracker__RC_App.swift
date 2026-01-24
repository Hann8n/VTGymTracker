//
//  GymTrackerApp.swift
//  Gym Tracker
//
//  Created by Jack on 1/18/25.
//

import SwiftUI
import BackgroundTasks

@main
struct Gym_Tracker__RC_App: App {
    @StateObject private var alertManager = AlertManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alertManager)
        }
        .backgroundTask(.appRefresh("com.gymtracker.apprefresh")) { await runBackgroundRefresh() }
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

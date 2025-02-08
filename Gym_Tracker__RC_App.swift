//
//  GymTrackerApp.swift
//  Gym Tracker
//
//  Created by Jack on 1/18/25.
//

import SwiftUI

@main
struct Gym_Tracker__RC_App: App {
    // We no longer rely on BrightnessManager,
    // so we remove any references to it.

    @StateObject private var alertManager = AlertManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alertManager) // Inject AlertManager globally
        }
    }
}

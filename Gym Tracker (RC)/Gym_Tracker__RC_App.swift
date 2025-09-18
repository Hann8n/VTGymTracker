//
//  GymTrackerApp.swift
//  Gym Tracker
//
//  Created by Jack on 1/18/25.
//

import SwiftUI

@main
struct Gym_Tracker__RC_App: App {
    @StateObject private var alertManager = AlertManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alertManager)
        }
    }
}

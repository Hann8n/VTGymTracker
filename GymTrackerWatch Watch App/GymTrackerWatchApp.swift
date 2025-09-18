//
//  GymTrackerWatchApp.swift
//  GymTrackerWatch Watch App
//
//  Created by Jack on 1/30/25.
//

import SwiftUI

struct WatchContentView: View {
    var body: some View {
        WatchFacilitiesView()
    }
}

@main
struct GymTrackerWatch_App: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

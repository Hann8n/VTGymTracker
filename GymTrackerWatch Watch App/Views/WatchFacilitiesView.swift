// WatchFacilitiesView.swift
// Gym Tracker Watch App

import SwiftUI

struct WatchFacilitiesView: View {
    @ObservedObject private var gymService = GymService.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    
    init() {
        let networkMonitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: networkMonitor)
    }
    
    var body: some View {
        TabView {
            // War Memorial Hall Card
            WatchGymCardView(
                title: "War Memorial Hall",
                occupancy: gymService.warMemorialOccupancy ?? 0,
                maxCapacity: Constants.warMemorialMaxCapacity,
                facilityId: Constants.warMemorialFacilityId,
                networkMonitor: networkMonitor,
                color: .green
            )
            
            // McComas Hall Card
            WatchGymCardView(
                title: "McComas Hall",
                occupancy: gymService.mcComasOccupancy ?? 0,
                maxCapacity: Constants.mcComasMaxCapacity,
                facilityId: Constants.mcComasFacilityId,
                networkMonitor: networkMonitor,
                color: .blue
            )
            
            // Bouldering Wall Card
            WatchGymCardView(
                title: "Bouldering Wall",
                occupancy: gymService.boulderingWallOccupancy ?? 0,
                maxCapacity: Constants.boulderingWallMaxCapacity,
                facilityId: Constants.boulderingWallFacilityId,
                networkMonitor: networkMonitor,
                color: .orange
            )
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear {
            Task {
                if networkMonitor.isConnected {
                    await gymService.fetchAllGymOccupancy()
                }
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, newValue in
            if newValue {
                Task { await gymService.fetchAllGymOccupancy() }
            }
        }
    }
}

struct WatchFacilitiesView_Previews: PreviewProvider {
    static var previews: some View {
        WatchFacilitiesView()
    }
}

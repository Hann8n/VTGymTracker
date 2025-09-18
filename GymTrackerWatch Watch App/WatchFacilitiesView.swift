// WatchFacilitiesView.swift
// Gym Tracker Watch App

import SwiftUI

struct WatchFacilitiesView: View {
    @ObservedObject private var gymService = GymService.shared
    
    var body: some View {
        NavigationView {
            List {
                // SECTION: War Memorial Hall (listed first)
                Section(header: Text("War Memorial Hall")) {
                    WatchUnifiedCard(
                        occupancy: gymService.warMemorialOccupancy ?? 0,
                        maxCapacity: Constants.warMemorialMaxCapacity,
                        facilityId: Constants.warMemorialFacilityId
                    )
                }
                
                // SECTION: McComas Hall
                Section(header: Text("McComas Hall")) {
                    WatchUnifiedCard(
                        occupancy: gymService.mcComasOccupancy ?? 0,
                        maxCapacity: Constants.mcComasMaxCapacity,
                        facilityId: Constants.mcComasFacilityId
                    )
                }
            }
            .onAppear {
                Task {
                    await gymService.fetchAllGymOccupancy()
                }
            }
        }
    }
}

struct WatchFacilitiesView_Previews: PreviewProvider {
    static var previews: some View {
        WatchFacilitiesView()
    }
}

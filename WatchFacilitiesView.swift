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
                        facilityId: Constants.warMemorialFacilityId,
                        defaultHours: Constants.warMemorialHours,
                        adjustedHours: warMemorialSpring2025AdjustedHours
                    )
                }
                
                // SECTION: McComas Hall
                Section(header: Text("McComas Hall")) {
                    WatchUnifiedCard(
                        occupancy: gymService.mcComasOccupancy ?? 0,
                        maxCapacity: Constants.mcComasMaxCapacity,
                        facilityId: Constants.mcComasFacilityId,
                        defaultHours: Constants.mcComasHours,
                        adjustedHours: mcComasSpring2025AdjustedHours
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

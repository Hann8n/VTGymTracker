//Constants.swift
//Shared File (Targets Gym Tracker RC and Gym Tracker Widget)

import Foundation

struct Constants {
    // Facility IDs
    static let mcComasFacilityId = "da73849e-434d-415f-975a-4f9e799b9c39"
    static let warMemorialFacilityId = "55069633-b56e-43b7-a68a-64d79364988d"
    static let boulderingWallFacilityId = "da838218-ae53-4c6f-b744-2213299033fc"
    
    // Maximum capacities
    static let mcComasMaxCapacity = 600
    static let warMemorialMaxCapacity = 1200
    static let boulderingWallMaxCapacity = 8

    // VT Facility Occupancy API
    static let facilityDataAPIURL = URL(string: "https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData")!
    static let occupancyDisplayType = "00000000-0000-0000-0000-000000004490"

    // App Group (main app, widget, Watch)
    static let appGroupID = "group.VTGymApp.D8VXFBV8SJ"
}

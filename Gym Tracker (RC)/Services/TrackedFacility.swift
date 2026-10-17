import Foundation

/// Fixed facility choices; identifiers and capacities remain in Constants.
enum TrackedFacility: String, CaseIterable, Sendable {
    case allFacilities, bothGyms, mcComas, warMemorial, boulderingWall

    static let individualFacilities: [Self] = [.mcComas, .warMemorial, .boulderingWall]
    static let gyms: [Self] = [.mcComas, .warMemorial]

    var facilities: [Self] {
        switch self {
        case .allFacilities: return Self.individualFacilities
        case .bothGyms: return Self.gyms
        default: return [self]
        }
    }

    var id: String {
        switch self {
        case .allFacilities: return "all"
        case .bothGyms: return "gyms"
        case .mcComas: return Constants.mcComasFacilityId
        case .warMemorial: return Constants.warMemorialFacilityId
        case .boulderingWall: return Constants.boulderingWallFacilityId
        }
    }

    var name: String {
        switch self {
        case .allFacilities: return "All Facilities"
        case .bothGyms: return "Both Gyms"
        case .mcComas: return "McComas Hall"
        case .warMemorial: return "War Memorial Hall"
        case .boulderingWall: return "Bouldering Wall"
        }
    }

    var capacity: Int {
        switch self {
        case .allFacilities, .bothGyms: return 0 // Selection only; never returned as a facility reading.
        case .mcComas: return Constants.mcComasMaxCapacity
        case .warMemorial: return Constants.warMemorialMaxCapacity
        case .boulderingWall: return Constants.boulderingWallMaxCapacity
        }
    }

    var occupancyKey: String { "\(rawValue)Occupancy" }
    var fetchDateKey: String { "\(rawValue)LastSuccessfulFetchAt" }

}

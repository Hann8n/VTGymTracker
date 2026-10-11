import Foundation

/// Fixed facility choices; identifiers and capacities remain in Constants.
enum TrackedFacility: String, CaseIterable, Sendable {
    case allFacilities, mcComas, warMemorial, boulderingWall

    static let individualFacilities: [Self] = [.mcComas, .warMemorial, .boulderingWall]

    var facilities: [Self] { self == .allFacilities ? Self.individualFacilities : [self] }

    var id: String {
        switch self {
        case .allFacilities: return "all"
        case .mcComas: return Constants.mcComasFacilityId
        case .warMemorial: return Constants.warMemorialFacilityId
        case .boulderingWall: return Constants.boulderingWallFacilityId
        }
    }

    var name: String {
        switch self {
        case .allFacilities: return "All Facilities"
        case .mcComas: return "McComas Hall"
        case .warMemorial: return "War Memorial Hall"
        case .boulderingWall: return "Bouldering Wall"
        }
    }

    var capacity: Int {
        switch self {
        case .allFacilities: return 0 // Selection only; never returned as a facility reading.
        case .mcComas: return Constants.mcComasMaxCapacity
        case .warMemorial: return Constants.warMemorialMaxCapacity
        case .boulderingWall: return Constants.boulderingWallMaxCapacity
        }
    }

    var occupancyKey: String { "\(rawValue)Occupancy" }
    var fetchDateKey: String { "\(rawValue)LastSuccessfulFetchAt" }

}

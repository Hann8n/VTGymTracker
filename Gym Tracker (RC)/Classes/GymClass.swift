import Foundation

/// One scheduled class in a gym studio, read from the gym's EMS room schedule.
struct GymClass: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let room: String
    let start: Date
    let end: Date

    func isUnderway(at now: Date) -> Bool { start <= now && now < end }
}

// MARK: - Sources

/// Which EMS schedule belongs to which gym; identifiers stay in Constants.
extension TrackedFacility {
    static let classScheduleFacilities: [Self] = [.warMemorial, .mcComas]

    var emsBuildingID: Int? {
        switch self {
        case .mcComas: return Constants.mcComasEMSBuildingID
        case .warMemorial: return Constants.warMemorialEMSBuildingID
        default: return nil
        }
    }

    var emsPage: String? {
        switch self {
        case .mcComas: return Constants.mcComasEMSPage
        case .warMemorial: return Constants.warMemorialEMSPage
        default: return nil
        }
    }
}

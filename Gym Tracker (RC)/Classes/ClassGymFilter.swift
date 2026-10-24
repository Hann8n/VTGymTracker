import Foundation

/// Which gyms' classes to show; remembered between launches so the dashboard and schedule agree.
enum ClassGymFilter: String, CaseIterable, Identifiable, Sendable {
    case all, warMemorial, mcComas

    static let storageKey = "classGymFilter"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .warMemorial: return "War Memorial"
        case .mcComas: return "McComas"
        }
    }

    var facilities: [TrackedFacility] {
        switch self {
        case .all: return TrackedFacility.classScheduleFacilities
        case .warMemorial: return [.warMemorial]
        case .mcComas: return [.mcComas]
        }
    }
}

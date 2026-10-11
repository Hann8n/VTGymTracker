import Foundation

/// A retrieval snapshot, never an assertion about the time RecSports measured the crowd.
struct OccupancySnapshot: Sendable {
    let facility: TrackedFacility
    let count: Int?
    let fetchedAt: Date?
    let checkedAt: Date
    let lastSuccessfulFetchAt: Date?
    let status: CrowdDataStatus
    let unavailableReason: String?

    var capacity: Int { facility.capacity }
    var fullnessPercent: Double? {
        count.map { OccupancyMath.percent(occupancy: $0, maxCapacity: capacity) }
    }
    // The endpoint publishes no measurement timestamp. HTTP Date is not one.
    var sourceMeasuredAt: Date? { nil }
    var cacheAgeSeconds: Double? {
        guard status == .cached, let fetchedAt else { return nil }
        return max(0, checkedAt.timeIntervalSince(fetchedAt))
    }
}

import Foundation

struct EventsSnapshot {
    let events: [Event]
    let status: EventsDataStatus
    let fetchedAt: Date?
    let checkedAt: Date
    let rejectedRecordCount: Int?
    let availabilityDetail: String?

    var cacheAgeSeconds: Double? {
        guard status == .cached, let fetchedAt else { return nil }
        return max(0, checkedAt.timeIntervalSince(fetchedAt))
    }
}

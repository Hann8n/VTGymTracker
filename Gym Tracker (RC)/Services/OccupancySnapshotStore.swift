import Foundation

/// Uses the existing app-group current values, with independent success dates.
/// No history, disk response cache, or migration from the ambiguous global lastFetchDate.
struct OccupancySnapshotStore {
    let defaults: UserDefaults?
    static let maximumReuseAge: TimeInterval = 90

    func read(_ facility: TrackedFacility, at now: Date) -> OccupancySnapshot {
        let last = defaults?.object(forKey: facility.fetchDateKey) as? Date
        let count = defaults?.object(forKey: facility.occupancyKey) as? Int
        let age = last.map { now.timeIntervalSince($0) }
        let usable = count.map { (0...facility.capacity).contains($0) } == true
            && age.map { $0 >= 0 && $0 <= Self.maximumReuseAge } == true
        return OccupancySnapshot(facility: facility, count: usable ? count : nil,
                                 fetchedAt: usable ? last : nil, checkedAt: now,
                                 lastSuccessfulFetchAt: last, status: usable ? .cached : .unavailable,
                                 unavailableReason: usable ? nil : "No recent verified reading")
    }

    /// Failures clear counts as before, but never advance or erase the last-success date.
    func write(_ snapshot: OccupancySnapshot) {
        if let count = snapshot.count, let fetchedAt = snapshot.fetchedAt {
            defaults?.set(count, forKey: snapshot.facility.occupancyKey)
            defaults?.set(fetchedAt, forKey: snapshot.facility.fetchDateKey)
        } else {
            defaults?.removeObject(forKey: snapshot.facility.occupancyKey)
        }
    }
}

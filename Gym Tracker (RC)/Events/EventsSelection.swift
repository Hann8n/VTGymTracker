import Foundation

struct EventsSelection {
    let events: [Event]
    let matchingCount: Int
    let from: Date
    let before: Date?
    let limit: Int

    init(snapshot: EventsSnapshot, from: Date?, before: Date?, limit: Int) throws {
        let lower = max(from ?? snapshot.checkedAt, snapshot.checkedAt)
        guard before.map({ $0 > lower }) ?? true else { throw EventsServiceError.invalidDateRange }
        guard (1...20).contains(limit) else { throw EventsServiceError.invalidLimit }
        // Half-open interval overlap: ongoing events are included; ended events are excluded.
        let ordered = snapshot.events.filter { event in
            event.endDate > lower && (before.map { upper in event.startDate < upper } ?? true)
        }.sorted {
            $0.startDate == $1.startDate ? $0.stableIdentifier < $1.stableIdentifier : $0.startDate < $1.startDate
        }
        events = Array(ordered.prefix(limit))
        matchingCount = ordered.count
        self.from = lower
        self.before = before
        self.limit = limit
    }
}

import Foundation

/// Uses the app's existing event cache. Legacy arrays have no verified retrieval time.
struct EventsCacheStore {
    let url: URL?
    static let maximumReuseAge: TimeInterval = 24 * 60 * 60

    static var shared: Self {
        let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true)
        return Self(url: directory?.appendingPathComponent("cachedEvents.json"))
    }

    private struct Envelope: Codable {
        let events: [Event]
        let fetchedAt: Date
        let rejectedRecordCount: Int
    }

    func write(_ snapshot: EventsSnapshot) {
        guard snapshot.status == .live, let url, let fetchedAt = snapshot.fetchedAt else { return }
        let value = Envelope(events: snapshot.events, fetchedAt: fetchedAt,
                             rejectedRecordCount: snapshot.rejectedRecordCount ?? 0)
        if let data = try? JSONEncoder().encode(value) { try? data.write(to: url, options: .atomic) }
    }

    func read(at now: Date, failure: String) -> EventsSnapshot {
        guard let url, let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              (0...Self.maximumReuseAge).contains(now.timeIntervalSince(envelope.fetchedAt)) else {
            return EventsSnapshot(events: [], status: .unavailable, fetchedAt: nil, checkedAt: now,
                                  rejectedRecordCount: nil, availabilityDetail: failure)
        }
        return EventsSnapshot(events: envelope.events.filter { $0.endDate > now }, status: .cached,
                              fetchedAt: envelope.fetchedAt, checkedAt: now,
                              rejectedRecordCount: envelope.rejectedRecordCount, availabilityDetail: failure)
    }

    /// Preserve the app's immediate legacy-cache display; Siri cannot label these records fresh.
    func loadForDisplay(at now: Date = Date()) -> [Event] {
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        let events = (try? decoder.decode(Envelope.self, from: data).events)
            ?? (try? decoder.decode([Event].self, from: data)) ?? []
        return events.filter { $0.endDate > now }
    }
}

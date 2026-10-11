import Foundation

enum GymOccupancyFetcher {
    static let liveSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    /// Siri always uses this real-data path, including in DEBUG. Tests inject URLSession.
    static func fetchSnapshots(
        facilities: [TrackedFacility] = TrackedFacility.individualFacilities,
        session: URLSession = liveSession,
        previous: [OccupancySnapshot] = [],
        now: @escaping @Sendable () -> Date = { Date() }
    ) async -> [OccupancySnapshot] {
        await withTaskGroup(of: (Int, OccupancySnapshot).self) { group in
            for (index, facility) in facilities.enumerated() where facility != .allFacilities {
                group.addTask {
                    let snapshot = await fetchOne(facility: facility, session: session,
                                                  previous: previous.first { $0.facility == facility }, now: now)
                    return (index, snapshot)
                }
            }
            var results: [(Int, OccupancySnapshot)] = []
            for await result in group { results.append(result) }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // Existing app/widget interfaces remain optional and retain their screenshot mock lane.
    static func fetchForWidget() async -> (mcComas: Int?, warMemorial: Int?, boulderingWall: Int?) {
        let result = await fetchAll()
        return (result.mcComas?.occupancy, result.warMemorial?.occupancy, result.bouldering?.occupancy)
    }

    static func fetchAll() async -> (
        mcComas: (occupancy: Int, remaining: Int)?,
        warMemorial: (occupancy: Int, remaining: Int)?,
        bouldering: (occupancy: Int, remaining: Int)?
    ) {
        if Constants.forceMockOccupancy {
            return ((Constants.mockMcComasOccupancy, Constants.mcComasMaxCapacity - Constants.mockMcComasOccupancy),
                    (Constants.mockWarMemorialOccupancy, Constants.warMemorialMaxCapacity - Constants.mockWarMemorialOccupancy),
                    (Constants.mockBoulderingWallOccupancy, Constants.boulderingWallMaxCapacity - Constants.mockBoulderingWallOccupancy))
        }
        let snapshots = await fetchSnapshots()
        let store = OccupancySnapshotStore(defaults: UserDefaults(suiteName: Constants.appGroupID))
        snapshots.filter { $0.status == .live }.forEach { store.write($0) }
        func values(_ facility: TrackedFacility) -> (occupancy: Int, remaining: Int)? {
            guard let count = snapshots.first(where: { $0.facility == facility })?.count else { return nil }
            return (count, facility.capacity - count)
        }
        return (values(.mcComas), values(.warMemorial), values(.boulderingWall))
    }

    private static func fetchOne(facility: TrackedFacility, session: URLSession,
                                 previous: OccupancySnapshot?, now: @Sendable () -> Date) async -> OccupancySnapshot {
        var failure = "Occupancy data unavailable"
        do {
            var request = URLRequest(url: Constants.facilityDataAPIURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 12
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "facilityId=\(facility.id)&occupancyDisplayType=\(Constants.occupancyDisplayType)".data(using: .utf8)
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let html = String(data: data, encoding: .utf8),
               let reading = OccupancyHTMLParser.parse(html, capacity: facility.capacity, facilityID: facility.id) {
                let date = now()
                return OccupancySnapshot(facility: facility, count: reading.occupancy, fetchedAt: date,
                                         checkedAt: date, lastSuccessfulFetchAt: date, status: .live, unavailableReason: nil)
            }
            failure = "RecSports returned no valid occupancy reading"
        } catch {
            failure = (error as? URLError)?.code == .timedOut ? "RecSports request timed out" : "Unable to reach RecSports"
        }
        let date = now()
        // Recheck age AFTER the network attempt; an initially recent value can expire while waiting.
        if let previous, let count = previous.count, let fetchedAt = previous.fetchedAt,
           (0...facility.capacity).contains(count),
           (0...OccupancySnapshotStore.maximumReuseAge).contains(date.timeIntervalSince(fetchedAt)) {
            return OccupancySnapshot(facility: facility, count: count, fetchedAt: fetchedAt,
                                     checkedAt: date, lastSuccessfulFetchAt: fetchedAt, status: .cached, unavailableReason: failure)
        }
        return OccupancySnapshot(facility: facility, count: nil, fetchedAt: nil, checkedAt: date,
                                 lastSuccessfulFetchAt: previous?.lastSuccessfulFetchAt,
                                 status: .unavailable, unavailableReason: failure)
    }
}

// MARK: - Shared (App Group) occupancy store

/// Last-known-good occupancy shared by the app and widgets. A failed fetch reuses a value
/// only while it is recent, so one bad response never flashes 0 but old counts never fossilize.
enum SharedOccupancyStore {
    static let freshness: TimeInterval = 15 * 60

    enum Key: String {
        case mcComas = "mcComasOccupancy"
        case warMemorial = "warMemorialOccupancy"
        case boulderingWall = "boulderingWallOccupancy"

        var dateKey: String { rawValue + "Date" }
    }

    static var defaults: UserDefaults? { UserDefaults(suiteName: Constants.appGroupID) }

    /// Stored value for `key` if it was fetched within `freshness`, else nil.
    static func fresh(_ key: Key) -> Int? {
        cached(key, maxAge: freshness)
    }

    /// Stored value for `key` if it was fetched within `maxAge`, else nil.
    static func cached(_ key: Key, maxAge: TimeInterval) -> Int? {
        guard let defaults,
              let date = defaults.object(forKey: key.dateKey) as? Date,
              (0..<maxAge).contains(Date().timeIntervalSince(date)),
              let count = defaults.object(forKey: key.rawValue) as? Int,
              let facility = TrackedFacility.individualFacilities.first(where: { $0.occupancyKey == key.rawValue }),
              (0...facility.capacity).contains(count)
        else { return nil }
        return count
    }

    /// Records a successful fetch, or clears the value once it is no longer fresh.
    static func record(_ value: Int?, for key: Key) {
        guard let defaults else { return }
        if let value {
            defaults.set(value, forKey: key.rawValue)
            let facility = TrackedFacility.individualFacilities.first { $0.occupancyKey == key.rawValue }
            let fetchedAt = facility.flatMap { defaults.object(forKey: $0.fetchDateKey) as? Date }
            // fetchAll already records each successful response's actual time. Never replace
            // that time with the later moment when all concurrent requests finish.
            defaults.set(Constants.forceMockOccupancy ? Date() : (fetchedAt ?? Date()), forKey: key.dateKey)
            if Constants.forceMockOccupancy, let facility {
                defaults.removeObject(forKey: facility.fetchDateKey)
            }
        } else if fresh(key) == nil {
            defaults.removeObject(forKey: key.rawValue)
            // Retain the actual last-success time when the current value expires.
        }
    }
}

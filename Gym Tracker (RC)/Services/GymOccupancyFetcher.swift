import Foundation

enum GymOccupancyFetcher {

    private static let urlSession: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        // Occupancy data must be fresh; caching would show stale counts
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    // Widgets only need occupancy count, not remaining capacity, to save space
    static func fetchForWidget() async -> (mcComas: Int?, warMemorial: Int?, boulderingWall: Int?) {
        if Constants.forceMockOccupancy {
            return (
                Constants.mockMcComasOccupancy,
                Constants.mockWarMemorialOccupancy,
                Constants.mockBoulderingWallOccupancy
            )
        }

        // Fetch all facilities concurrently for performance
        async let mc = fetchOne(facilityId: Constants.mcComasFacilityId, maxCapacity: Constants.mcComasMaxCapacity)
        async let wm = fetchOne(facilityId: Constants.warMemorialFacilityId, maxCapacity: Constants.warMemorialMaxCapacity)
        async let bw = fetchOne(facilityId: Constants.boulderingWallFacilityId, maxCapacity: Constants.boulderingWallMaxCapacity)
        let (m, w, b) = await (mc, wm, bw)
        return (m?.occupancy, w?.occupancy, b?.occupancy)
    }

    // Main app displays both occupancy and remaining capacity
    static func fetchAll() async -> (
        mcComas: (occupancy: Int, remaining: Int)?,
        warMemorial: (occupancy: Int, remaining: Int)?,
        bouldering: (occupancy: Int, remaining: Int)?
    ) {
        if Constants.forceMockOccupancy {
            return (
                mcComas: (
                    occupancy: Constants.mockMcComasOccupancy,
                    remaining: max(0, Constants.mcComasMaxCapacity - Constants.mockMcComasOccupancy)
                ),
                warMemorial: (
                    occupancy: Constants.mockWarMemorialOccupancy,
                    remaining: max(0, Constants.warMemorialMaxCapacity - Constants.mockWarMemorialOccupancy)
                ),
                bouldering: (
                    occupancy: Constants.mockBoulderingWallOccupancy,
                    remaining: max(0, Constants.boulderingWallMaxCapacity - Constants.mockBoulderingWallOccupancy)
                )
            )
        }

        // Fetch all facilities concurrently for performance
        async let mc = fetchOne(facilityId: Constants.mcComasFacilityId, maxCapacity: Constants.mcComasMaxCapacity)
        async let wm = fetchOne(facilityId: Constants.warMemorialFacilityId, maxCapacity: Constants.warMemorialMaxCapacity)
        async let bw = fetchOne(facilityId: Constants.boulderingWallFacilityId, maxCapacity: Constants.boulderingWallMaxCapacity)
        let (m, w, b) = await (mc, wm, bw)
        return (m, w, b)
    }

    private static func fetchOne(facilityId: String, maxCapacity: Int) async -> (occupancy: Int, remaining: Int)? {
        do {
            var req = URLRequest(url: Constants.facilityDataAPIURL)
            // API requires POST with form data, not a REST endpoint
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = "facilityId=\(facilityId)&occupancyDisplayType=\(Constants.occupancyDisplayType)".data(using: .utf8)
            let (data, response) = try await urlSession.data(for: req)
            guard let r = response as? HTTPURLResponse, (200...299).contains(r.statusCode) else { return nil }
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            guard let parsed = OccupancyHTMLParser.parse(html) else { return nil }
            return (parsed.occupancy, parsed.remaining ?? max(0, maxCapacity - parsed.occupancy))
        } catch {
            return nil
        }
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
              Date().timeIntervalSince(date) < maxAge,
              defaults.object(forKey: key.rawValue) != nil
        else { return nil }
        return defaults.integer(forKey: key.rawValue)
    }

    /// Records a successful fetch, or clears the value once it is no longer fresh.
    static func record(_ value: Int?, for key: Key) {
        guard let defaults else { return }
        if let value {
            defaults.set(value, forKey: key.rawValue)
            defaults.set(Date(), forKey: key.dateKey)
        } else if fresh(key) == nil {
            defaults.removeObject(forKey: key.rawValue)
            defaults.removeObject(forKey: key.dateKey)
        }
    }
}

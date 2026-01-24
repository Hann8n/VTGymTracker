import Foundation

/// VT RecSports API fetch + regex parse. Used by the widget; OccupancyHTMLParser extracts data-occupancy/data-remaining.
enum GymOccupancyFetcher {

    private static let urlSession: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    /// Widget: McComas, War Memorial, and Bouldering Wall. Returns occupancy per facility.
    static func fetchForWidget() async -> (mcComas: Int?, warMemorial: Int?, boulderingWall: Int?) {
        async let mc = fetchOne(facilityId: Constants.mcComasFacilityId)
        async let wm = fetchOne(facilityId: Constants.warMemorialFacilityId)
        async let bw = fetchOne(facilityId: Constants.boulderingWallFacilityId)
        let (m, w, b) = await (mc, wm, bw)
        return (m?.occupancy, w?.occupancy, b?.occupancy)
    }

    /// Main app: all three facilities. Returns (occupancy, remaining) per facility.
    static func fetchAll() async -> (
        mcComas: (occupancy: Int, remaining: Int)?,
        warMemorial: (occupancy: Int, remaining: Int)?,
        bouldering: (occupancy: Int, remaining: Int)?
    ) {
        async let mc = fetchOne(facilityId: Constants.mcComasFacilityId)
        async let wm = fetchOne(facilityId: Constants.warMemorialFacilityId)
        async let bw = fetchOne(facilityId: Constants.boulderingWallFacilityId)
        let (m, w, b) = await (mc, wm, bw)
        return (m, w, b)
    }

    private static func fetchOne(facilityId: String) async -> (occupancy: Int, remaining: Int)? {
        do {
            var req = URLRequest(url: Constants.facilityDataAPIURL)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = "facilityId=\(facilityId)&occupancyDisplayType=\(Constants.occupancyDisplayType)".data(using: .utf8)
            let (data, response) = try await urlSession.data(for: req)
            guard let r = response as? HTTPURLResponse, (200...299).contains(r.statusCode) else { return nil }
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            return parseOccupancy(html)
        } catch {
            return nil
        }
    }

    /// Parse canvas.occupancy-chart data-occupancy and data-remaining via OccupancyHTMLParser.
    private static func parseOccupancy(_ html: String) -> (occupancy: Int, remaining: Int)? {
        OccupancyHTMLParser.parse(html)
    }
}

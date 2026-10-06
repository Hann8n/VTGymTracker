// WatchGymService.swift
// Gym Tracker Watch App — fully independent occupancy fetching over watchOS networking.
// Does NOT depend on the iPhone app, WatchConnectivity, or App Groups
// (App Group defaults are per-device and do not sync iPhone <-> Watch).

import Foundation
import Combine

// MARK: - Watch-local constants (mirrors iOS Constants.swift values)

enum WatchGymConstants {
    static let mcComasFacilityId = "232d714e-5b3e-4b0d-9936-e6a738150ec4"
    static let warMemorialFacilityId = "55069633-b56e-43b7-a68a-64d79364988d"
    static let boulderingWallFacilityId = "da838218-ae53-4c6f-b744-2213299033fc"

    static let mcComasMaxCapacity = 600
    static let warMemorialMaxCapacity = 1200
    static let boulderingWallMaxCapacity = 8

    static let facilityDataAPIURL = URL(string: "https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData")!
    static let occupancyDisplayType = "00000000-0000-0000-0000-000000004490"
}

// MARK: - Watch-local math / formatting helpers

enum WatchOccupancyMath {
    static func percent(occupancy: Int, maxCapacity: Int) -> Double {
        guard maxCapacity > 0 else { return 0 }
        return min(max(Double(occupancy) / Double(maxCapacity), 0), 1) * 100
    }
}

extension Int {
    var watchAbbreviatedCount: String {
        if self < 1000 { return "\(self)" }
        if self < 1_000_000 { return String(format: "%.1fk", Double(self) / 1000) }
        return String(format: "%.1fM", Double(self) / 1_000_000)
    }
}

// MARK: - Watch-local occupancy service

@MainActor
final class WatchGymService: ObservableObject {
    static let shared = WatchGymService()

    @Published var mcComasOccupancy: Int?
    @Published var warMemorialOccupancy: Int?
    @Published var boulderingWallOccupancy: Int?
    @Published var isOnline: Bool = true

    private static let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        // Occupancy must be fresh; never cache
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    func fetchAllGymOccupancy() async {
        // Fetch all facilities concurrently for performance / battery
        async let mc = Self.fetchOne(facilityId: WatchGymConstants.mcComasFacilityId)
        async let wm = Self.fetchOne(facilityId: WatchGymConstants.warMemorialFacilityId)
        async let bw = Self.fetchOne(facilityId: WatchGymConstants.boulderingWallFacilityId)
        let (m, w, b) = await (mc, wm, bw)

        // If any facility succeeds, the API is reachable
        isOnline = m != nil || w != nil || b != nil

        if let m { mcComasOccupancy = m }
        if let w { warMemorialOccupancy = w }
        if let b { boulderingWallOccupancy = b }
    }

    private static func fetchOne(facilityId: String) async -> Int? {
        do {
            var request = URLRequest(url: WatchGymConstants.facilityDataAPIURL)
            // API requires POST with form data, not a REST endpoint
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "facilityId=\(facilityId)&occupancyDisplayType=\(WatchGymConstants.occupancyDisplayType)".data(using: .utf8)
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            return extractInt(html, attribute: "data-occupancy")
        } catch {
            return nil
        }
    }

    // Regex parsing avoids an HTML parser dependency; simple attribute extraction is sufficient
    private static func extractInt(_ html: String, attribute: String) -> Int? {
        let pattern = attribute + "=\"([0-9]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let capture = Range(match.range(at: 1), in: html) else { return nil }
        return Int(html[capture])
    }
}

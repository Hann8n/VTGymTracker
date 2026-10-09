// WatchGymService.swift
// Gym Tracker Watch App — fully independent occupancy fetching over watchOS networking.
// Does NOT depend on the iPhone app, WatchConnectivity, or App Groups
// (App Group defaults are per-device and do not sync iPhone <-> Watch).

import Foundation
import Combine

// MARK: - Shared verified facility constants

typealias WatchGymConstants = Constants

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

    func fetchAllGymOccupancy() async {
        let snapshots = await GymOccupancyFetcher.fetchSnapshots()
        isOnline = snapshots.contains { $0.status == .live }
        mcComasOccupancy = snapshots.first { $0.facility == .mcComas }?.count
        warMemorialOccupancy = snapshots.first { $0.facility == .warMemorial }?.count
        boulderingWallOccupancy = snapshots.first { $0.facility == .boulderingWall }?.count
    }

}

//
//  GymService.swift
//  Shared File (Targets Gym Tracker RC and Gym Tracker Widget)
//
//  Created by Jack on 1/30/25.
//

import Foundation
import Combine
import WidgetKit

#if canImport(UIKit)
import UIKit
#endif

enum GymServiceError: Error {
    case invalidURL
    case invalidResponse
    case htmlParsingError
    case dataConversionError
}

// MARK: - Struct to Hold Gym Occupancy Data
struct GymOccupancyData {
    let occupancy: Int
    let remaining: Int
}

@MainActor
class GymService: ObservableObject {
    static let shared = GymService()
    
    @Published var mcComasOccupancy: Int? = nil
    @Published var warMemorialOccupancy: Int? = nil
    @Published var boulderingWallOccupancy: Int? = nil
    @Published var isOnline: Bool = true
    
    // MARK: - Computed Properties for Remaining Capacity
    
    /// Returns remaining capacity for McComas Hall
    var mcComasRemaining: Int {
        guard let occupancy = mcComasOccupancy else { return Constants.mcComasMaxCapacity }
        return max(0, Constants.mcComasMaxCapacity - occupancy)
    }
    
    /// Returns remaining capacity for War Memorial Hall
    var warMemorialRemaining: Int {
        guard let occupancy = warMemorialOccupancy else { return Constants.warMemorialMaxCapacity }
        return max(0, Constants.warMemorialMaxCapacity - occupancy)
    }
    
    /// Returns remaining capacity for Bouldering Wall
    var boulderingWallRemaining: Int {
        guard let occupancy = boulderingWallOccupancy else { return Constants.boulderingWallMaxCapacity }
        return max(0, Constants.boulderingWallMaxCapacity - occupancy)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private var activeAppCancellable: AnyCancellable?
    // 30-second interval balances data freshness with battery and network usage
    private let activeAppInterval: TimeInterval = 30
    
    // Launch shows the last stored counts until the first live fetch replaces them
    // (instead of a placeholder 0); older than this, the card shows a spinner instead.
    private let launchCacheMaxAge: TimeInterval = 12 * 60 * 60

    private init() {
        mcComasOccupancy = SharedOccupancyStore.cached(.mcComas, maxAge: launchCacheMaxAge)
        warMemorialOccupancy = SharedOccupancyStore.cached(.warMemorial, maxAge: launchCacheMaxAge)
        boulderingWallOccupancy = SharedOccupancyStore.cached(.boulderingWall, maxAge: launchCacheMaxAge)
        setupAppLifecycleNotifications()
    }
    
    private func startActiveAppFetching() {
        guard activeAppCancellable == nil else { return }
        activeAppCancellable = Timer.publish(every: activeAppInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    guard let self = self else { return }
                    if self.isOnline {
                        await self.fetchAllGymOccupancy()
                    }
                }
            }
    }
    
    private func stopActiveAppFetching() {
        activeAppCancellable?.cancel()
        activeAppCancellable = nil
    }
    
    // MARK: - iOS Lifecycle
    
    private func setupAppLifecycleNotifications() {
    #if os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.startActiveAppFetching()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.stopActiveAppFetching()
            }
            .store(in: &cancellables)
    #endif
    }
    
    // MARK: - Main Fetch
    
    func fetchAllGymOccupancy() async {
        let (mc, wm, bw) = await GymOccupancyFetcher.fetchAll()

        // If any facility succeeds, API is reachable; only mark offline if all fail
        isOnline = mc != nil || wm != nil || bw != nil
        storeAndNotify(mcComas: mc?.occupancy, warMemorial: wm?.occupancy, boulderingWall: bw?.occupancy)

        if !isOnline {
            print("No occupancy data fetched successfully, scheduling retry...")
            // Retry after 60 seconds to handle transient network failures without immediate retry loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                Task {
                    await self?.fetchAllGymOccupancy()
                }
            }
        }
    }

    // MARK: - Store & Notify
    
    private func storeAndNotify(mcComas: Int?, warMemorial: Int?, boulderingWall: Int?) {
        // A single failed facility request keeps its last good value while recent, instead of
        // dropping to nil (rendered as 0). Read before recording so the fallback is the prior value.
        self.mcComasOccupancy = mcComas ?? SharedOccupancyStore.fresh(.mcComas)
        self.warMemorialOccupancy = warMemorial ?? SharedOccupancyStore.fresh(.warMemorial)
        self.boulderingWallOccupancy = boulderingWall ?? SharedOccupancyStore.fresh(.boulderingWall)
        
        // App Group UserDefaults allows widgets to access latest occupancy data
        SharedOccupancyStore.record(mcComas, for: .mcComas)
        SharedOccupancyStore.record(warMemorial, for: .warMemorial)
        SharedOccupancyStore.record(boulderingWall, for: .boulderingWall)

        if mcComas != nil || warMemorial != nil || boulderingWall != nil {
            SharedOccupancyStore.defaults?.set(Date(), forKey: "lastFetchDate")
        }

        // Notify widgets immediately when new data arrives (iOS only;
        // watchOS fetches directly over its own network connection and
        // App Group defaults are per-device, not synced iPhone <-> Watch)
        #if !os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        activeAppCancellable?.cancel()
    }
}

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
    
    // Published properties for in-app display (if you need them)
    @Published var mcComasOccupancy: Int? = nil
    @Published var warMemorialOccupancy: Int? = nil
    @Published var boulderingWallOccupancy: Int? = nil
    @Published var isOnline: Bool = true
    
    // **Custom Occupancy Properties**
    @Published var useCustomOccupancy: Bool = false
    @Published var customMcComasOccupancy: Int? = 275
    @Published var customWarMemorialOccupancy: Int? = 1025
    @Published var customBoulderingWallOccupancy: Int? = 6
    
    private var cancellables = Set<AnyCancellable>()
    
    // 30-second refresh while app is in foreground
    private var activeAppCancellable: AnyCancellable?
    private let activeAppInterval: TimeInterval = 30
    
    private init() {
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
        let mcData = mc.map { GymOccupancyData(occupancy: $0.occupancy, remaining: $0.remaining) }
        let wmData = wm.map { GymOccupancyData(occupancy: $0.occupancy, remaining: $0.remaining) }
        let bwData = bw.map { GymOccupancyData(occupancy: $0.occupancy, remaining: $0.remaining) }

        isOnline = mc != nil || wm != nil || bw != nil
        storeAndNotify(mcComasData: mcData, warMemorialData: wmData, boulderingWallData: bwData)

        if !isOnline {
            print("No occupancy data fetched successfully, scheduling retry...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                Task {
                    await self?.fetchAllGymOccupancy()
                }
            }
        }
    }

    // MARK: - Store & Notify in one place
    
    private func storeAndNotify(mcComasData: GymOccupancyData?, warMemorialData: GymOccupancyData?, boulderingWallData: GymOccupancyData?) {
        
        // 1. Update your in-app Published vars (if needed)
        self.mcComasOccupancy = useCustomOccupancy ? customMcComasOccupancy : mcComasData?.occupancy
        self.warMemorialOccupancy = useCustomOccupancy ? customWarMemorialOccupancy : warMemorialData?.occupancy
        self.boulderingWallOccupancy = useCustomOccupancy ? customBoulderingWallOccupancy : boulderingWallData?.occupancy
        
        // 2. Store the latest data in App Group (for widget)
        guard let sharedDefaults = UserDefaults(suiteName: Constants.appGroupID) else {
            print("Could not access shared defaults.")
            return
        }
        
        // McComas
        let mcOccupancyToStore = useCustomOccupancy ? customMcComasOccupancy : mcComasData?.occupancy
        if let mc = mcOccupancyToStore {
            sharedDefaults.set(mc, forKey: "mcComasOccupancy")
        }

        // War
        let warOccupancyToStore = useCustomOccupancy ? customWarMemorialOccupancy : warMemorialData?.occupancy
        if let wm = warOccupancyToStore {
            sharedDefaults.set(wm, forKey: "warMemorialOccupancy")
        }

        // Bouldering Wall
        let boulderingWallOccupancyToStore = useCustomOccupancy ? customBoulderingWallOccupancy : boulderingWallData?.occupancy
        if let bw = boulderingWallOccupancyToStore {
            sharedDefaults.set(bw, forKey: "boulderingWallOccupancy")
        }

        // Tell WidgetKit to reload
        WidgetCenter.shared.reloadAllTimelines()
        
        print("New data stored and WidgetKit notified.")
    }
    
    // MARK: - Custom Occupancy Methods
    
    func setCustomOccupancies(mcComas: Int?, warMemorial: Int?, boulderingWall: Int?) {
        customMcComasOccupancy = mcComas
        customWarMemorialOccupancy = warMemorial
        customBoulderingWallOccupancy = boulderingWall
        useCustomOccupancy = true
    }
    
    func clearCustomOccupancies() {
        customMcComasOccupancy = nil
        customWarMemorialOccupancy = nil
        customBoulderingWallOccupancy = nil
        useCustomOccupancy = false
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        activeAppCancellable?.cancel()
    }
}

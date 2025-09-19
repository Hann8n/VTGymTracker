//
//  GymService.swift
//  Shared File (Targets Gym Tracker RC and Gym Tracker Widget)
//
//  Created by Jack on 1/30/25.
//

import Foundation
import Combine
import SwiftSoup
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
    
    private let facilityDataAPIURL = URL(string: "https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData")!
    private let occupancyDisplayType = "00000000-0000-0000-0000-000000004490"
    private var cancellables = Set<AnyCancellable>()
    
    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
    
    // 30-second refresh while app is in foreground
    private var activeAppCancellable: AnyCancellable?
    private let activeAppInterval: TimeInterval = 30
    
    // For widget refresh, just run on a 15-min cycle
    // and/or let the system re-request from the widget extension
    private let appGroupID = "group.VTGymApp.D8VXFBV8SJ"
    
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
    
    // New efficient method using the API endpoint
    func fetchAllGymOccupancy() async {
        // Fetch each facility individually using the API endpoint
        let warMemorialFacilityId = Constants.warMemorialFacilityId
        let mcComasFacilityId = Constants.mcComasFacilityId
        let boulderingWallFacilityId = Constants.boulderingWallFacilityId
        
        async let warMemorialData = fetchFacilityOccupancy(facilityId: warMemorialFacilityId)
        async let mcComasData = fetchFacilityOccupancy(facilityId: mcComasFacilityId)
        async let boulderingWallData = fetchFacilityOccupancy(facilityId: boulderingWallFacilityId)
        
        let (warMemorial, mcComas, boulderingWall) = await (warMemorialData, mcComasData, boulderingWallData)
        
        // Update online status based on whether any requests succeeded
        isOnline = warMemorial != nil || mcComas != nil || boulderingWall != nil
        
        // Store and notify with the fetched data
        storeAndNotify(mcComasData: mcComas, warMemorialData: warMemorial, boulderingWallData: boulderingWall)
        
        // If no data was fetched successfully, schedule a retry
        if !isOnline {
            print("No occupancy data fetched successfully, scheduling retry...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                Task {
                    await self?.fetchAllGymOccupancy()
                }
            }
        }
    }
    
    // New method to fetch individual facility data using the API
    private func fetchFacilityOccupancy(facilityId: String) async -> GymOccupancyData? {
        do {
            var request = URLRequest(url: facilityDataAPIURL)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "facilityId=\(facilityId)&occupancyDisplayType=\(occupancyDisplayType)".data(using: .utf8)
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw GymServiceError.invalidResponse
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw GymServiceError.dataConversionError
            }
            
            // Parse the HTML fragment response
            return parseHTMLForOccupancy(htmlString, facilityId: facilityId)
            
        } catch {
            print("Error fetching facility \(facilityId): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func parseHTMLForOccupancy(_ html: String, facilityId: String) -> GymOccupancyData? {
        do {
            let document = try SwiftSoup.parse(html)
            
            // API responses return HTML fragments with canvas elements
            guard let canvas = try document.select("canvas.occupancy-chart").first() else {
                throw GymServiceError.htmlParsingError
            }
            
            let occupancyStr = try canvas.attr("data-occupancy")
            let remainingStr = try canvas.attr("data-remaining")
            
            guard let occupancy = Int(occupancyStr),
                  let remaining = Int(remainingStr)
            else {
                throw GymServiceError.dataConversionError
            }
            
            return GymOccupancyData(occupancy: occupancy, remaining: remaining)
        } catch {
            print("Error parsing HTML for facility \(facilityId): \(error)")
            return nil
        }
    }
    
    // MARK: - Store & Notify in one place
    
    private func storeAndNotify(mcComasData: GymOccupancyData?, warMemorialData: GymOccupancyData?, boulderingWallData: GymOccupancyData?) {
        
        // 1. Update your in-app Published vars (if needed)
        self.mcComasOccupancy = useCustomOccupancy ? customMcComasOccupancy : mcComasData?.occupancy
        self.warMemorialOccupancy = useCustomOccupancy ? customWarMemorialOccupancy : warMemorialData?.occupancy
        self.boulderingWallOccupancy = useCustomOccupancy ? customBoulderingWallOccupancy : boulderingWallData?.occupancy
        
        // 2. Store the latest data in App Group (for widget)
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("Could not access shared defaults.")
            return
        }
        
        // McComas
        let mcOccupancyToStore = useCustomOccupancy ? customMcComasOccupancy : mcComasData?.occupancy
        let mcRemainingToStore = mcComasData?.remaining
        if let mc = mcOccupancyToStore {
            sharedDefaults.set(mc, forKey: "mcComasOccupancy")
        }
        if let mcRem = mcRemainingToStore {
            sharedDefaults.set(mcRem, forKey: "mcComasRemaining")
        }
        
        // War
        let warOccupancyToStore = useCustomOccupancy ? customWarMemorialOccupancy : warMemorialData?.occupancy
        let warRemainingToStore = warMemorialData?.remaining
        if let wm = warOccupancyToStore {
            sharedDefaults.set(wm, forKey: "warMemorialOccupancy")
        }
        if let wmRem = warRemainingToStore {
            sharedDefaults.set(wmRem, forKey: "warMemorialRemaining")
        }
        
        // Bouldering Wall
        let boulderingWallOccupancyToStore = useCustomOccupancy ? customBoulderingWallOccupancy : boulderingWallData?.occupancy
        let boulderingWallRemainingToStore = boulderingWallData?.remaining
        if let bw = boulderingWallOccupancyToStore {
            sharedDefaults.set(bw, forKey: "boulderingWallOccupancy")
        }
        if let bwRem = boulderingWallRemainingToStore {
            sharedDefaults.set(bwRem, forKey: "boulderingWallRemaining")
        }
        
        // 3. Optionally store a timestamp
        sharedDefaults.set(Date(), forKey: "lastFetchDate")
        
        // 4. Tell WidgetKit to reload
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

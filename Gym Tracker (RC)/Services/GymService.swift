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
    @Published var isOnline: Bool = true
    
    // **Custom Occupancy Properties**
    @Published var useCustomOccupancy: Bool = false
    @Published var customMcComasOccupancy: Int? = 275
    @Published var customWarMemorialOccupancy: Int? = 1025
    
    private let occupancyURL = URL(string: "https://connect.recsports.vt.edu/facilityoccupancy")!
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
    
    func fetchAllGymOccupancy() async {
        do {
            let (data, response) = try await urlSession.data(from: occupancyURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw GymServiceError.invalidResponse
            }
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw GymServiceError.dataConversionError
            }
            
            // The request succeeded
            isOnline = true
            
            // Parse each gym from one single HTML response
            let warMemorialFacilityId = "55069633-b56e-43b7-a68a-64d79364988d"
            let mcComasFacilityId     = "da73849e-434d-415f-975a-4f9e799b9c39"
            
            let warMemorialData = parseHTMLForOccupancy(htmlString, facilityId: warMemorialFacilityId)
            let mcComasData     = parseHTMLForOccupancy(htmlString, facilityId: mcComasFacilityId)
            
            // Now unify & store
            storeAndNotify(mcComasData: mcComasData, warMemorialData: warMemorialData)
            
        } catch {
            print("Error fetching occupancy: \(error.localizedDescription)")
            isOnline = false
            
            // Potentially schedule a retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                Task {
                    await self?.fetchAllGymOccupancy()
                }
            }
        }
    }
    
    private func parseHTMLForOccupancy(_ html: String, facilityId: String) -> GymOccupancyData? {
        do {
            let document = try SwiftSoup.parse(html)
            
            guard let facilityContainer = try document
                .select("div[data-facilityid='\(facilityId)']")
                .first()
            else {
                throw GymServiceError.htmlParsingError
            }
            
            guard let canvasElement = try facilityContainer
                .select("canvas.occupancy-chart")
                .first()
            else {
                throw GymServiceError.htmlParsingError
            }
            
            let occupancyStr = try canvasElement.attr("data-occupancy")
            let remainingStr = try canvasElement.attr("data-remaining")
            
            guard let occupancy = Int(occupancyStr),
                  let remaining = Int(remainingStr)
            else {
                throw GymServiceError.dataConversionError
            }
            
            return GymOccupancyData(occupancy: occupancy, remaining: remaining)
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
    
    // MARK: - Store & Notify in one place
    
    private func storeAndNotify(mcComasData: GymOccupancyData?, warMemorialData: GymOccupancyData?) {
        
        // 1. Update your in-app Published vars (if needed)
        self.mcComasOccupancy = useCustomOccupancy ? customMcComasOccupancy : mcComasData?.occupancy
        self.warMemorialOccupancy = useCustomOccupancy ? customWarMemorialOccupancy : warMemorialData?.occupancy
        
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
        
        // 3. Optionally store a timestamp
        sharedDefaults.set(Date(), forKey: "lastFetchDate")
        
        // 4. Tell WidgetKit to reload
        WidgetCenter.shared.reloadAllTimelines()
        
        print("New data stored and WidgetKit notified.")
    }
    
    // MARK: - Custom Occupancy Methods
    
    func setCustomOccupancies(mcComas: Int?, warMemorial: Int?) {
        customMcComasOccupancy = mcComas
        customWarMemorialOccupancy = warMemorial
        useCustomOccupancy = true
    }
    
    func clearCustomOccupancies() {
        customMcComasOccupancy = nil
        customWarMemorialOccupancy = nil
        useCustomOccupancy = false
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        activeAppCancellable?.cancel()
    }
}

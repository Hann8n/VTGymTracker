//GymService.swift
//Shared File (Targets Gym Tracker RC and Gym Tracker Widget)

import Foundation
import Combine
import SwiftSoup
import WidgetKit

// Error types for GymService
enum GymServiceError: Error {
    case invalidURL
    case invalidResponse
    case htmlParsingError
    case dataConversionError
}

// Struct to hold gym occupancy data
struct GymOccupancyData {
    let occupancy: Int
    let remaining: Int
}

class GymService: ObservableObject {
    // MARK: - Singleton Instance
    static let shared = GymService()

    // MARK: - Published Properties
    @Published var mcComasOccupancy: Int? = nil
    @Published var warMemorialOccupancy: Int? = nil
    @Published var isOnline: Bool = true

    // MARK: - Private Properties
    private let occupancyURL = URL(string: "https://connect.recsports.vt.edu/facilityoccupancy")!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    private init() {}

    // MARK: - Public Methods

    /// Fetch gym occupancy data for a given facility ID
    func fetchGymOccupancy(for facilityId: String) async -> GymOccupancyData? {
        do {
            print("Fetching from URL: \(occupancyURL)")

            // Fetch the data from the URL
            let (data, response) = try await URLSession.shared.data(from: occupancyURL)

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Invalid HTTP response")
                isOnline = false
                throw GymServiceError.invalidResponse
            }

            // Decode HTML response into a String
            guard let html = String(data: data, encoding: .utf8) else {
                print("Failed to decode HTML")
                isOnline = false
                throw GymServiceError.dataConversionError
            }

            print("HTML Response: \(html.prefix(500))...") // For debugging

            // Parse the HTML to extract occupancy data
            isOnline = true
            return parseHTMLForOccupancy(html: html, facilityId: facilityId)

        } catch {
            // Log errors and update online status
            print("Error fetching occupancy data: \(error.localizedDescription)")
            isOnline = false
            return nil
        }
    }

    /// Store fetched occupancy data in the App Group's UserDefaults (for widget updates)
    func storeOccupancyDataInAppGroup(mcComas: GymOccupancyData, warMemorial: GymOccupancyData) {
        let sharedDefaults = UserDefaults(suiteName: "group.VTGymApp")

        // Store McComas data
        sharedDefaults?.set(mcComas.occupancy, forKey: "mcComasOccupancy")
        sharedDefaults?.set(mcComas.remaining, forKey: "mcComasRemaining")

        // Store War Memorial data
        sharedDefaults?.set(warMemorial.occupancy, forKey: "warMemorialOccupancy")
        sharedDefaults?.set(warMemorial.remaining, forKey: "warMemorialRemaining")

        // Synchronize UserDefaults
        sharedDefaults?.synchronize()

        // Notify the widget to reload its timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "GymTrackerWidget")
    }

    // MARK: - Private Methods

    /// Parse HTML to extract gym occupancy data
    private func parseHTMLForOccupancy(html: String, facilityId: String) -> GymOccupancyData? {
        do {
            let document = try SwiftSoup.parse(html)

            // Locate the canvas element by facility ID
            guard let canvasElement = try document.select("#occupancyChart-\(facilityId)").first() else {
                print("Canvas element not found for facilityId: \(facilityId)")
                throw GymServiceError.htmlParsingError
            }

            // Extract the occupancy and remaining data from the attributes
            let occupancyStr = try canvasElement.attr("data-occupancy")
            let remainingStr = try canvasElement.attr("data-remaining")

            // Convert extracted strings to integers
            guard let occupancy = Int(occupancyStr), let remaining = Int(remainingStr) else {
                print("Failed to parse occupancy or remaining data")
                throw GymServiceError.dataConversionError
            }

            return GymOccupancyData(occupancy: occupancy, remaining: remaining)

        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }

    // MARK: - Helper Methods

    /// Update occupancy and handle Combine bindings
    func updateOccupancy(mcComas: GymOccupancyData?, warMemorial: GymOccupancyData?) {
        DispatchQueue.main.async {
            self.mcComasOccupancy = mcComas?.occupancy
            self.warMemorialOccupancy = warMemorial?.occupancy
        }
    }

    /// Periodically fetch data and update occupancy
    func startFetchingData(interval: TimeInterval = 30) {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    guard let self = self else { return }
                    if self.isOnline {
                        async let mcComas = self.fetchGymOccupancy(for: "mcComasFacilityId")
                        async let warMemorial = self.fetchGymOccupancy(for: "warMemorialFacilityId")

                        let mcComasResult = await mcComas
                        let warMemorialResult = await warMemorial

                        self.updateOccupancy(mcComas: mcComasResult, warMemorial: warMemorialResult)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

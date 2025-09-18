// WarningManager.swift
// Shared File (Targets Gym Tracker RC and Gym Tracker Widget)

import Foundation
import Combine

class WarningManager: ObservableObject {
    @Published var showOccupancyWarning: Bool = false
    private var lastMcComasOccupancy: Int?
    private var lastWarMemorialOccupancy: Int?
    private var cancellables = Set<AnyCancellable>()
    
    private let checkInterval: TimeInterval = 900 // 15 minutes


    private func checkForWarnings(mcComas: Int?, warMemorial: Int?) {
        guard let mcComas = mcComas, let warMemorial = warMemorial else { return }

        // Trigger warning if occupancy hasn't changed
        if mcComas == lastMcComasOccupancy, warMemorial == lastWarMemorialOccupancy {
            showOccupancyWarning = true
        } else {
            showOccupancyWarning = false
        }

        // Update last known values
        lastMcComasOccupancy = mcComas
        lastWarMemorialOccupancy = warMemorial
    }
}

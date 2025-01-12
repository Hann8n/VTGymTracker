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

    init(gymService: GymService) {
        observeOccupancyChanges(from: gymService)
    }

    private func observeOccupancyChanges(from gymService: GymService) {
        // Observe changes to occupancy data
        gymService.$isOnline
            .combineLatest(
                gymService.$mcComasOccupancy,
                gymService.$warMemorialOccupancy
            )
            .debounce(for: .seconds(checkInterval), scheduler: RunLoop.main) // Trigger checks every 15 mins
            .sink { [weak self] isOnline, mcComas, warMemorial in
                guard let self = self, isOnline else { return }
                self.checkForWarnings(mcComas: mcComas, warMemorial: warMemorial)
            }
            .store(in: &cancellables)
    }

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

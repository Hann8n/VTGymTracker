//
//  EventsViewModel.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import Foundation
import Combine

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case noInternet
    case fetchFailed(description: String)
    case noData
    case parseFailed
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "Please check your internet connection"
        case .fetchFailed(_):
            return "Unable to load events right now"
        case .noData:
            return "No events available at the moment"
        case .parseFailed:
            return "Unable to load events right now"
        }
    }
}

// MARK: - EventsViewModel

class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor: NetworkMonitor
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        setupNetworkMonitor()
        
        // Load cache immediately to display events without network delay
        let cachedEvents = loadCache()
        if !cachedEvents.isEmpty {
            self.events = cachedEvents
        } else {
            // Nothing to show until the first fetch lands; start in the loading state so the
            // section renders the skeleton instead of flashing "Nothing scheduled".
            self.isLoading = true
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitor() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if !isConnected {
                    if self.events.isEmpty {
                        let cachedEvents = self.loadCache()
                        if cachedEvents.isEmpty {
                            self.errorMessage = NetworkError.noInternet.errorDescription
                        } else {
                            self.events = cachedEvents
                            self.errorMessage = nil
                        }
                    }
                } else {
                    // Refetch on reconnect to ensure data freshness after network outage
                    if self.errorMessage == NetworkError.noInternet.errorDescription {
                        self.errorMessage = nil
                        self.fetchEvents()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents() {
        guard networkMonitor.isConnected else {
            DispatchQueue.main.async {
                self.isLoading = false
                let cachedEvents = self.loadCache()
                if cachedEvents.isEmpty {
                    self.errorMessage = NetworkError.noInternet.errorDescription
                } else {
                    self.events = cachedEvents
                    self.errorMessage = nil
                }
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        Task {
            let snapshot = await EventsService().fetch()
            await MainActor.run {
                self.isLoading = false
                if snapshot.status != .unavailable {
                    self.events = snapshot.events
                    self.errorMessage = nil
                } else {
                    self.useCachedEventsOrShowError(.fetchFailed(description: snapshot.availabilityDetail ?? ""))
                }
            }
        }
    }

    // MARK: - Caching Methods

    private func loadCache() -> [Event] {
        EventsCacheStore.shared.loadForDisplay()
    }

    private func useCachedEventsOrShowError(_ error: NetworkError) {
        let cachedEvents = loadCache()
        if cachedEvents.isEmpty {
            errorMessage = error.errorDescription
        } else {
            events = cachedEvents
            errorMessage = nil
        }
    }
}

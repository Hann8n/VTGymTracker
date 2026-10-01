// WatchNetworkMonitor.swift
// Gym Tracker Watch App — independent watchOS network monitor (no iPhone dependency)

import Foundation
import Network
import Combine

final class WatchNetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "WatchNetworkMonitor")

    init() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor?.cancel()
    }
}

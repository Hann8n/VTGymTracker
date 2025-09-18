//NetworkMonitor.swift
//
import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

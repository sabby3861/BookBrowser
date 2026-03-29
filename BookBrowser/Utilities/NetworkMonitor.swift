//
//  NetworkMonitor.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation
import Network

/// Lightweight wrapper around `NWPathMonitor` that publishes
/// connectivity state as a simple boolean.`.
@MainActor
@Observable
final class NetworkMonitor {
    
    private(set) var isConnected = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bookbrowser.networkmonitor", qos: .utility)
    
    init() {
        startMonitoring()
    }
    
    /// `NWPathMonitor.cancel()` is documented as thread-safe,
    /// so calling it from deinit (which runs outside actor isolation) is safe.
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Private
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

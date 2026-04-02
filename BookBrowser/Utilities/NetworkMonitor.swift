//
//  NetworkMonitor.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation
import Network

/// Wraps `NWPathMonitor` to publish connectivity state as a simple boolean.
/// Runs on a dedicated serial queue, dispatches updates back to `@MainActor`.
@MainActor
@Observable
final class NetworkMonitor {
    
    private(set) var isConnected = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bookbrowser.networkmonitor", qos: .utility)
    
    init() {
        startMonitoring()
    }
    
    /// `NWPathMonitor.cancel()` is thread-safe, safe to call from deinit.
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

//
//  NetworkMonitor.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation
import Network
import SwiftUI

class NetworkMonitor: NSObject, ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var isSlowConnection = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    private override init() {
        super.init()
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isSlowConnection = path.status == .satisfied && (
                    path.availableInterfaces.allSatisfy { $0.type == .cellular } ||
                    path.availableInterfaces.isEmpty
                )
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }

    deinit {
        stop()
    }
}

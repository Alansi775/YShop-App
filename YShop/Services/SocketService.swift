//
//  SocketService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation
import SwiftUI

@MainActor
class SocketService: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var errorMessage: String?
@Published var heading: Double? = nil

    static let shared = SocketService()

    private var urlSession: URLSessionWebSocketTask?
    private var currentToken: String?
    private var orderObservers: [String: [UUID: () -> Void]] = [:]
    private var locationObservers: [String: [UUID: (String) -> Void]] = [:]
    private let baseURL: String = AppConstants.baseURL.replacingOccurrences(of: "http", with: "ws")

    override private init() {
        super.init()
    }

    // MARK: - Connection Management
    func connectIfNeeded(token: String) {
        guard !token.isEmpty else { return }

        if isConnected, currentToken == token {
            return
        }

        disconnect()
        connect(token: token)
    }

    func connect(token: String) {
        guard let url = URL(string: baseURL) else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let webSocket = URLSession.shared.webSocketTask(with: urlRequest)
        self.urlSession = webSocket
        self.currentToken = token
        webSocket.resume()

        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        urlSession?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        currentToken = nil
        errorMessage = nil
    }

    func observeOrder(orderId: String, onUpdate: @escaping () -> Void) -> UUID {
        let observerId = UUID()
        var observers = orderObservers[orderId] ?? [:]
        observers[observerId] = onUpdate
        orderObservers[orderId] = observers
        return observerId
    }

    func removeObserver(orderId: String, observerId: UUID) {
        guard var observers = orderObservers[orderId] else { return }
        observers.removeValue(forKey: observerId)
        if observers.isEmpty {
            orderObservers.removeValue(forKey: orderId)
        } else {
            orderObservers[orderId] = observers
        }
    }

    func observeLocation(orderId: String, onUpdate: @escaping (String) -> Void) -> UUID {
        let observerId = UUID()
        var observers = locationObservers[orderId] ?? [:]
        observers[observerId] = onUpdate
        locationObservers[orderId] = observers
        return observerId
    }

    func removeLocationObserver(orderId: String, observerId: UUID) {
        guard var observers = locationObservers[orderId] else { return }
        observers.removeValue(forKey: observerId)
        if observers.isEmpty {
            locationObservers.removeValue(forKey: orderId)
        } else {
            locationObservers[orderId] = observers
        }
    }

    // MARK: - Send Message
    func send(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        urlSession?.send(message) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Receive Message
    private func receiveMessage() {
        urlSession?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.handleMessage(text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.handleMessage(text)
                        }
                    }
                @unknown default:
                    break
                }
                DispatchQueue.main.async {
                    self?.receiveMessage()
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleMessage(_ message: String) {
        print("[WebSocket] Received: \(message)")

        guard let data = message.data(using: .utf8) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let envelope = try? decoder.decode(SocketMessageEnvelope.self, from: data) {
            if let type = envelope.type, type == "driver_location",
               let orderId = envelope.orderId ?? envelope.id ?? envelope.orderID,
               let driverLoc = envelope.driverLocation {
                notifyLocationObservers(for: orderId, location: driverLoc)
                return
            }

            if let order = envelope.order ?? envelope.data ?? envelope.payload {
                notifyOrderObservers(for: order.id)
                return
            }

            if let orderId = envelope.orderId ?? envelope.id ?? envelope.orderID {
                notifyOrderObservers(for: orderId)
                return
            }
        }

        if let order = try? decoder.decode(Order.self, from: data) {
            notifyOrderObservers(for: order.id)
        }
    }

    private func notifyOrderObservers(for orderId: String) {
        // Normalize incoming id and notify any observers whose normalized id matches.
        let incoming = normalizeOrderId(orderId)

        for (key, observers) in orderObservers {
            if normalizeOrderId(key) == incoming {
                for callback in observers.values {
                    callback()
                }
            }
        }
    }

    private func normalizeOrderId(_ id: String) -> String {
        // Keep only digits for loose equality (e.g. "ORDER-123" == "123")
        let digits = id.compactMap { $0.isNumber ? String($0) : nil }.joined()
        return digits.isEmpty ? id : digits
    }

    private func notifyLocationObservers(for orderId: String, location: String) {
        guard let observers = locationObservers[orderId], !observers.isEmpty else { return }

        for callback in observers.values {
            callback(location)
        }
    }

    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.urlSession?.cancel(with: .goingAway, reason: nil)
        }
    }
}

private struct SocketMessageEnvelope: Decodable {
    let id: String?
    let orderId: String?
    let orderID: String?
    let order: Order?
    let data: Order?
    let payload: Order?
    let type: String?
    let event: String?
    let action: String?
    let driverLocation: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId
        case orderID = "order_id"
        case order
        case data
        case payload
        case type
        case event
        case action
        case driverLocation = "driver_location"
    }
}

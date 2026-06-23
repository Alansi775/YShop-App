//
//  SocketService.swift
//  YShop
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
    private var reconnectTask: Task<Void, Never>?

    // Socket.IO WebSocket endpoint — Engine.IO v4 direct transport
    // Format: ws(s)://host/socket.io/?EIO=4&transport=websocket
    private var socketURL: String {
        AppConstants.mediaBaseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
            + "/socket.io/?EIO=4&transport=websocket"
    }

    override private init() { super.init() }

    // MARK: - Public connection API

    func connectIfNeeded(token: String) {
        guard !token.isEmpty else { return }
        if isConnected, currentToken == token { return }
        disconnect()
        connect(token: token)
    }

    func connect(token: String) {
        reconnectTask?.cancel()
        guard let url = URL(string: socketURL) else { return }

        var request = URLRequest(url: url)
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 10

        let ws = URLSession.shared.webSocketTask(with: request)
        urlSession = ws
        currentToken = token
        ws.resume()
        receiveLoop()
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        urlSession?.cancel(with: .goingAway, reason: nil)
        urlSession = nil
        isConnected = false
        currentToken = nil
        errorMessage = nil
    }

    // MARK: - Order / location observer registration

    func observeOrder(orderId: String, onUpdate: @escaping () -> Void) -> UUID {
        let id = UUID()
        orderObservers[orderId, default: [:]][id] = onUpdate
        return id
    }

    func removeObserver(orderId: String, observerId: UUID) {
        orderObservers[orderId]?.removeValue(forKey: observerId)
        if orderObservers[orderId]?.isEmpty == true { orderObservers.removeValue(forKey: orderId) }
    }

    func observeLocation(orderId: String, onUpdate: @escaping (String) -> Void) -> UUID {
        let id = UUID()
        locationObservers[orderId, default: [:]][id] = onUpdate
        return id
    }

    func removeLocationObserver(orderId: String, observerId: UUID) {
        locationObservers[orderId]?.removeValue(forKey: observerId)
        if locationObservers[orderId]?.isEmpty == true { locationObservers.removeValue(forKey: orderId) }
    }

    // MARK: - Receive loop

    private func receiveLoop() {
        urlSession?.receive { [weak self] result in
            switch result {
            case .success(let message):
                let text: String? = {
                    switch message {
                    case .string(let s): return s
                    case .data(let d):   return String(data: d, encoding: .utf8)
                    @unknown default:    return nil
                    }
                }()
                if let text {
                    DispatchQueue.main.async { self?.handleEngineIO(text) }
                }
                DispatchQueue.main.async { self?.receiveLoop() }

            case .failure(let err):
                print("[Socket] ❌ WebSocket error: \(err.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.scheduleReconnect()
                }
            }
        }
    }

    private func scheduleReconnect() {
        guard let token = currentToken else { return }
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { self.connect(token: token) }
        }
    }

    // MARK: - Engine.IO / Socket.IO protocol parser
    //
    // Socket.IO sits on top of Engine.IO.
    // Raw WebSocket frames look like: "<engine_type><socketio_type>[json_payload]"
    //
    // Engine.IO types:
    //   0 = open   (server sends handshake → we reply "40" to join default namespace)
    //   2 = ping   (server→client: we must reply "3" within pingTimeout)
    //   3 = pong
    //   4 = message (contains a Socket.IO packet)
    //
    // Socket.IO types (first char after the "4"):
    //   0 = namespace connect confirmation  → set isConnected = true
    //   2 = event  →  "42["eventName",{data}]"

    private func handleEngineIO(_ raw: String) {
        guard let first = raw.first else { return }
        switch first {
        case "0":
            // Engine.IO handshake — join Socket.IO default namespace
            sendFrame("40")
        case "2":
            // Engine.IO ping from server → respond with pong
            sendFrame("3")
        case "4":
            handleSocketIO(String(raw.dropFirst()))
        default:
            break
        }
    }

    private func handleSocketIO(_ payload: String) {
        guard let first = payload.first else { return }
        switch first {
        case "0":
            // Namespace connected: "0" or "0{...}"
            let wasConnected = isConnected
            isConnected = true
            print("[Socket] ✅ Connected to server\(wasConnected ? " (was already connected)" : " (reconnected)")")
            if !wasConnected {
                NotificationCenter.default.post(name: .yshopSocketReconnected, object: nil)
            }
        case "2":
            // Socket.IO event: "2["eventName", {...}]"
            decodeEvent(String(payload.dropFirst()))
        default:
            break
        }
    }

    private func decodeEvent(_ jsonStr: String) {
        guard let data = jsonStr.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 2,
              let payloadDict = array[1] as? [String: Any],
              let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict)
        else {
            print("[Socket] ⚠️ decodeEvent: failed to parse JSON array from: \(String(jsonStr.prefix(120)))")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(SocketMessageEnvelope.self, from: payloadData) else {
            print("[Socket] ⚠️ decodeEvent: SocketMessageEnvelope decode failed for payload: \(String(jsonStr.prefix(120)))")
            return
        }
        print("[Socket] ✅ Event received — type=\(envelope.type ?? "nil") orderId=\(envelope.orderId ?? envelope.id ?? "nil") storeId=\(envelope.storeId ?? "nil") status=\(envelope.status ?? "nil")")
        dispatch(envelope)
    }

    // MARK: - Event dispatch

    private func dispatch(_ e: SocketMessageEnvelope) {
        switch e.type {

        case "driver_location":
            if let oid = e.orderId ?? e.id ?? e.orderID, let loc = e.driverLocation {
                notifyLocationObservers(for: oid, location: loc)
            }

        case "order_updated", "order_created":
            let oid = e.orderId ?? e.id ?? e.orderID
            if let oid {
                AppCache.shared.invalidate(.userOrders)
                AppCache.shared.invalidate(.activeOrder(id: oid))
                notifyOrderObservers(for: oid)
                NotificationCenter.default.post(name: .yshopOrderUpdated, object: oid)
            }

        case "store_updated", "store_created", "store_deleted":
            if let t = e.storeType { AppCache.shared.invalidate(.stores(category: t)) }
            if let sid = e.storeId {
                AppCache.shared.invalidate(.storeDetail(id: sid))
                AppCache.shared.invalidate(.categories(storeId: sid))
            }
            NotificationCenter.default.post(
                name: .yshopStoreChanged,
                object: nil,
                userInfo: [
                    "action":    e.type    ?? "",
                    "storeId":   e.storeId ?? "",
                    "storeType": e.storeType ?? "",
                    "status":    e.status  ?? ""
                ]
            )

        case "product_updated", "product_created", "product_deleted":
            if let sid = e.storeId, let id = Int(sid) {
                AppCache.shared.invalidate(.products(storeId: id))
            }
            NotificationCenter.default.post(
                name: .yshopProductChanged,
                object: nil,
                userInfo: [
                    "action":    e.type      ?? "",
                    "productId": e.productId ?? "",
                    "storeId":   e.storeId   ?? "",
                    "status":    e.status    ?? ""
                ]
            )

        default:
            break
        }
    }

    // MARK: - Internal helpers

    private func sendFrame(_ text: String) {
        urlSession?.send(.string(text)) { _ in }
    }

    private func notifyOrderObservers(for orderId: String) {
        let incoming = normalized(orderId)
        orderObservers
            .filter { normalized($0.key) == incoming }
            .values
            .flatMap { $0.values }
            .forEach { $0() }
    }

    private func notifyLocationObservers(for orderId: String, location: String) {
        locationObservers[orderId]?.values.forEach { $0(location) }
    }

    private func normalized(_ id: String) -> String {
        let digits = id.filter { $0.isNumber }
        return digits.isEmpty ? id : digits
    }

    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.urlSession?.cancel(with: .goingAway, reason: nil)
        }
    }
}

// MARK: - Message envelope

// Lightweight envelope — never tries to decode a full Order object.
// The backend sends order.id as an integer in the nested "order" field,
// which would cause a type mismatch against Order.id: String and silently
// nil-out the entire decode. We only need the top-level string IDs.
private struct SocketMessageEnvelope: Decodable {
    let id: String?
    let orderId: String?
    let orderID: String?
    let type: String?
    let driverLocation: String?
    let storeType: String?
    let storeId: String?
    let productId: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId
        case orderID        = "order_id"
        case type
        case driverLocation = "driver_location"
        case storeType      = "store_type"
        case storeId        = "store_id"
        case productId      = "product_id"
        case status
    }

    // Custom init so that `id` is parsed tolerantly (String or Int).
    // All fields use try? so a single bad value never kills the whole decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id may arrive as "123" or 123
        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let n = try? c.decode(Int.self, forKey: .id) {
            id = String(n)
        } else {
            id = nil
        }

        orderId        = try? c.decode(String.self, forKey: .orderId)
        orderID        = try? c.decode(String.self, forKey: .orderID)
        type           = try? c.decode(String.self, forKey: .type)
        driverLocation = try? c.decode(String.self, forKey: .driverLocation)
        storeType      = try? c.decode(String.self, forKey: .storeType)
        storeId        = try? c.decode(String.self, forKey: .storeId)
        productId      = try? c.decode(String.self, forKey: .productId)
        status         = try? c.decode(String.self, forKey: .status)
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let yshopOrderUpdated    = Notification.Name("yshop.orderUpdated")
    static let yshopStoreChanged    = Notification.Name("yshop.storeChanged")
    static let yshopProductChanged  = Notification.Name("yshop.productChanged")
    static let yshopSocketReconnected = Notification.Name("yshop.socketReconnected")
}

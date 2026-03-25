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

    static let shared = SocketService()

    private var urlSession: URLSessionWebSocketTask?
    private let baseURL: String = AppConstants.baseURL.replacingOccurrences(of: "http", with: "ws")

    override private init() {
        super.init()
    }

    // MARK: - Connection Management
    func connect(token: String) {
        guard let url = URL(string: baseURL) else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let webSocket = URLSession.shared.webSocketTask(with: urlRequest)
        self.urlSession = webSocket
        webSocket.resume()

        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        urlSession?.cancel(with: .goingAway, reason: nil)
        isConnected = false
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
        // Handle incoming WebSocket messages
        print("[WebSocket] Received: \(message)")
    }

    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.urlSession?.cancel(with: .goingAway, reason: nil)
        }
    }
}

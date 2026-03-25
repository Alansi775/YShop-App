//
//  AIService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Chat
    static func sendMessage(sessionId: String, message: String) async throws -> AIMessage {
        struct ChatRequest: Encodable {
            let sessionId: String
            let message: String

            enum CodingKeys: String, CodingKey {
                case message
                case sessionId = "session_id"
            }
        }

        let request = ChatRequest(sessionId: sessionId, message: message)
        return try await APIClient.shared.request(.sendAIMessage, body: request)
    }

    // MARK: - Get Chat History
    static func getChatHistory(sessionId: String) async throws -> [AIMessage] {
        try await APIClient.shared.request(.getAIChatHistory)
    }

    // MARK: - Clear Chat History
    static func clearChatHistory(sessionId: String) async throws -> EmptyResponse {
        try await APIClient.shared.request(.clearAIChat)
    }

    // MARK: - Get AI Status
    static func getAIStatus() async throws -> AIStatus {
        try await APIClient.shared.request(.getAIStatus)
    }
}

struct AIStatus: Codable {
    let status: String
    let responseTime: Double
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case status
        case responseTime = "response_time"
        case lastUpdated = "last_updated"
    }
}

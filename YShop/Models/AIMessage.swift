import Foundation

enum AIMessageRole: String, Codable {
    case user, assistant, system
}

struct AIMessage: Codable, Identifiable {
    let id: String
    let conversationId: String?
    let text: String
    let role: AIMessageRole
    let category: String?
    let productRecommendations: [Product]?
    let storeRecommendations: [Store]?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case text, role, category
        case productRecommendations = "product_recommendations"
        case storeRecommendations = "store_recommendations"
        case createdAt = "created_at"
    }
    
    static let mock = AIMessage(
        id: "1",
        conversationId: "conv1",
        text: "Hello! Looking for groceries?",
        role: .assistant,
        category: nil,
        productRecommendations: [.mock],
        storeRecommendations: [.mock],
        createdAt: nil
    )
}

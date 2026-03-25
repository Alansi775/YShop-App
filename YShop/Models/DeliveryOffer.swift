import Foundation

enum DeliveryOfferStatus: String, Codable {
    case pending, accepted, rejected, expired
}

struct DeliveryOffer: Codable, Identifiable {
    let id: String
    let orderId: String
    let driverId: String?
    let order: Order?
    let estimatedTime: Int?
    let bidPrice: Double
    let status: DeliveryOfferStatus
    let expiresAt: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case driverId = "driver_id"
        case order
        case estimatedTime = "estimated_time"
        case bidPrice = "bid_price"
        case status
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let mock = DeliveryOffer(
        id: "1",
        orderId: "order1",
        driverId: nil,
        order: .mock,
        estimatedTime: 30,
        bidPrice: 3.50,
        status: .pending,
        expiresAt: nil,
        createdAt: nil,
        updatedAt: nil
    )
}

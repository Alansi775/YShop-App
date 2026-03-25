import Foundation

enum OrderStatus: String, Codable {
    case pending, confirmed, processing, outForDelivery = "out_for_delivery", delivered, cancelled, failed
}

struct Order: Codable, Identifiable {
    let id: String
    let userId: String
    let storeId: String
    let items: [CartItem]
    let totalPrice: Double
    let status: OrderStatus
    let deliveryAddress: String?
    let phone: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storeId = "store_id"
        case items, status, notes
        case totalPrice = "total_price"
        case deliveryAddress = "delivery_address"
        case phone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let mock = Order(
        id: "1",
        userId: "user1",
        storeId: "store1",
        items: [.mock],
        totalPrice: 11.98,
        status: .pending,
        deliveryAddress: "123 Main St",
        phone: nil,
        notes: nil,
        createdAt: nil,
        updatedAt: nil
    )
}

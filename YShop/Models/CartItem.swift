import Foundation

struct CartItem: Codable, Identifiable {
    let id: String
    let userId: String
    let productId: String
    let storeId: String
    let quantity: Int
    let price: Double
    let product: Product?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case productId = "product_id"
        case storeId = "store_id"
        case quantity, price, product
    }
    
    static let mock = CartItem(
        id: "1",
        userId: "user1",
        productId: "prod1",
        storeId: "store1",
        quantity: 2,
        price: 5.99,
        product: .mock
    )
}

import Foundation

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let price: Double
    let image: String?
    let categoryId: String
    let storeId: String
    let rating: Double
    let reviewCount: Int
    let availability: Int
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, image
        case categoryId = "category_id"
        case storeId = "store_id"
        case rating, reviewCount = "review_count"
        case availability
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let mock = Product(
        id: "1",
        name: "Fresh Apples",
        description: "Organic Fuji apples",
        price: 5.99,
        image: nil,
        categoryId: "1",
        storeId: "1",
        rating: 4.5,
        reviewCount: 128,
        availability: 50,
        createdAt: nil,
        updatedAt: nil
    )
}

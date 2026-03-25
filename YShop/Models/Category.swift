import Foundation

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let icon: String?
    
    static let mock = Category(id: "1", name: "Groceries", description: "Fresh groceries", icon: nil)
}

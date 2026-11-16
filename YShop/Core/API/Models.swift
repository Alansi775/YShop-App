import Foundation

// Mirrors of the v2 API responses. Field names match the server JSON exactly.

extension API {
    struct User: Codable, Identifiable, Hashable {
        enum Role: String, Codable { case CUSTOMER, STORE_OWNER, DRIVER, ADMIN, SUPERADMIN }

        let id: String
        let email: String
        let emailVerified: Bool
        let firstName: String?
        let lastName: String?
        let phone: String?
        let avatarUrl: URL?
        let roles: [Role]
        let hasPassword: Bool
        let createdAt: Date

        var displayName: String {
            let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
            return name.isEmpty ? email : name
        }

        var initials: String {
            let letters = [firstName, lastName].compactMap { $0?.first }.map(String.init).joined()
            return letters.isEmpty ? String(email.prefix(1)).uppercased() : letters.uppercased()
        }

        var isDriver: Bool { roles.contains(.DRIVER) }
    }

    struct AuthResponse: Codable {
        let accessToken: String
        let refreshToken: String
        let user: User
    }

    struct StoreType: Codable, Hashable, Identifiable {
        let type: String
        let storeCount: Int
        var id: String { type }
    }

    struct Store: Codable, Identifiable, Hashable {
        let id: Int
        let name: String
        let description: String?
        let type: String
        let iconUrl: URL?
        let coverUrl: URL?
        let address: String
        let latitude: Double?
        let longitude: Double?
        let productCount: Int
    }

    struct StoreDetail: Codable, Identifiable, Hashable {
        struct Category: Codable, Identifiable, Hashable {
            let id: Int
            let name: String
            let icon: String?
            let productIds: [Int]
        }

        let id: Int
        let name: String
        let description: String?
        let type: String
        let phone: String?
        let address: String
        let latitude: Double?
        let longitude: Double?
        let iconUrl: URL?
        let coverUrl: URL?
        let categories: [Category]
        let products: [Product]

        func products(in category: Category) -> [Product] {
            let ids = Set(category.productIds)
            return products.filter { ids.contains($0.id) }
        }
    }

    struct Product: Codable, Identifiable, Hashable {
        struct StoreSummary: Codable, Hashable {
            let id: Int
            let name: String
            let type: String
            let iconUrl: URL?
        }

        let id: Int
        let name: String
        let description: String?
        let price: Decimal
        let currency: String
        let inStock: Bool
        let stock: Int
        let imageUrl: URL?
        let thumbUrl: URL?
        let images: [URL?]
        let storeId: Int
        let categoryId: Int?
        let createdAt: Date
        /// Only on `GET /products/:id`.
        let store: StoreSummary?

        var formattedPrice: String {
            price.formatted(.currency(code: currency).precision(.fractionLength(price.isWhole ? 0 : 2)))
        }
    }

    struct Page<Item: Codable & Hashable>: Codable, Hashable {
        let items: [Item]
        let nextCursor: Int?
    }
}

private extension Decimal {
    var isWhole: Bool { self == (self as NSDecimalNumber).rounding(accordingToBehavior: nil) as Decimal }
}

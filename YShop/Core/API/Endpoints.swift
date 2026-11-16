import Foundation

// Typed calls — screens never build paths or query strings themselves.

extension API {
    enum Auth {
        struct Credentials: Encodable { let email: String; let password: String }
        struct Registration: Encodable { let email, password, firstName, lastName: String; let phone: String? }
        struct Apple: Encodable { let identityToken: String; let firstName: String?; let lastName: String? }
        struct Google: Encodable { let idToken: String }

        static func login(email: String, password: String) async throws -> AuthResponse {
            try await client.post("/auth/login", Credentials(email: email, password: password))
        }
        static func register(_ r: Registration) async throws -> AuthResponse {
            try await client.post("/auth/register", r)
        }
        static func apple(identityToken: String, firstName: String?, lastName: String?) async throws -> AuthResponse {
            try await client.post("/auth/apple", Apple(identityToken: identityToken, firstName: firstName, lastName: lastName))
        }
        static func google(idToken: String) async throws -> AuthResponse {
            try await client.post("/auth/google", Google(idToken: idToken))
        }
        static func me() async throws -> User {
            try await client.get("/auth/me")
        }
        static func logout(refreshToken: String) async throws {
            try await client.post("/auth/logout", ["refreshToken": refreshToken])
        }
    }

    enum Catalog {
        static func storeTypes() async throws -> [StoreType] {
            try await client.get("/store-types")
        }
        static func stores(type: String? = nil, search: String? = nil) async throws -> [Store] {
            try await client.get("/stores", query: ["type": type, "search": search])
        }
        static func store(_ id: Int) async throws -> StoreDetail {
            try await client.get("/stores/\(id)")
        }
        static func products(storeId: Int? = nil, categoryId: Int? = nil, search: String? = nil,
                             cursor: Int? = nil, limit: Int = 40) async throws -> Page<Product> {
            try await client.get("/products", query: [
                "storeId": storeId.map(String.init), "categoryId": categoryId.map(String.init),
                "search": search, "cursor": cursor.map(String.init), "limit": String(limit),
            ])
        }
        static func product(_ id: Int) async throws -> Product {
            try await client.get("/products/\(id)")
        }
    }
}

//
//  User.swift
//  YShop
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let avatar: String?
    let role: String
    let isActive: Bool
    let isVerified: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, avatar, role
        case isActive = "is_active"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static let mock = User(
        id: "1", name: "John Doe", email: "john@example.com",
        phone: "1234567890", avatar: nil, role: "customer",
        isActive: true, isVerified: true, createdAt: Date(), updatedAt: Date()
    )
}

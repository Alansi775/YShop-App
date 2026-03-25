//
//  CartService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

class CartService {
    static let shared = CartService()
    private init() {}

    // MARK: - Get Cart
    static func getCart() async throws -> [CartItem] {
        try await APIClient.shared.request(.cart)
    }

    // MARK: - Add to Cart
    static func addToCart(productId: String, storeId: String, quantity: Int) async throws -> CartItem {
        struct AddRequest: Encodable {
            let productId: String
            let storeId: String?
            let quantity: Int

            enum CodingKeys: String, CodingKey {
                case quantity
                case productId = "product_id"
                case storeId = "store_id"
            }
        }

        let request = AddRequest(productId: productId, storeId: storeId, quantity: quantity)
        return try await APIClient.shared.request(.addToCart, body: request)
    }

    // MARK: - Update Cart Item
    static func updateCartItem(itemId: String, quantity: Int) async throws -> CartItem {
        struct UpdateRequest: Encodable {
            let quantity: Int
        }

        let request = UpdateRequest(quantity: quantity)
        return try await APIClient.shared.request(.updateCartItem(itemId), body: request)
    }

    // MARK: - Remove Cart Item
    static func removeCartItem(itemId: String) async throws -> EmptyResponse {
        try await APIClient.shared.request(.removeCartItem(itemId))
    }

    // MARK: - Clear Cart
    static func clearCart() async throws -> EmptyResponse {
        try await APIClient.shared.request(.clearCart)
    }

    // MARK: - Checkout
    static func checkout(
        deliveryAddress: String,
        latitude: Double,
        longitude: Double,
        notes: String?
    ) async throws -> Order {
        struct CheckoutRequest: Encodable {
            let deliveryAddress: String
            let latitude: Double
            let longitude: Double
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case notes
                case deliveryAddress = "delivery_address"
                case latitude
                case longitude
            }
        }

        let request = CheckoutRequest(
            deliveryAddress: deliveryAddress,
            latitude: latitude,
            longitude: longitude,
            notes: notes
        )
        return try await APIClient.shared.request(.checkout, body: request)
    }
}

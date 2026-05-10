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
        do {
            let response: APIResponse<[CartItem]> = try await APIClient.shared.request(.cart)
            return response.data
        } catch {
            return try await APIClient.shared.request(.cart)
        }
    }

    // MARK: - Add to Cart
    static func addToCart(productId: String, quantity: Int) async throws -> CartItem {
        struct AddRequest: Encodable {
            let productId: String
            let quantity: Int

            enum CodingKeys: String, CodingKey {
                case productId
                case quantity
            }
        }

        let request = AddRequest(productId: productId, quantity: quantity)
        let _: EmptyResponse = try await APIClient.shared.request(.addToCart, body: request)

        let cartItems = try await getCart()
        if let matchedItem = cartItems.first(where: { $0.productId == productId }) {
            return matchedItem
        }

        throw APIError.unknown("Item added but could not be found in cart")
    }

    // MARK: - Update Cart Item
    static func updateCartItem(itemId: String, quantity: Int) async throws -> CartItem {
        struct UpdateRequest: Encodable {
            let quantity: Int
        }

        let request = UpdateRequest(quantity: quantity)
        let _: EmptyResponse = try await APIClient.shared.request(.updateCartItem(itemId), body: request)

        let cartItems = try await getCart()
        if let matchedItem = cartItems.first(where: { $0.id == itemId }) {
            return matchedItem
        }

        throw APIError.unknown("Item updated but could not be found in cart")
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

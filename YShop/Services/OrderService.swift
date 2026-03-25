//
//  OrderService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

class OrderService {
    static let shared = OrderService()
    private init() {}

    // MARK: - Create Order
    static func createOrder(
        items: [CartItem],
        deliveryAddress: String,
        latitude: Double,
        longitude: Double,
        notes: String?
    ) async throws -> Order {
        struct CreateRequest: Encodable {
            let items: [String] // itemIds
            let deliveryAddress: String
            let latitude: Double
            let longitude: Double
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case items, notes, latitude, longitude
                case deliveryAddress = "delivery_address"
            }
        }

        let itemIds = items.map { $0.id }
        let request = CreateRequest(
            items: itemIds,
            deliveryAddress: deliveryAddress,
            latitude: latitude,
            longitude: longitude,
            notes: notes
        )
        return try await APIClient.shared.request(.createOrder, body: request)
    }

    // MARK: - Get User Orders
    static func getUserOrders(page: Int = 1) async throws -> [Order] {
        try await APIClient.shared.request(.getUserOrders)
    }

    // MARK: - Get Order Detail
    static func getOrderDetail(id: String) async throws -> Order {
        try await APIClient.shared.request(.getOrderDetail(id))
    }

    // MARK: - Update Order Status
    static func updateOrderStatus(id: String, status: OrderStatus) async throws -> Order {
        struct UpdateRequest: Encodable {
            let status: String
        }

        let request = UpdateRequest(status: status.rawValue)
        return try await APIClient.shared.request(.updateOrderStatus(id), body: request)
    }

    // MARK: - Cancel Order
    static func cancelOrder(id: String) async throws -> EmptyResponse {
        try await APIClient.shared.request(.cancelOrder(id))
    }
}

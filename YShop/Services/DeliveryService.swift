//
//  DeliveryService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation
import CoreLocation

class DeliveryService {
    static let shared = DeliveryService()
    private init() {}

    // MARK: - Get Driver Profile
    static func getDriverProfile() async throws -> DeliveryDriver {
        try await APIClient.shared.request(.getDriverProfile)
    }

    // MARK: - Update Driver Location
    static func updateDriverLocation(latitude: Double, longitude: Double) async throws -> EmptyResponse {
        struct LocationRequest: Encodable {
            let latitude: Double
            let longitude: Double
        }

        let request = LocationRequest(latitude: latitude, longitude: longitude)
        return try await APIClient.shared.request(.updateDriverLocation, body: request)
    }

    // MARK: - Toggle Working Status
    static func toggleWorking(isWorking: Bool) async throws -> EmptyResponse {
        struct WorkingRequest: Encodable {
            let isWorking: Bool

            enum CodingKeys: String, CodingKey {
                case isWorking = "is_working"
            }
        }

        let request = WorkingRequest(isWorking: isWorking)
        return try await APIClient.shared.request(.toggleWorking, body: request)
    }

    // MARK: - Get Delivery Offer
    static func getDeliveryOffer() async throws -> DeliveryOffer {
        try await APIClient.shared.request(.getDeliveryOffer)
    }

    // MARK: - Accept Offer
    static func acceptDeliveryOffer(offerId: String) async throws -> EmptyResponse {
        struct AcceptRequest: Encodable {
            let offerId: String

            enum CodingKeys: String, CodingKey {
                case offerId = "offer_id"
            }
        }

        let request = AcceptRequest(offerId: offerId)
        return try await APIClient.shared.request(.acceptOffer(offerId), body: request)
    }

    // MARK: - Skip Offer
    static func skipDeliveryOffer(offerId: String) async throws -> EmptyResponse {
        struct SkipRequest: Encodable {
            let offerId: String

            enum CodingKeys: String, CodingKey {
                case offerId = "offer_id"
            }
        }

        let request = SkipRequest(offerId: offerId)
        return try await APIClient.shared.request(.skipOffer(offerId), body: request)
    }

    // MARK: - Get Skipped Orders
    static func getSkippedOrders() async throws -> [Order] {
        try await APIClient.shared.request(.getSkippedOrders)
    }

    // MARK: - Reclaim Order
    static func reclaimOrder(orderId: String) async throws -> EmptyResponse {
        struct ReclaimRequest: Encodable {
            let orderId: String

            enum CodingKeys: String, CodingKey {
                case orderId = "order_id"
            }
        }

        let request = ReclaimRequest(orderId: orderId)
        return try await APIClient.shared.request(.reclaimOrder(orderId), body: request)
    }

    // MARK: - Get Active Order
    static func getActiveOrder() async throws -> Order {
        try await APIClient.shared.request(.getActiveOrder)
    }

    // MARK: - Pickup Order
    static func pickupOrder(orderId: String) async throws -> EmptyResponse {
        try await APIClient.shared.request(.pickupOrder(orderId))
    }

    // MARK: - Update Delivery Location
    static func updateDeliveryLocation(orderId: String, latitude: Double, longitude: Double) async throws -> EmptyResponse {
        struct LocationRequest: Encodable {
            let latitude: Double
            let longitude: Double
        }

        let request = LocationRequest(latitude: latitude, longitude: longitude)
        return try await APIClient.shared.request(.updateDeliveryLocation, body: request)
    }

    // MARK: - Deliver Order
    static func deliverOrder(orderId: String) async throws -> EmptyResponse {
        try await APIClient.shared.request(.deliverOrder(orderId))
    }

    // MARK: - Get Delivery History
    static func getDeliveryHistory(page: Int = 1) async throws -> [Order] {
        try await APIClient.shared.request(.getDeliveryHistory)
    }

    // MARK: - Get Driver Stats
    static func getDriverStats() async throws -> DriverStats {
        try await APIClient.shared.request(.getDriverStats)
    }
}

struct DriverStats: Codable {
    let totalDeliveries: Int
    let completedToday: Int
    let totalEarningsToday: Double
    let averageRating: Double
    let completionRate: Double

    enum CodingKeys: String, CodingKey {
        case totalDeliveries = "total_deliveries"
        case completedToday = "completed_today"
        case totalEarningsToday = "total_earnings_today"
        case averageRating = "average_rating"
        case completionRate = "completion_rate"
    }
}

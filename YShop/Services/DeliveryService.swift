//
//  DeliveryService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation
import CoreLocation
import SwiftUI

class DeliveryService {
    static let shared = DeliveryService()
    private init() {}

    // MARK: - Get Driver Profile
    static func getDriverProfile() async throws -> DeliveryProfile {
        let response: APIResponse<DeliveryProfile> = try await APIClient.shared.request(.getDriverProfile)
        return response.data
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
    static func toggleWorking(uid: String, isWorking: Bool) async throws -> EmptyResponse {
        struct WorkingRequest: Encodable {
            let uid: String
            let isWorking: Bool

            enum CodingKeys: String, CodingKey {
                case uid
                case isWorking
            }
        }

        let request = WorkingRequest(uid: uid, isWorking: isWorking)
        return try await APIClient.shared.request(.toggleWorking, body: request)
    }

    // MARK: - Get Delivery Offer
    static func getDeliveryOffer(latitude: Double, longitude: Double) async throws -> DeliveryOffer {
        try await APIClient.shared.request(.getDeliveryOffer(latitude: latitude, longitude: longitude))
    }

    // MARK: - Accept Offer
    static func acceptDeliveryOffer(orderId: String) async throws -> EmptyResponse {
        struct AcceptRequest: Encodable {
            let orderId: String

            enum CodingKeys: String, CodingKey {
                case orderId
            }
        }

        let request = AcceptRequest(orderId: orderId)
        return try await APIClient.shared.request(.acceptOffer(orderId), body: request)
    }

    // MARK: - Skip Offer
    static func skipDeliveryOffer(orderId: String) async throws -> EmptyResponse {
        struct SkipRequest: Encodable {
            let orderId: String

            enum CodingKeys: String, CodingKey {
                case orderId
            }
        }

        let request = SkipRequest(orderId: orderId)
        return try await APIClient.shared.request(.skipOffer(orderId), body: request)
    }

    // MARK: - Get Skipped Orders
    static func getSkippedOrders(latitude: Double, longitude: Double) async throws -> [Order] {
        try await APIClient.shared.request(.getSkippedOrders(latitude: latitude, longitude: longitude))
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
        return try await APIClient.shared.request(.updateDeliveryLocation(orderId), body: request)
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

struct DeliveryProfile: Codable, Identifiable {
    let id: String
    let uid: String
    let email: String
    let name: String
    let phone: String?
    let nationalId: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let isWorking: Bool
    let status: String
    let emailVerified: Bool
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, uid, email, name, phone, address, latitude, longitude, status
        case nationalId = "national_id"
        case isWorking = "is_working"
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = (try? container.decode(String.self, forKey: .id)) ?? ""
        }

        uid = (try? container.decode(String.self, forKey: .uid)) ?? ""
        email = (try? container.decode(String.self, forKey: .email)) ?? ""
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        phone = try? container.decodeIfPresent(String.self, forKey: .phone)
        nationalId = try? container.decodeIfPresent(String.self, forKey: .nationalId)
        address = try? container.decodeIfPresent(String.self, forKey: .address)

        if let latDouble = try? container.decodeIfPresent(Double.self, forKey: .latitude) {
            latitude = latDouble
        } else if let latString = try? container.decodeIfPresent(String.self, forKey: .latitude) {
            latitude = Double(latString)
        } else {
            latitude = nil
        }

        if let lonDouble = try? container.decodeIfPresent(Double.self, forKey: .longitude) {
            longitude = lonDouble
        } else if let lonString = try? container.decodeIfPresent(String.self, forKey: .longitude) {
            longitude = Double(lonString)
        } else {
            longitude = nil
        }

        isWorking = Self.decodeFlexibleBool(container, forKey: .isWorking)
        status = Self.normalizeStatus((try? container.decode(String.self, forKey: .status)) ?? "Pending")
        emailVerified = Self.decodeFlexibleBool(container, forKey: .emailVerified)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    private static func normalizeStatus(_ rawValue: String) -> String {
        rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private static func decodeFlexibleBool(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Bool {
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return boolValue ?? false
        }

        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return (intValue ?? 0) == 1
        }

        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return ["1", "true", "yes"].contains(stringValue.lowercased())
        }

        return false
    }

    var isApproved: Bool { status.lowercased() == "approved" }
    var isVerified: Bool { emailVerified }

    var accountStateTitle: String {
        isApproved ? "Approved" : "Pending"
    }

    var accountStateSubtitle: String {
        isApproved ? "Ready to receive delivery requests" : "Waiting for admin approval"
    }

    var accountStateColor: Color {
        isApproved ? .green : .orange
    }

    var canReceiveOrders: Bool {
        isApproved
    }
}

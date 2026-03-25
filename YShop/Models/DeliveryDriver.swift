//
//  DeliveryDriver.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

struct DeliveryDriver: Codable, Identifiable {
    let id: String
    let userId: String
    let vehicleType: String
    let vehiclePlate: String?
    let licenseNumber: String?
    let isWorking: Bool
    let availableOrders: Int
    let completedDeliveries: Int
    let totalEarnings: Double
    let rating: Double?
    let status: DriverStatus
    let currentLatitude: Double?
    let currentLongitude: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, rating, status
        case userId = "user_id"
        case vehicleType = "vehicle_type"
        case vehiclePlate = "vehicle_plate"
        case licenseNumber = "license_number"
        case isWorking = "is_working"
        case availableOrders = "available_orders"
        case completedDeliveries = "completed_deliveries"
        case totalEarnings = "total_earnings"
        case currentLatitude = "current_latitude"
        case currentLongitude = "current_longitude"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum DriverStatus: String, Codable {
    case active, inactive, suspended, onBreak
}

extension DeliveryDriver {
    static let mock = DeliveryDriver(
        id: "1",
        userId: "user1",
        vehicleType: "motorcycle",
        vehiclePlate: "ABC-1234",
        licenseNumber: "DL123456",
        isWorking: true,
        availableOrders: 3,
        completedDeliveries: 150,
        totalEarnings: 2500.00,
        rating: 4.7,
        status: .active,
        currentLatitude: 40.7128,
        currentLongitude: -74.0060,
        createdAt: Date(),
        updatedAt: Date()
    )
}

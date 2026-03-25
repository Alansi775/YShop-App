//
//  ReturnRequest.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

struct ReturnRequest: Codable, Identifiable {
    let id: String
    let orderId: String
    let customerId: String
    let reason: String
    let description: String?
    let images: [String]?
    let status: ReturnStatus
    let refundAmount: Double?
    let refundStatus: RefundStatus?
    let approvedAt: Date?
    let refundedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, reason, description, images, status
        case orderId = "order_id"
        case customerId = "customer_id"
        case refundAmount = "refund_amount"
        case refundStatus = "refund_status"
        case approvedAt = "approved_at"
        case refundedAt = "refunded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ReturnStatus: String, Codable {
    case pending, approved, rejected, completed, cancelled
}

enum RefundStatus: String, Codable {
    case pending, processing, completed, failed
}

extension ReturnRequest {
    static let mock = ReturnRequest(
        id: "1",
        orderId: "order1",
        customerId: "user1",
        reason: "Damaged product",
        description: "Item arrived damaged",
        images: [],
        status: .pending,
        refundAmount: nil,
        refundStatus: nil,
        approvedAt: nil,
        refundedAt: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

//
//  ReturnService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

class ReturnService {
    static let shared = ReturnService()
    private init() {}

    // MARK: - Create Return Request
    static func createReturnRequest(
        orderId: String,
        reason: String,
        description: String?,
        images: [Data]?
    ) async throws -> ReturnRequest {
        struct CreateRequest: Encodable {
            let orderId: String
            let reason: String
            let description: String?

            enum CodingKeys: String, CodingKey {
                case reason, description
                case orderId = "order_id"
            }
        }

        let request = CreateRequest(orderId: orderId, reason: reason, description: description)
        return try await APIClient.shared.request(.createReturnRequest, body: request)
    }

    // MARK: - Get User Returns
    static func getUserReturns(page: Int = 1) async throws -> [ReturnRequest] {
        try await APIClient.shared.request(.getUserReturns)
    }

    // MARK: - Get Return Detail
    static func getReturnDetail(id: String) async throws -> ReturnRequest {
        try await APIClient.shared.request(.getReturnDetail(id))
    }

    // MARK: - Upload Evidence
    static func uploadEvidence(returnId: String, images: [Data]) async throws -> ReturnRequest {
        var uploadRequest = ReturnRequest.mock
        uploadRequest = ReturnRequest(
            id: returnId,
            orderId: uploadRequest.orderId,
            customerId: uploadRequest.customerId,
            reason: uploadRequest.reason,
            description: uploadRequest.description,
            images: [],
            status: uploadRequest.status,
            refundAmount: uploadRequest.refundAmount,
            refundStatus: uploadRequest.refundStatus,
            approvedAt: uploadRequest.approvedAt,
            refundedAt: uploadRequest.refundedAt,
            createdAt: uploadRequest.createdAt,
            updatedAt: uploadRequest.updatedAt
        )
        return uploadRequest
    }
}

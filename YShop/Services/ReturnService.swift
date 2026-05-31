import Foundation
import UIKit

struct ReturnSubmitResponse: Decodable {
    let success: Bool
    let message: String?
    let data: ReturnSubmitData?

    struct ReturnSubmitData: Decodable {
        let id: Int?
        let returnId: Int?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case id
            case returnId = "return_id"
            case status
        }
    }
}

struct ReturnOrderItem: Identifiable, Decodable {
    let id: Int
    let orderId: Int
    let driverId: String?
    let productName: String?
    let productDescription: String?
    let productPrice: Double?
    let productCurrency: String?
    let productImageUrl: String?
    let quantity: Int?
    let reason: String
    let status: String
    let adminAccepted: Int?
    let storeReceived: Int?
    let driverPickedUp: Int?
    let deliveredAt: String?
    let returnRequestedAt: String?
    let customerName: String?
    let customerAddress: String?
    let customerLatitude: Double?
    let customerLongitude: Double?
    let storeId: Int?
    let storeName: String?
    let storeLatitude: Double?
    let storeLongitude: Double?
    let createdAt: String?
    let photos: [String]?

    var fullProductImageUrl: String? {
        guard let productImageUrl = productImageUrl, !productImageUrl.isEmpty else { return nil }

        if productImageUrl.starts(with: "http") {
            return productImageUrl
        }

        let baseURL = AppConstants.mediaBaseURL
        return productImageUrl.starts(with: "/") ? baseURL + productImageUrl : baseURL + "/" + productImageUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, reason, status, photos
        case orderId = "order_id"
        case driverId = "driver_id"
        case productName = "product_name"
        case productDescription = "product_description"
        case productPrice = "product_price"
        case productCurrency = "product_currency"
        case productImageUrl = "product_image_url"
        case quantity
        case adminAccepted = "admin_accepted"
        case storeReceived = "store_received"
        case driverPickedUp = "driver_picked_up"
        case deliveredAt = "delivered_at"
        case returnRequestedAt = "return_requested_at"
        case customerName = "customer_name"
        case customerAddress = "customer_address"
        case customerLatitude = "customer_latitude"
        case customerLongitude = "customer_longitude"
        case storeId = "store_id"
        case storeName = "store_name"
        case storeLatitude = "store_latitude"
        case storeLongitude = "store_longitude"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        orderId = (try? container.decode(Int.self, forKey: .orderId)) ?? 0
        driverId = try? container.decodeIfPresent(String.self, forKey: .driverId)
        productName = try? container.decodeIfPresent(String.self, forKey: .productName)
        productDescription = try? container.decodeIfPresent(String.self, forKey: .productDescription)
        productPrice = Self.decodeFlexibleDouble(container, forKey: .productPrice)
        productCurrency = try? container.decodeIfPresent(String.self, forKey: .productCurrency)
        productImageUrl = try? container.decodeIfPresent(String.self, forKey: .productImageUrl)
        quantity = Self.decodeFlexibleInt(container, forKey: .quantity)
        reason = (try? container.decode(String.self, forKey: .reason)) ?? ""
        status = (try? container.decode(String.self, forKey: .status)) ?? "pending"
        adminAccepted = Self.decodeFlexibleInt(container, forKey: .adminAccepted)
        storeReceived = Self.decodeFlexibleInt(container, forKey: .storeReceived)
        driverPickedUp = Self.decodeFlexibleInt(container, forKey: .driverPickedUp)
        deliveredAt = try? container.decodeIfPresent(String.self, forKey: .deliveredAt)
        returnRequestedAt = try? container.decodeIfPresent(String.self, forKey: .returnRequestedAt)
        customerName = try? container.decodeIfPresent(String.self, forKey: .customerName)
        customerAddress = try? container.decodeIfPresent(String.self, forKey: .customerAddress)
        customerLatitude = Self.decodeFlexibleDouble(container, forKey: .customerLatitude)
        customerLongitude = Self.decodeFlexibleDouble(container, forKey: .customerLongitude)
        storeId = Self.decodeFlexibleInt(container, forKey: .storeId)
        storeName = try? container.decodeIfPresent(String.self, forKey: .storeName)
        storeLatitude = Self.decodeFlexibleDouble(container, forKey: .storeLatitude)
        storeLongitude = Self.decodeFlexibleDouble(container, forKey: .storeLongitude)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        photos = try? container.decodeIfPresent([String].self, forKey: .photos)
    }

    private static func decodeFlexibleInt(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }

    private static func decodeFlexibleDouble(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }
}

struct ReturnOrdersResponse: Decodable {
    let success: Bool
    let data: [ReturnOrderItem]?
}

// Placeholder decodable for responses we don't care about
private struct EmptyData: Decodable {}
private struct GenericResponse: Decodable {
    let success: Bool?
    let message: String?
}

class ReturnService {
    static let shared = ReturnService()
    private init() {}

    // MARK: - Submit Return with 6 Photos (Multipart)
    static func submitReturnRequest(
        orderId: String,
        reason: String,
        photos: [(label: String, data: Data)]
    ) async throws -> ReturnSubmitResponse {
        let photoTypes = photos.map { $0.label }.joined(separator: ",")
        let parameters: [String: String] = [
            "order_id": orderId,
            "reason": reason,
            "photo_types": photoTypes
        ]

        let files = photos.map { photo in
            APIClient.MultipartFile(
                data: photo.data,
                fieldName: "photos",
                fileName: "\(photo.label)_\(Int(Date().timeIntervalSince1970)).jpg",
                mimeType: "image/jpeg"
            )
        }

        return try await APIClient.shared.uploadMultipartFiles(
            .submitReturnRequest,
            parameters: parameters,
            files: files
        )
    }

    // MARK: - Cancel Return (revert order to delivered)
    static func cancelReturnRequest(orderId: String) async throws {
        struct StatusBody: Encodable { let status: String }
        let _: GenericResponse = try await APIClient.shared.request(
            .cancelOrderReturn(orderId),
            body: StatusBody(status: "delivered")
        )
    }

    // MARK: - Get Return Orders (for delivery driver)
    static func getReturnOrders() async throws -> [ReturnOrderItem] {
        let response: ReturnOrdersResponse = try await APIClient.shared.request(.getReturnOrders)
        return response.data ?? []
    }

    // MARK: - Get Driver Pending Returns (assigned to the logged-in driver)
    static func getDriverPendingReturns() async throws -> [ReturnOrderItem] {
        let response: ReturnOrdersResponse = try await APIClient.shared.request(.getDriverReturnPickups)
        return response.data ?? []
    }

    // MARK: - Driver confirms pickup from customer
    static func markDriverPickedUp(returnId: String) async throws {
        let _: GenericResponse = try await APIClient.shared.request(
            .driverPickedUpReturn(returnId)
        )
    }

    // MARK: - Mark Store Received (driver delivered return to store)
    static func markStoreReceived(returnId: String) async throws {
        struct Body: Encodable { let store_received: Int }
        let _: GenericResponse = try await APIClient.shared.request(
            .storeReceivedReturn(returnId),
            body: Body(store_received: 1)
        )
    }

    // MARK: - Legacy: Create Return (text-only)
    static func createReturnRequest(
        orderId: String,
        reason: String,
        description: String?,
        images: [Data]? = nil
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
        let body = CreateRequest(orderId: orderId, reason: reason, description: description)
        return try await APIClient.shared.request(.createReturnRequest, body: body)
    }

    // MARK: - Get User Returns
    static func getUserReturns(page: Int = 1) async throws -> [ReturnRequest] {
        try await APIClient.shared.request(.getUserReturns)
    }
}

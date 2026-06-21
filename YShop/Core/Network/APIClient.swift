//
//  APIClient.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Pagination Info
struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
}

// MARK: - API Response Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
    let message: String?
    let timestamp: String?
    let pagination: PaginationInfo?
    
    enum CodingKeys: String, CodingKey {
        case success, data, message, timestamp, pagination
    }
}

// MARK: - API Error
enum APIError: LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case networkError
    case decodingError(String)
    case validationError(String)
    case unknown(String)
    case invalidRequest
    case timeout

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError:
            return "Network connection error. Check your internet."
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .invalidRequest:
            return "Invalid request."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Please log in with your credentials."
        case .forbidden:
            return "Contact support if you believe this is an error."
        case .networkError:
            return "Check your internet connection and try again."
        default:
            return "Please try again."
        }
    }
}

// MARK: - API Endpoint
enum APIEndpoint {
    // MARK: - Auth
    case login
    case signup
    case deliverySignup
    case deliveryLogin
    case verifyEmail
    case me
    case changePassword
    case logout

    // MARK: - Products
    case products
    case productDetail(String)
    case createProduct
    case updateProduct(String)
    case deleteProduct(String)

    // MARK: - Stores
    case stores
    case publicStores
    case storeDetail(String)
    case storeCategories(String)
    case storeProducts(Int)

    // MARK: - Cart
    case cart
    case addToCart
    case updateCartItem(String)
    case removeCartItem(String)
    case clearCart
    case checkout

    // MARK: - Orders
    case createOrder
    case getUserOrders
    case getOrderDetail(String)
    case sendOrderReceipt(String)
    case updateOrderStatus(String)
    case cancelOrder(String)
    case saveLiveActivityToken(String)

    // MARK: - Delivery
    case getDriverProfile
    case updateDriverLocation
    case toggleWorking
    case getDeliveryOffer(latitude: Double, longitude: Double)
    case acceptOffer(String)
    case skipOffer(String)
    case getSkippedOrders(latitude: Double, longitude: Double)
    case reclaimOrder(String)
    case getActiveOrder
    case pickupOrder(String)
    case deliverOrder(String)
    case updateDeliveryLocation(String)
    case getDeliveryHistory
    case getDriverStats

    // MARK: - AI Chat
    case sendAIMessage
    case getAIChatHistory
    case clearAIChat
    case getAIStatus

    // MARK: - Returns
    case createReturnRequest
    case submitReturnRequest
    case getUserReturns
    case getReturnDetail(String)
    case uploadReturnEvidence(String)
    case cancelOrderReturn(String)
    case getReturnOrders
    case getDriverReturnPickups
    case driverPickedUpReturn(String)
    case storeReceivedReturn(String)

    // MARK: - Complaints
    case submitComplaint
    case getMyComplaints
    case getComplaintDetail(Int)
    case getDriverComplaints

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        case .deliverySignup:
            return "/auth/delivery-signup"
        case .deliveryLogin:
            return "/auth/delivery-login"
        case .verifyEmail:
            return "/auth/verify-email"
        case .me:
            return "/auth/me"
        case .changePassword:
            return "/auth/change-password"
        case .logout:
            return "/auth/logout"

        case .products:
            return "/products"
        case .productDetail(let id):
            return "/products/\(id)"
        case .createProduct:
            return "/products"
        case .updateProduct(let id):
            return "/products/\(id)"
        case .deleteProduct(let id):
            return "/products/\(id)"

        case .stores:
            return "/stores"
        case .publicStores:
            return "/stores/public"
        case .storeDetail(let id):
            return "/stores/\(id)"
        case .storeCategories(let storeId):
            return "/stores/\(storeId)/categories"
        case .storeProducts(let storeId):
            return "/products?storeId=\(storeId)"

        case .cart:
            return "/cart"
        case .addToCart:
            return "/cart/add"
        case .updateCartItem(let itemId):
            return "/cart/item/\(itemId)"
        case .removeCartItem(let itemId):
            return "/cart/item/\(itemId)"
        case .clearCart:
            return "/cart"
        case .checkout:
            return "/cart/checkout"

        case .createOrder:
            return "/orders"
        case .getUserOrders:
            return "/orders/user"
        case .getOrderDetail(let id):
            return "/orders/\(id)"
        case .saveLiveActivityToken(let id):
            return "/orders/\(id)/live-activity-token"
        case .sendOrderReceipt(let id):
            return "/orders/\(id)/receipt"
        case .updateOrderStatus(let id):
            return "/orders/\(id)/status"
        case .cancelOrder(let id):
            return "/orders/\(id)/cancel"

        case .getDriverProfile:
            return "/delivery-requests/me"
        case .updateDriverLocation:
            return "/delivery-requests/location"
        case .toggleWorking:
            return "/delivery-requests/working"
        case .getDeliveryOffer(let latitude, let longitude):
            return "/delivery-requests/offer?latitude=\(latitude)&longitude=\(longitude)"
        case .acceptOffer(let offerId):
            return "/delivery-requests/offer/accept"
        case .skipOffer(let offerId):
            return "/delivery-requests/offer/skip"
        case .getSkippedOrders(let latitude, let longitude):
            return "/delivery-requests/skipped-orders?latitude=\(latitude)&longitude=\(longitude)"
        case .reclaimOrder(let orderId):
            return "/delivery-requests/reclaim"
        case .getActiveOrder:
            return "/delivery-requests/active-order"
        case .pickupOrder(let orderId):
            return "/delivery-requests/orders/\(orderId)/pickup"
        case .deliverOrder(let orderId):
            return "/delivery-requests/orders/\(orderId)/delivered"
        case .updateDeliveryLocation(let orderId):
            return "/delivery-requests/orders/\(orderId)/location"
        case .getDeliveryHistory:
            return "/delivery-requests/history"
        case .getDriverStats:
            return "/delivery-requests/stats"

        case .sendAIMessage:
            return "/ai/messages"
        case .getAIChatHistory:
            return "/ai/history"
        case .clearAIChat:
            return "/ai/history"
        case .getAIStatus:
            return "/ai/status"

        case .createReturnRequest:
            return "/returns"
        case .submitReturnRequest:
            return "/returns/submit"
        case .getUserReturns:
            return "/returns"
        case .getReturnDetail(let id):
            return "/returns/\(id)"
        case .uploadReturnEvidence(let returnId):
            return "/returns/\(returnId)/evidence"
        case .cancelOrderReturn(let orderId):
            return "/orders/\(orderId)/status"
        case .getReturnOrders:
            return "/returns/list"
        case .getDriverReturnPickups:
            return "/returns/driver/pending"
        case .driverPickedUpReturn(let returnId):
            return "/returns/\(returnId)/driver-picked-up"
        case .storeReceivedReturn(let returnId):
            return "/returns/\(returnId)/store-received"
        case .submitComplaint:
            return "/complaints"
        case .getMyComplaints:
            return "/complaints/my"
        case .getComplaintDetail(let id):
            return "/complaints/\(id)"
        case .getDriverComplaints:
            return "/complaints/driver"
        }
    }

    var method: HTTPMethod {
        switch self {
                case .login, .signup, .deliverySignup, .deliveryLogin, .verifyEmail, .createProduct,
                                                 .addToCart, .checkout, .createOrder, .acceptOffer, .pickupOrder, .deliverOrder,
                             .sendOrderReceipt,
                         .sendAIMessage, .createReturnRequest, .uploadReturnEvidence, .submitReturnRequest, .submitComplaint:
            return .post

        case .saveLiveActivityToken:
            return .post

        case .cancelOrderReturn:
            return .put

                case .driverPickedUpReturn, .storeReceivedReturn:
                        return .put

        case .updateProduct, .updateOrderStatus, .updateCartItem, .updateDriverLocation, .updateDeliveryLocation:
            return .put

        case .deleteProduct, .removeCartItem, .cancelOrder, .clearCart:
            return .delete

        case .skipOffer:
            return .post

        case .changePassword:
            return .patch

        case .toggleWorking:
            return .put

        case .reclaimOrder:
            return .post

        default:
            return .get
        }
    }
}

// MARK: - APIClient
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private var baseURL: String
    private let baseURLCandidates: [String]
    private let requestTimeout: TimeInterval = 5

    private init(baseURL: String = "") {
        self.baseURLCandidates = AppConstants.baseURLCandidates
        self.baseURL = baseURL.isEmpty ? (baseURLCandidates.first ?? AppConstants.baseURL) : baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        config.requestCachePolicy = .returnCacheDataElseLoad

        self.session = URLSession(configuration: config)
    }

    // MARK: - Auto-Discovery
    /// Scans the local subnet for the YShop server and caches the found URL.
    /// Call once at app launch — runs in background.
    func discoverServerIfNeeded() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            if let found = await ServerDiscovery.findServer() {
                await MainActor.run {
                    self.baseURL = found
                    UserDefaults.standard.set(found, forKey: "lastWorkingAPIURL")
                    #if DEBUG
                    print("🔍 [DISCOVERY] Found server at: \(found)")
                    #endif
                }
            }
        }
    }

    // MARK: - Generic Request
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        retryCount: Int = 0
    ) async throws -> T {
        let url = try buildURL(for: endpoint)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.timeoutInterval = requestTimeout
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

        // Add headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add JWT token if available
        if let token = await AuthManager.shared.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if present
        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        #if DEBUG
        logRequest(urlRequest)
        #endif

        do {
            let (data, response) = try await session.data(for: urlRequest)

            #if DEBUG
            logResponse(response, data: data)
            #endif

            try validateResponse(response, data: data)
            // Cache the working URL so next launch starts with it
            UserDefaults.standard.set(baseURL, forKey: "lastWorkingAPIURL")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)

        } catch let error as APIError {
            // Handle specific authentication errors
            // Only logout on 401 if NOT on an auth endpoint (login/signup/verify don't need auto-logout)
            if case .unauthorized = error {
                // Check if this is an auth endpoint that shouldn't trigger logout
                let isAuthEndpoint: Bool
                switch endpoint {
                case .login, .signup, .deliveryLogin, .deliverySignup, .verifyEmail:
                    isAuthEndpoint = true
                default:
                    isAuthEndpoint = false
                }
                
                // Only auto-logout on protected resource access (not during auth attempts)
                if !isAuthEndpoint {
                    Task {
                        try? await AuthManager.shared.logout()
                    }
                }
            }
            throw error
        } catch {
            if shouldAttemptFailover(error), let fallbackURL = nextBaseURL(current: baseURL) {
                #if DEBUG
                print("🔁 [API] Failover from \(baseURL) to \(fallbackURL)")
                #endif
                baseURL = fallbackURL
                return try await request(endpoint, body: body, retryCount: retryCount + 1)
            }

            if retryCount < 1 {
                // Retry once on transient errors
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                return try await request(endpoint, body: body, retryCount: retryCount + 1)
            }
            throw mapError(error)
        }
    }

    // MARK: - Multipart Upload
    func uploadMultipart<T: Decodable>(
        _ endpoint: APIEndpoint,
        parameters: [String: String] = [:],
        fileData: Data,
        fileName: String,
        mimeType: String = "image/jpeg"
    ) async throws -> T {
        let url = try buildURL(for: endpoint)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60 // Longer timeout for uploads

        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if let token = await AuthManager.shared.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.httpBody = body

        #if DEBUG
        logRequest(urlRequest)
        #endif

        let (data, response) = try await session.data(for: urlRequest)

        #if DEBUG
        logResponse(response, data: data)
        #endif

        try validateResponse(response, data: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Multipart Upload (Multiple Files)
    struct MultipartFile {
        let data: Data
        let fieldName: String
        let fileName: String
        let mimeType: String
    }

    func uploadMultipartFiles<T: Decodable>(
        _ endpoint: APIEndpoint,
        parameters: [String: String] = [:],
        files: [MultipartFile]
    ) async throws -> T {
        let url = try buildURL(for: endpoint)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 120

        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = await AuthManager.shared.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        let crlf = "\r\n".data(using: .utf8)!

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append(crlf)
        }

        for file in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append(crlf)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response, data: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Private Helpers
    private func buildURL(for endpoint: APIEndpoint) throws -> URL {
        let path = endpoint.path
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidRequest
        }
        return url
    }

    private func nextBaseURL(current: String) -> String? {
        guard let idx = baseURLCandidates.firstIndex(of: current) else {
            return baseURLCandidates.first
        }
        let nextIdx = idx + 1
        guard nextIdx < baseURLCandidates.count else { return nil }
        return baseURLCandidates[nextIdx]
    }

    private func shouldAttemptFailover(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        switch nsError.code {
        case NSURLErrorTimedOut,
             NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorDNSLookupFailed:
            return true
        default:
            return false
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }

        switch httpResponse.statusCode {
        case 200...299:
            break // Success
        case 401:
            throw APIError.unauthorized
        case 403:
            // Check if it's an email verification issue
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        print("📋 [API] 403 Error: \(message)")
                        throw APIError.validationError(message)
                    }
                } catch let error as APIError {
                    throw error
                } catch {
                    print("⚠️ [API] Could not parse 403 error response")
                }
            }
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 400:
            throw APIError.invalidRequest
        case 500...599:
            // Try to extract error message from response body
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        print("📋 [API] Backend error message: \(message)")
                        throw APIError.serverError(message)
                    }
                } catch let error as APIError {
                    throw error
                } catch {
                    // If JSON parsing fails, use generic error
                    print("⚠️ [API] Could not parse error response: \(error)")
                }
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        default:
            throw APIError.unknown("HTTP \(httpResponse.statusCode)")
        }
    }

    private func mapError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkError
            case NSURLErrorTimedOut:
                return .timeout
            default:
                return .networkError
            }
        }

        if error is DecodingError {
            return .decodingError(error.localizedDescription)
        }

        return .unknown(error.localizedDescription)
    }

    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("[API Request]")
        print("URL: \(request.url?.absoluteString ?? "N/A")")
        print("Method: \(request.httpMethod ?? "N/A")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }

    private func logResponse(_ response: URLResponse, data: Data) {
        if let httpResponse = response as? HTTPURLResponse {
            print("[API Response]")
            print("Status: \(httpResponse.statusCode)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("Data: \(dataString)")
            }
        }
    }
    #endif
}

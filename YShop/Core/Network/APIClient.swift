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
    case updateOrderStatus(String)
    case cancelOrder(String)

    // MARK: - Delivery
    case getDriverProfile
    case updateDriverLocation
    case toggleWorking
    case getDeliveryOffer
    case acceptOffer(String)
    case skipOffer(String)
    case getSkippedOrders
    case reclaimOrder(String)
    case getActiveOrder
    case pickupOrder(String)
    case deliverOrder(String)
    case updateDeliveryLocation
    case getDeliveryHistory
    case getDriverStats

    // MARK: - AI Chat
    case sendAIMessage
    case getAIChatHistory
    case clearAIChat
    case getAIStatus

    // MARK: - Returns
    case createReturnRequest
    case getUserReturns
    case getReturnDetail(String)
    case uploadReturnEvidence(String)

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

        case .cart:
            return "/cart"
        case .addToCart:
            return "/cart/items"
        case .updateCartItem(let itemId):
            return "/cart/items/\(itemId)"
        case .removeCartItem(let itemId):
            return "/cart/items/\(itemId)"
        case .clearCart:
            return "/cart"
        case .checkout:
            return "/cart/checkout"

        case .createOrder:
            return "/orders"
        case .getUserOrders:
            return "/orders"
        case .getOrderDetail(let id):
            return "/orders/\(id)"
        case .updateOrderStatus(let id):
            return "/orders/\(id)/status"
        case .cancelOrder(let id):
            return "/orders/\(id)/cancel"

        case .getDriverProfile:
            return "/delivery/profile"
        case .updateDriverLocation:
            return "/delivery/location"
        case .toggleWorking:
            return "/delivery/toggle-working"
        case .getDeliveryOffer:
            return "/delivery/offers/next"
        case .acceptOffer(let offerId):
            return "/delivery/offers/\(offerId)/accept"
        case .skipOffer(let offerId):
            return "/delivery/offers/\(offerId)/skip"
        case .getSkippedOrders:
            return "/delivery/skipped-orders"
        case .reclaimOrder(let orderId):
            return "/delivery/skipped-orders/\(orderId)/reclaim"
        case .getActiveOrder:
            return "/delivery/active-order"
        case .pickupOrder(let orderId):
            return "/delivery/orders/\(orderId)/pickup"
        case .deliverOrder(let orderId):
            return "/delivery/orders/\(orderId)/deliver"
        case .updateDeliveryLocation:
            return "/delivery/location"
        case .getDeliveryHistory:
            return "/delivery/history"
        case .getDriverStats:
            return "/delivery/stats"

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
        case .getUserReturns:
            return "/returns"
        case .getReturnDetail(let id):
            return "/returns/\(id)"
        case .uploadReturnEvidence(let returnId):
            return "/returns/\(returnId)/evidence"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .signup, .deliverySignup, .deliveryLogin, .verifyEmail, .createProduct,
             .addToCart, .checkout, .createOrder, .acceptOffer, .pickupOrder, .deliverOrder,
             .sendAIMessage, .createReturnRequest, .uploadReturnEvidence:
            return .post

        case .updateProduct, .updateOrderStatus, .updateCartItem, .updateDriverLocation:
            return .put

        case .deleteProduct, .removeCartItem, .cancelOrder, .skipOffer:
            return .delete

        case .changePassword, .toggleWorking, .reclaimOrder:
            return .patch

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
    private let requestTimeout: TimeInterval = 30

    private init(baseURL: String = "") {
        self.baseURLCandidates = AppConstants.baseURLCandidates
        self.baseURL = baseURL.isEmpty ? (baseURLCandidates.first ?? AppConstants.baseURL) : baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: config)
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

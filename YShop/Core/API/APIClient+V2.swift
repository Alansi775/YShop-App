import Foundation

/// Namespace for everything that talks to the v2 API (NestJS).
/// Old v1 code keeps its own `APIClient` until its screens are replaced.
enum API {
    static let client = Client()
}

extension API {
    /// One client for the whole app.
    ///
    /// - Adds the access token to every request.
    /// - On 401 refreshes once and retries; concurrent 401s share ONE refresh.
    /// - A refresh the server rejects signs the person out (`onSessionExpired`).
    actor Client {
        private let session: URLSession
        private let decoder: JSONDecoder
        private let encoder: JSONEncoder
        private var tokens: Tokens?
        private var refreshing: Task<Tokens, Error>?

        /// Called (on the main actor) when the session can't be renewed.
        @MainActor var onSessionExpired: (() -> Void)?

        init() {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = Config.timeout
            config.waitsForConnectivity = false
            config.requestCachePolicy = .useProtocolCachePolicy
            config.urlCache = URLCache(memoryCapacity: 20 << 20, diskCapacity: 100 << 20)
            session = URLSession(configuration: config)

            decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { d in
                let raw = try d.singleValueContainer().decode(String.self)
                if let date = Client.iso.date(from: raw) ?? Client.isoNoFraction.date(from: raw) { return date }
                throw DecodingError.dataCorrupted(.init(codingPath: d.codingPath, debugDescription: "Bad date \(raw)"))
            }
            encoder = JSONEncoder()
            tokens = TokenStore.load()
        }

        private static let iso: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        private static let isoNoFraction = ISO8601DateFormatter()

        var isSignedIn: Bool { tokens != nil }

        func store(_ new: Tokens?) {
            tokens = new
            if let new { TokenStore.save(new) } else { TokenStore.clear() }
        }


        // MARK: Verbs

        func get<T: Decodable>(_ path: String, query: [String: String?] = [:]) async throws -> T {
            try await send(path, method: "GET", query: query, body: Optional<Empty>.none)
        }

        func post<T: Decodable, B: Encodable>(_ path: String, _ body: B) async throws -> T {
            try await send(path, method: "POST", body: body)
        }

        func post<B: Encodable>(_ path: String, _ body: B) async throws {
            let _: Empty = try await send(path, method: "POST", body: body)
        }

        func patch<T: Decodable, B: Encodable>(_ path: String, _ body: B) async throws -> T {
            try await send(path, method: "PATCH", body: body)
        }

        func delete(_ path: String) async throws {
            let _: Empty = try await send(path, method: "DELETE", body: Optional<Empty>.none)
        }

        // MARK: Core

        private func send<T: Decodable, B: Encodable>(
            _ path: String, method: String, query: [String: String?] = [:], body: B?, retried: Bool = false
        ) async throws -> T {
            var request = try makeRequest(path, method: method, query: query, body: body)
            if let access = tokens?.access { request.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization") }

            let (data, response) = try await perform(request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            if status == 401, tokens != nil, !retried, !path.hasPrefix("/auth/") {
                _ = try await renewTokens()
                return try await send(path, method: method, query: query, body: body, retried: true)
            }
            guard (200..<300).contains(status) else {
                throw (try? decoder.decode(FailureEnvelope.self, from: data).error)
                    ?? Failure(status: status, code: "HTTP_\(status)", message: Failure.unreachable.message)
            }
            if T.self == Empty.self || data.isEmpty { return Empty() as! T }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("⚠️ API decode \(method) \(path): \(error)")
                #endif
                throw Failure.decoding
            }
        }

        private func makeRequest<B: Encodable>(_ path: String, method: String, query: [String: String?], body: B?) throws -> URLRequest {
            var components = URLComponents(url: Config.baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
            let items = query.compactMap { k, v in v.map { URLQueryItem(name: k, value: $0) } }
            if !items.isEmpty { components.queryItems = items }
            var request = URLRequest(url: components.url!)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if let body, !(body is Empty) {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            return request
        }

        private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
            do {
                return try await session.data(for: request)
            } catch let error as URLError {
                switch error.code {
                case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: throw Failure.offline
                case .cancelled: throw CancellationError()
                default: throw Failure.unreachable
                }
            }
        }

        /// Single-flight refresh: whoever comes second waits for the first.
        private func renewTokens() async throws -> Tokens {
            if let refreshing { return try await refreshing.value }
            guard let current = tokens else { throw Failure.sessionExpired }

            let task = Task<Tokens, Error> {
                let request = try makeRequest("/auth/refresh", method: "POST", query: [:], body: ["refreshToken": current.refresh])
                let (data, response) = try await perform(request)
                guard (response as? HTTPURLResponse)?.statusCode == 200,
                      let auth = try? decoder.decode(AuthResponse.self, from: data) else {
                    throw Failure.sessionExpired
                }
                return Tokens(access: auth.accessToken, refresh: auth.refreshToken)
            }
            refreshing = task
            defer { refreshing = nil }
            do {
                let new = try await task.value
                store(new)
                return new
            } catch {
                store(nil)
                await MainActor.run { onSessionExpired?() }
                throw Failure.sessionExpired
            }
        }
    }

    struct Empty: Codable {}
}

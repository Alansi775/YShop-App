import Foundation

struct AIChatResult {
    let message: String
    let products: [[String: Any]]
    let voiceMood: String
    let voiceIntensity: Double
}

actor AIChatService {
    static let shared = AIChatService()
    private init() {}

    // MARK: - Chat

    func chat(message: String, userId: String) async throws -> AIChatResult {
        var req = try await makeRequest(path: "/ai/chat", method: "POST")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "message": message,
            "userId": userId,
            "language": "auto"
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let d    = json["data"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        let products = d["products"] as? [[String: Any]] ?? []
        let mood      = d["voiceMood"]      as? String ?? "neutral"
        let intensity = d["voiceIntensity"] as? Double ?? 0.65
        return AIChatResult(message: d["message"] as? String ?? "", products: products,
                            voiceMood: mood, voiceIntensity: intensity)
    }

    // MARK: - Interaction Tracking (fire-and-forget)

    func trackInteraction(userId: String, productId: Int, query: String?, storeType: String?) async {
        guard var req = try? await makeRequest(path: "/ai/interact", method: "POST") else { return }
        var body: [String: Any] = ["userId": userId, "productId": productId, "eventType": "add_to_cart"]
        if let q  = query     { body["query"]     = q  }
        if let st = storeType { body["storeType"] = st }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String) async throws -> URLRequest {
        let base = UserDefaults.standard.string(forKey: "lastWorkingAPIURL") ?? AppConstants.baseURL
        guard let url = URL(string: "\(base)\(path)") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 20
        let token = await MainActor.run { AuthManager.shared.token }
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return req
    }
}

import Foundation

extension API {
    /// Every server error has one shape: `{ "error": { status, code, message } }`.
    /// `message` is already written for people — show it as is.
    struct Failure: LocalizedError, Decodable, Equatable {
        let status: Int
        let code: String
        let message: String

        var errorDescription: String? { message }

        static let offline = Failure(status: 0, code: "OFFLINE", message: "You're offline. Check your connection and try again.")
        static let unreachable = Failure(status: 0, code: "UNREACHABLE", message: "Can't reach YShop right now. Try again in a moment.")
        static let decoding = Failure(status: 0, code: "DECODING", message: "Something went wrong. Try again.")
        static let sessionExpired = Failure(status: 401, code: "SESSION_EXPIRED", message: "Please sign in again.")
    }

    struct FailureEnvelope: Decodable { let error: Failure }
}

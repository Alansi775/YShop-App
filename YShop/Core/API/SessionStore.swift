import Foundation
import Observation

/// Who is using the app right now. The root view switches on `phase`.
///
/// Browsing never needs an account: a guest sees stores and products, and
/// signs in only when an action needs it (cart, checkout, orders).
@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case launching
        case guest
        case signedIn(API.User)
    }

    static let shared = SessionStore()

    private(set) var phase: Phase = .launching

    var user: API.User? {
        if case .signedIn(let u) = phase { return u }
        return nil
    }

    private init() {
        API.client.onSessionExpiredOnMain { [weak self] in self?.phase = .guest }
    }

    /// At launch: a saved session is checked with the server; offline we stay
    /// signed in with nothing shown until the network returns.
    func restore() async {
        guard await API.client.isSignedIn else { phase = .guest; return }
        do {
            phase = .signedIn(try await API.Auth.me())
        } catch let failure as API.Failure where failure.code == API.Failure.sessionExpired.code {
            phase = .guest
        } catch {
            // Offline or server down — keep the tokens, retry on next launch.
            phase = .guest
        }
    }

    func login(email: String, password: String) async throws {
        try await adopt(API.Auth.login(email: email, password: password))
    }

    func register(_ registration: API.Auth.Registration) async throws {
        try await adopt(API.Auth.register(registration))
    }

    func signInWithApple(identityToken: String, firstName: String?, lastName: String?) async throws {
        try await adopt(API.Auth.apple(identityToken: identityToken, firstName: firstName, lastName: lastName))
    }

    func signInWithGoogle(idToken: String) async throws {
        try await adopt(API.Auth.google(idToken: idToken))
    }

    func signOut() async {
        if let tokens = API.TokenStore.load() {
            try? await API.Auth.logout(refreshToken: tokens.refresh)
        }
        await API.client.store(nil)
        phase = .guest
    }

    private func adopt(_ auth: API.AuthResponse) async {
        await API.client.store(API.Tokens(access: auth.accessToken, refresh: auth.refreshToken))
        phase = .signedIn(auth.user)
    }
}

private extension API.Client {
    /// Sets the handler without awaiting the actor from a sync init.
    nonisolated func onSessionExpiredOnMain(_ handler: @escaping @MainActor () -> Void) {
        Task { @MainActor in self.onSessionExpired = handler }
    }
}

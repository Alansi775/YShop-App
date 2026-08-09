import Foundation
import SwiftUI
import Combine
import GoogleSignIn

// MARK: - Enums
enum UserRole: String, Codable {
    case customer, driver, deliveryDriver
}

// MARK: - Request Models
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct SignupRequest: Encodable {
    let email: String
    let password: String
    let display_name: String
    let phone: String
    let national_id: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let building_info: String?
    let apartment_number: String?
    let delivery_instructions: String?
}

struct DeliverySignupRequest: Encodable {
    let email: String
    let password: String
    let name: String
    let phone: String
    let national_id: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let building_info: String?
    let apartment_number: String?
    let delivery_instructions: String?
}

struct ChangePasswordRequest: Encodable {
    let oldPassword: String
    let newPassword: String
    enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newPassword = "new_password"
    }
}

// MARK: - Response Models
struct SimpleUser: Codable, Equatable {
    let id: String
    let name: String
    let surname: String?
    let email: String
    let phone: String?
    let avatar: String?
    let role: String
    let isActive: Bool
    let isVerified: Bool
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let buildingInfo: String?
    let apartmentNumber: String?
    let deliveryInstructions: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, avatar
        case name = "display_name"
        case namePlain = "name"
        case surname
        case role = "userType"
        case rolePlain = "role"
        case isActive = "is_active"
        case isVerified = "is_verified"
        case emailVerified = "email_verified"
        case address
        case latitude
        case longitude
        case buildingInfo = "building_info"
        case buildingInfoAlt = "buildingInfo"
        case apartmentNumber = "apartment_number"
        case apartmentNumberAlt = "apartmentNumber"
        case deliveryInstructions = "delivery_instructions"
        case deliveryInstructionsAlt = "deliveryInstructions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either String or Int
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = (try? container.decode(String.self, forKey: .id)) ?? ""
        }
        
        let preferredName = (try? container.decode(String.self, forKey: .name))
            ?? (try? container.decode(String.self, forKey: .namePlain))
            ?? ""
        let preferredSurname = try? container.decodeIfPresent(String.self, forKey: .surname)
        name = preferredSurname?.isEmpty == false ? "\(preferredName) \(preferredSurname!)" : preferredName
        surname = preferredSurname
        email = try container.decode(String.self, forKey: .email)
        phone = try? container.decode(String.self, forKey: .phone)
        avatar = try? container.decode(String.self, forKey: .avatar)
        role = (try? container.decode(String.self, forKey: .role)) ?? (try? container.decode(String.self, forKey: .rolePlain)) ?? "customer"
        isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
        isVerified = Self.decodeFlexibleBool(container, primaryKey: .isVerified, fallbackKey: .emailVerified)
        address = try? container.decodeIfPresent(String.self, forKey: .address)
        
        // Handle latitude - try Double first, then String
        if let latDouble = try? container.decodeIfPresent(Double.self, forKey: .latitude) {
            latitude = latDouble
        } else if let latString = try? container.decodeIfPresent(String.self, forKey: .latitude) {
            latitude = Double(latString)
        } else {
            latitude = nil
        }
        
        // Handle longitude - try Double first, then String
        if let lonDouble = try? container.decodeIfPresent(Double.self, forKey: .longitude) {
            longitude = lonDouble
        } else if let lonString = try? container.decodeIfPresent(String.self, forKey: .longitude) {
            longitude = Double(lonString)
        } else {
            longitude = nil
        }
        
        buildingInfo = (try? container.decodeIfPresent(String.self, forKey: .buildingInfo))
            ?? (try? container.decodeIfPresent(String.self, forKey: .buildingInfoAlt))
        apartmentNumber = (try? container.decodeIfPresent(String.self, forKey: .apartmentNumber))
            ?? (try? container.decodeIfPresent(String.self, forKey: .apartmentNumberAlt))
        deliveryInstructions = (try? container.decodeIfPresent(String.self, forKey: .deliveryInstructions))
            ?? (try? container.decodeIfPresent(String.self, forKey: .deliveryInstructionsAlt))
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(surname, forKey: .surname)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(avatar, forKey: .avatar)
        try container.encode(role, forKey: .role)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(buildingInfo, forKey: .buildingInfo)
        try container.encodeIfPresent(apartmentNumber, forKey: .apartmentNumber)
        try container.encodeIfPresent(deliveryInstructions, forKey: .deliveryInstructions)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    private static func decodeFlexibleBool(_ container: KeyedDecodingContainer<CodingKeys>, primaryKey: CodingKeys, fallbackKey: CodingKeys) -> Bool {
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: primaryKey) {
            return boolValue ?? false
        }

        if let intValue = try? container.decodeIfPresent(Int.self, forKey: primaryKey) {
            return (intValue ?? 0) == 1
        }

        if let stringValue = try? container.decodeIfPresent(String.self, forKey: primaryKey) {
            return ["1", "true", "yes"].contains(stringValue.lowercased())
        }

        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: fallbackKey) {
            return boolValue ?? false
        }

        if let intValue = try? container.decodeIfPresent(Int.self, forKey: fallbackKey) {
            return (intValue ?? 0) == 1
        }

        if let stringValue = try? container.decodeIfPresent(String.self, forKey: fallbackKey) {
            return ["1", "true", "yes"].contains(stringValue.lowercased())
        }

        return false
    }
}

struct AuthResponse: Decodable {
    let token: String
    let user: SimpleUser
}

struct UserResponse: Decodable {
    let user: SimpleUser?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try to decode user if it exists
        self.user = try container.decodeIfPresent(SimpleUser.self, forKey: .user)
    }
    
    enum CodingKeys: String, CodingKey {
        case user
    }
}

struct SignupResponse: Decodable {
    let success: Bool
    let message: String
    let email: String
}

struct DeliverySignupResponse: Decodable {
    let success: Bool
    let message: String
    let email: String
    let uid: String?
}

struct EmptyResponse: Decodable {}

struct GoogleProfileInfo: Decodable {
    let email: String
    let givenName: String?
    let familyName: String?
    let name: String?
}

struct GoogleAuthResponse: Decodable {
    let success: Bool
    let token: String?
    let isNewUser: Bool?
    let needsProfileCompletion: Bool?
    let user: SimpleUser?
    let message: String?
    // Present only when isNewUser == true — no account/session exists yet.
    let pendingSignupToken: String?
    let googleProfile: GoogleProfileInfo?
}

struct GoogleAuthResult {
    let needsProfileCompletion: Bool
}

@MainActor
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn = false
    @Published var userRole: UserRole?
    @Published var currentUser: SimpleUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
@Published var heading: Double? = nil
    // Set only while a NEW Google user is mid-signup: the pending token
    // plus whatever name Google actually gave us, held between
    // signInWithGoogle and the required-fields form being submitted
    // (completeGoogleSignup). In-memory only — if the user backs out of
    // CompleteProfileView, this is just discarded and nothing was ever
    // written to the database.
    @Published var pendingGoogleProfile: GoogleProfileInfo?
    private var pendingGoogleSignupToken: String?

    private let keychainHelper = KeychainHelper.shared
    private let session: URLSession
    private let baseURL = AppConstants.baseURL
    private let tokenKey = "authToken"
    private let roleKey = "userRole"

    var token: String? {
        get { try? keychainHelper.readString(for: tokenKey) }
        set {
            if let newValue = newValue {
                try? keychainHelper.saveString(newValue, for: tokenKey)
            } else {
                try? keychainHelper.delete(for: tokenKey)
            }
        }
    }

    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        super.init()
        checkAuthStatus()
    }

    func checkAuthStatus() {
        if let token = token, !token.isEmpty {
            print("🔍 [AUTH] Found token in Keychain, verifying...")
            // Load role from UserDefaults if available
            if let roleStr = UserDefaults.standard.string(forKey: roleKey),
               let role = UserRole(rawValue: roleStr) {
                userRole = role
                print("✅ [AUTH] Role found in UserDefaults: \(roleStr)")
                // Only fetch if we have a valid role
                print("📡 [AUTH] Verifying token with server...")
                fetchCurrentUser()
            } else {
                print("⚠️  [AUTH] No role in UserDefaults - attempting to recover from token")
                // Try to decode role from token payload first (safe, no signature verification)
                if let decodedRole = decodeRoleFromJWT(token) {
                    if let role = UserRole(rawValue: decodedRole) {
                        userRole = role
                        UserDefaults.standard.set(decodedRole, forKey: roleKey)
                        print("✅ [AUTH] Role decoded from token: \(decodedRole)")
                        print("📡 [AUTH] Verifying token with server...")
                        fetchCurrentUser()
                        return
                    }
                }

                // Fallback: verify token with server (do not clear token immediately)
                print("📡 [AUTH] Role not available locally — verifying token with server...")
                fetchCurrentUser()
            }
        } else {
            print("🚪 [AUTH] No token found - user not logged in")
            isLoggedIn = false
            userRole = nil
            currentUser = nil
        }
    }

    func refreshCurrentUser() async {
        guard let token = self.token else {
            // Token may be transiently unreadable (device still locking/unlocking).
            // Only sign out if we were never logged in — don't clear a valid session.
            if self.currentUser == nil {
                print("🚪 [AUTH] No token and no cached user — not logged in")
                self.isLoggedIn = false
            } else {
                print("⚠️ [AUTH] Token temporarily unreadable — keeping session alive")
            }
            return
        }

        let url = URL(string: "\(baseURL)/auth/me")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("❌ [AUTH] Token invalid (401) while refreshing user")
                self.isLoggedIn = false
                self.currentUser = nil
                UserDefaults.standard.removeObject(forKey: self.roleKey)
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            var resolvedUser: SimpleUser? = nil

            if let apiResp = try? decoder.decode(APIResponse<SimpleUser>.self, from: data) {
                resolvedUser = apiResp.data
            }

            if resolvedUser == nil, let directUser = try? decoder.decode(SimpleUser.self, from: data) {
                resolvedUser = directUser
            }

            if resolvedUser == nil, let userResp = try? decoder.decode(UserResponse.self, from: data), let u = userResp.user {
                resolvedUser = u
            }

            if let user = resolvedUser {
                self.currentUser = user
                self.isLoggedIn = true
                print("✅ [AUTH] Refreshed current user: \(user.email)")
                if let token = self.token {
                    SocketService.shared.connectIfNeeded(token: token)
                }
                self.refreshPostAuthState(for: self.userRole)
            } else {
                print("❌ [AUTH] Failed to refresh current user")
            }
        } catch {
            print("❌ [AUTH] Failed to refresh current user: \(error)")
        }
    }

    // Attempt to decode the JWT payload and extract a role/userType field.
    // This does NOT verify the token signature; it's only used to recover cached role info.
    private func decodeRoleFromJWT(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let payloadPart = String(parts[1])

        // Pad base64 string
        var base64 = payloadPart
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // Common claim keys: "role", "userType"
                if let role = json["role"] as? String { return role }
                if let userType = json["userType"] as? String { return userType }
                if let r = json["user_type"] as? String { return r }
            }
        } catch {
            print("⚠️ [AUTH] Failed to decode JWT payload: \(error)")
        }
        return nil
    }

    private func fetchCurrentUser() {
        Task { await refreshCurrentUser() }
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        let request = LoginRequest(email: email, password: password)
        let url = URL(string: "\(baseURL)/auth/login")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, _) = try await session.data(for: urlRequest)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            DispatchQueue.main.async {
                self.token = response.token
                self.isLoggedIn = true
                self.userRole = .customer
                UserDefaults.standard.set(UserRole.customer.rawValue, forKey: self.roleKey)
                self.currentUser = response.user
                self.isLoading = false
                SocketService.shared.connectIfNeeded(token: response.token)
                self.refreshPostAuthState(for: .customer)
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
            throw error
        }
    }

    /// Sign in (or sign up, transparently) with Google. Unlike the web
    /// build's own Google Sign-In (which needs Google's own rendered
    /// button to reliably get an ID token), the native iOS SDK's
    /// imperative `signIn(withPresenting:)` flow returns one just fine —
    /// no such platform quirk here.
    /// Throws `GIDSignInError.canceled` if the user dismisses the picker
    /// (callers should treat that as "do nothing", not a real error).
    func signInWithGoogle(presenting: UIViewController) async throws -> GoogleAuthResult {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google sign-in did not return an ID token"])
        }

        let url = URL(string: "\(baseURL)/auth/google")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(["idToken": idToken])

        let (data, _) = try await session.data(for: urlRequest)
        let decoded = try JSONDecoder().decode(GoogleAuthResponse.self, from: data)

        guard decoded.success else {
            throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: decoded.message ?? "Google sign-in failed"])
        }

        if decoded.isNewUser == true {
            // No account exists yet — nothing to save. Just remember the
            // pending token + Google's name fields for CompleteProfileView.
            pendingGoogleSignupToken = decoded.pendingSignupToken
            pendingGoogleProfile = decoded.googleProfile
            return GoogleAuthResult(needsProfileCompletion: true)
        }

        guard let token = decoded.token, let user = decoded.user else {
            throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: decoded.message ?? "Google sign-in failed"])
        }

        self.token = token
        self.isLoggedIn = true
        self.userRole = .customer
        UserDefaults.standard.set(UserRole.customer.rawValue, forKey: self.roleKey)
        self.currentUser = user
        SocketService.shared.connectIfNeeded(token: token)
        self.refreshPostAuthState(for: .customer)

        return GoogleAuthResult(needsProfileCompletion: decoded.needsProfileCompletion ?? false)
    }

    /// Submits the required-fields form for a first-time Google sign-up
    /// (see CompleteProfileView) — creates the account and a real session
    /// together in one call, using the pending token from signInWithGoogle.
    /// [firstName]/[surname] are only used as a fallback for whatever
    /// Google itself didn't provide — the backend ignores them if Google
    /// already gave us that field, since it can't be overridden client-side.
    func completeGoogleSignup(
        phone: String,
        nationalId: String,
        address: String,
        latitude: Double?,
        longitude: Double?,
        buildingInfo: String,
        apartmentNumber: String,
        deliveryInstructions: String,
        firstName: String,
        surname: String
    ) async throws {
        guard let pendingToken = pendingGoogleSignupToken else {
            throw NSError(domain: "AuthManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "No pending Google sign-in — please sign in with Google again"])
        }

        let url = URL(string: "\(baseURL)/auth/google/complete-signup")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "pendingSignupToken": pendingToken,
            "phone": phone,
            "nationalId": nationalId,
            "address": address,
            "buildingInfo": buildingInfo,
            "apartmentNumber": apartmentNumber,
            "deliveryInstructions": deliveryInstructions,
            "firstName": firstName,
            "surname": surname,
        ]
        if let latitude { body["latitude"] = latitude }
        if let longitude { body["longitude"] = longitude }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: urlRequest)
        let decoded = try JSONDecoder().decode(GoogleAuthResponse.self, from: data)

        guard decoded.success, let token = decoded.token, let user = decoded.user else {
            throw NSError(domain: "AuthManager", code: -5, userInfo: [NSLocalizedDescriptionKey: decoded.message ?? "Failed to complete sign-up"])
        }

        self.token = token
        self.isLoggedIn = true
        self.userRole = .customer
        UserDefaults.standard.set(UserRole.customer.rawValue, forKey: self.roleKey)
        self.currentUser = user
        pendingGoogleSignupToken = nil
        pendingGoogleProfile = nil
        SocketService.shared.connectIfNeeded(token: token)
        self.refreshPostAuthState(for: .customer)
    }

    /// Submits the required-fields form shown after a first-time Google
    /// sign-in (see CompleteProfileView) — same PUT /users/profile endpoint
    /// the rest of the app already uses for profile edits.
    func completeProfile(
        displayName: String,
        surname: String,
        phone: String,
        nationalId: String,
        address: String,
        latitude: Double?,
        longitude: Double?,
        buildingInfo: String,
        apartmentNumber: String,
        deliveryInstructions: String
    ) async throws {
        guard let token = self.token else {
            throw NSError(domain: "AuthManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        let url = URL(string: "\(baseURL)/users/profile")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "displayName": displayName,
            "surname": surname,
            "phone": phone,
            "nationalId": nationalId,
            "address": address,
            "buildingInfo": buildingInfo,
            "apartmentNumber": apartmentNumber,
            "deliveryInstructions": deliveryInstructions,
        ]
        if let latitude { body["latitude"] = latitude }
        if let longitude { body["longitude"] = longitude }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw NSError(domain: "AuthManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to save your details"])
        }
        await refreshCurrentUser()
    }

    func logout() {
        // Clear all auth state
        isLoggedIn = false
        userRole = nil
        currentUser = nil
        token = nil  // This deletes from Keychain
        pendingGoogleSignupToken = nil
        pendingGoogleProfile = nil
        SocketService.shared.disconnect()
        GIDSignIn.sharedInstance.signOut()

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: roleKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.synchronize()
        CartManager.shared.clearLocalState()
        AppCache.shared.invalidateAll()

        print("🚪 [LOGOUT] User logged out successfully")
    }

    func refreshPostAuthState(for role: UserRole?) {
        Task {
            guard role == .customer else {
                await MainActor.run {
                    CartManager.shared.clearPendingTrackingOrder()
                    CartManager.shared.setActiveTrackingOrder(nil)
                }
                return
            }

            await CartManager.shared.refreshCart()
            await CartManager.shared.refreshActiveTrackingOrder()
        }
    }
}

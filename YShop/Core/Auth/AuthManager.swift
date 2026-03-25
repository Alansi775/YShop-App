import Foundation
import SwiftUI
import Combine

// MARK: - Enums
enum UserRole: String, Codable {
    case customer, driver
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
struct SimpleUser: Codable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let avatar: String?
    let role: String
    let isActive: Bool
    let isVerified: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, avatar
        case name = "display_name"
        case role = "userType"
        case isActive = "is_active"
        case isVerified = "is_verified"
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
        
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        email = try container.decode(String.self, forKey: .email)
        phone = try? container.decode(String.self, forKey: .phone)
        avatar = try? container.decode(String.self, forKey: .avatar)
        role = (try? container.decode(String.self, forKey: .role)) ?? "customer"
        isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
        isVerified = (try? container.decode(Bool.self, forKey: .isVerified)) ?? false
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
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

@MainActor
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn = false
    @Published var userRole: UserRole?
    @Published var currentUser: SimpleUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychainHelper = KeychainHelper.shared
    private let session: URLSession
    private let baseURL = "http://10.155.83.72:3000/api/v1"
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
                print("⚠️  [AUTH] No role in UserDefaults - clearing stale token")
                isLoggedIn = false
                userRole = nil
                currentUser = nil
            }
        } else {
            print("🚪 [AUTH] No token found - user not logged in")
            isLoggedIn = false
            userRole = nil
            currentUser = nil
        }
    }

    private func fetchCurrentUser() {
        guard let token = self.token else {
            print("❌ [AUTH] No token to fetch user")
            self.isLoggedIn = false
            return
        }
        
        let url = URL(string: "\(baseURL)/auth/me")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        Task {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                
                // Check for HTTP errors
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        print("❌ [AUTH] Token invalid (401) - logging out")
                        DispatchQueue.main.async {
                            self.isLoggedIn = false
                            self.currentUser = nil
                            UserDefaults.standard.removeObject(forKey: self.roleKey)
                        }
                        return
                    }
                }
                
                let responseData = try JSONDecoder().decode(UserResponse.self, from: data)
                DispatchQueue.main.async {
                    if let user = responseData.user {
                        self.currentUser = user
                        self.isLoggedIn = true
                        print("✅ [AUTH] User data fetched successfully: \(user.email)")
                    } else {
                        print("❌ [AUTH] User data not found in response")
                        self.isLoggedIn = false
                        self.currentUser = nil
                    }
                }
            } catch {
                print("❌ [AUTH] Failed to fetch current user: \(error)")
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.currentUser = nil
                    UserDefaults.standard.removeObject(forKey: self.roleKey)
                    print("⚠️  [AUTH] Session cleared due to fetch failure")
                }
            }
        }
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
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
            throw error
        }
    }

    func logout() {
        // Clear all auth state
        isLoggedIn = false
        userRole = nil
        currentUser = nil
        token = nil  // This deletes from Keychain
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: roleKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.synchronize()
        
        print("🚪 [LOGOUT] User logged out successfully")
    }
}

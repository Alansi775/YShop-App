//
//  AuthService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

class AuthService {
    static let shared = AuthService()
    private init() {}

    // MARK: - Login
    static func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        return try await APIClient.shared.request(.login, body: request)
    }

    // MARK: - Signup
    static func signup(
        displayName: String,
        email: String,
        password: String,
        phone: String,
        nationalId: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        buildingInfo: String? = nil,
        apartmentNumber: String? = nil,
        deliveryInstructions: String? = nil
    ) async throws -> SignupResponse {
        let request = SignupRequest(
            email: email,
            password: password,
            display_name: displayName,
            phone: phone,
            national_id: nationalId,
            address: address,
            latitude: latitude,
            longitude: longitude,
            building_info: buildingInfo,
            apartment_number: apartmentNumber,
            delivery_instructions: deliveryInstructions
        )
        return try await APIClient.shared.request(.signup, body: request)
    }

    // MARK: - Delivery Signup
    static func deliverySignup(
        name: String,
        email: String,
        password: String,
        phone: String,
        nationalId: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        buildingInfo: String? = nil,
        apartmentNumber: String? = nil,
        deliveryInstructions: String? = nil
    ) async throws -> DeliverySignupResponse {
        let request = DeliverySignupRequest(
            email: email,
            password: password,
            name: name,
            phone: phone,
            national_id: nationalId,
            address: address,
            latitude: latitude,
            longitude: longitude,
            building_info: buildingInfo,
            apartment_number: apartmentNumber,
            delivery_instructions: deliveryInstructions
        )
        return try await APIClient.shared.request(.deliverySignup, body: request)
    }

    // MARK: - Delivery Login
    static func deliveryLogin(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        return try await APIClient.shared.request(.deliveryLogin, body: request)
    }

    // MARK: - Verify Email
    static func verifyEmail(code: String) async throws -> EmptyResponse {
        struct VerifyRequest: Encodable {
            let code: String
        }
        return try await APIClient.shared.request(.verifyEmail, body: VerifyRequest(code: code))
    }

    // MARK: - Get Current User
    static func getCurrentUser() async throws -> User {
        try await APIClient.shared.request(.me)
    }

    // MARK: - Change Password
    static func changePassword(oldPassword: String, newPassword: String) async throws -> EmptyResponse {
        let request = ChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword)
        return try await APIClient.shared.request(.changePassword, body: request)
    }

    // MARK: - Logout
    static func logout() async throws -> EmptyResponse {
        try await APIClient.shared.request(.logout)
    }
}

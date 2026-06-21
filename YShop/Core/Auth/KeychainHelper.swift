//
//  KeychainHelper.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = "com.yshopp.app"

    private init() {}

    // MARK: - Save
    func save(_ data: Data, for key: String) throws {
        // Delete with search-only attributes (no kSecValueData in delete query)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // kSecAttrAccessibleAfterFirstUnlock: readable in background after first boot-unlock
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.savingFailed
        }
    }

    // MARK: - Read
    func read(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }

        guard let data = result as? Data else {
            throw KeychainError.decodingFailed
        }

        return data
    }

    // MARK: - Delete
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.deletingFailed
        }
    }

    // MARK: - Convenience Methods for String
    func saveString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, for: key)
    }

    func readString(for key: String) throws -> String {
        let data = try read(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return string
    }
}

enum KeychainError: LocalizedError {
    case savingFailed
    case itemNotFound
    case decodingFailed
    case encodingFailed
    case deletingFailed

    var errorDescription: String? {
        switch self {
        case .savingFailed:
            return "Failed to save item to Keychain."
        case .itemNotFound:
            return "Item not found in Keychain."
        case .decodingFailed:
            return "Failed to decode Keychain item."
        case .encodingFailed:
            return "Failed to encode item for Keychain."
        case .deletingFailed:
            return "Failed to delete item from Keychain."
        }
    }
}

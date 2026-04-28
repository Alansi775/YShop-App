//
//  AppConstants.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

struct AppConstants {
    // MARK: - API Configuration
    private static let defaultAPIPrefix = "/api/v1"
    private static let defaultDeviceHost = "http://192.168.1.69:3000"
    private static let defaultBonjourHost = "http://mackbook.local:3000"

    /// Change backend host in ONE place:
    /// 1) `API_BASE_URL` env var (full url, highest priority), or
    /// 2) `API_BASE_HOST` env var / Info.plist value (host only), or
    /// 3) sensible defaults (simulator -> localhost, device -> LAN IP)
    static let baseURL: String = {
        return baseURLCandidates.first ?? "http://localhost:3000/api/v1"
    }()

    /// Ordered candidates; API client can failover between them.
    static let baseURLCandidates: [String] = {
        var urls: [String] = []

        func normalized(_ raw: String) -> String {
            raw.hasSuffix(defaultAPIPrefix) ? raw : "\(raw)\(defaultAPIPrefix)"
        }

        let envFullURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? ""
        if !envFullURL.isEmpty { urls.append(normalized(envFullURL)) }

        let envHost = ProcessInfo.processInfo.environment["API_BASE_HOST"] ?? ""
        let plistHost = (Bundle.main.object(forInfoDictionaryKey: "API_BASE_HOST") as? String) ?? ""
        let configHost = !envHost.isEmpty ? envHost : plistHost
        if !configHost.isEmpty { urls.append(normalized(configHost)) }

        #if targetEnvironment(simulator)
        urls.append("http://localhost:3000/api/v1")
        #else
        urls.append(normalized(defaultDeviceHost))
        urls.append(normalized(defaultBonjourHost))
        #endif

        // Keep order, remove duplicates
        var unique: [String] = []
        for url in urls where !unique.contains(url) {
            unique.append(url)
        }
        return unique
    }()

    static let apiVersion = "v1"

    // MARK: - App Info
    static let appName = "YShop"
    static let appVersion = "1.0.0"
    static let appBuild = "1"

    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60

    // MARK: - Pagination
    static let defaultPageSize = 20
    static let defaultPage = 1

    // MARK: - Storage Keys
    enum StorageKey {
        static let authToken = "authToken"
        static let userRole = "userRole"
        static let lastLocation = "lastLocation"
        static let appLanguage = "appLanguage"
    }

    // MARK: - Feature Flags
    static let enableLogging = true
    static let enableCrashReporting = false
    static let enableOfflineMode = true

    // MARK: - Constraints
    static let maxImageUploadSize: Int = 5 * 1024 * 1024 // 5MB
    static let maxFileUploadSize: Int = 10 * 1024 * 1024 // 10MB
    static let minPasswordLength = 8
}

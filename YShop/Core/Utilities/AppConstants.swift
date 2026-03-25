//
//  AppConstants.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

struct AppConstants {
    // MARK: - API Configuration
    static let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://10.155.83.72:3000/api/v1"
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

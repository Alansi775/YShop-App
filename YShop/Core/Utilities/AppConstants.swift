import Foundation

struct AppConstants {
    // MARK: - API Configuration
    private static let defaultAPIPrefix = "/api/v1"
    // Fallback IP — updated by start.sh on each server launch
    private static let defaultDeviceHost = "http://Mohammeds-Mackbook-MacBook-Air.local:3000"

    static let baseURL: String = {
        baseURLCandidates.first ?? "http://localhost:3000/api/v1"
    }()

    /// All candidates tried in order. On device we also try the last cached working URL first.
    static let baseURLCandidates: [String] = {
        var urls: [String] = []

        func normalized(_ raw: String) -> String {
            raw.hasSuffix(defaultAPIPrefix) ? raw : "\(raw)\(defaultAPIPrefix)"
        }

        // 1. Env override (CI / Xcode scheme)
        let envFullURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? ""
        if !envFullURL.isEmpty { urls.append(normalized(envFullURL)) }

        // 2. Info.plist host
        let plistHost = (Bundle.main.object(forInfoDictionaryKey: "API_BASE_HOST") as? String) ?? ""
        if !plistHost.isEmpty { urls.append(normalized(plistHost)) }

        #if targetEnvironment(simulator)
        urls.append("http://localhost:3000/api/v1")
        #else
        // 3. Last cached working URL — skip raw IP addresses (they change per network).
        //    Only hostname-based URLs (.local, localhost) stay valid across WiFi changes.
        if let cached = UserDefaults.standard.string(forKey: "lastWorkingAPIURL"), !cached.isEmpty {
            let isRawIP = cached.range(of: #"https?://\d+\.\d+\.\d+\.\d+"#, options: .regularExpression) != nil
            if !isRawIP {
                urls.insert(normalized(cached), at: 0)
            }
        }
        // 4. Fallback hostname from build
        urls.append(normalized(defaultDeviceHost))
        #endif

        var unique: [String] = []
        for url in urls where !unique.contains(url) { unique.append(url) }
        return unique
    }()

    /// Media/uploads host (strips /api/v1). Uses cached URL if available.
    static var mediaBaseURL: String {
        let cached = UserDefaults.standard.string(forKey: "lastWorkingAPIURL") ?? ""
        let apiURL = cached.isEmpty ? (baseURLCandidates.first ?? "http://localhost:3000/api/v1") : cached
        if let range = apiURL.range(of: "/api/v1") {
            return String(apiURL[..<range.lowerBound])
        }
        return apiURL
    }

    static let apiVersion = "v1"

    // MARK: - App Info
    static let appName = "YShop"
    static let appVersion = "1.0.0"
    static let appBuild = "1"

    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 5   // short — so failover is fast
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
        static let lastWorkingAPIURL = "lastWorkingAPIURL"
    }

    // MARK: - Feature Flags
    static let enableLogging = true
    static let enableCrashReporting = false
    static let enableOfflineMode = true

    // MARK: - Constraints
    static let maxImageUploadSize: Int = 5 * 1024 * 1024
    static let maxFileUploadSize: Int = 10 * 1024 * 1024
    static let minPasswordLength = 8
}

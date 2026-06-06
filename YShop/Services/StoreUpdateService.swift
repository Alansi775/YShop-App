import Foundation
import UIKit

// MARK: - Store Update Models
struct StoreUpdate: Codable, Equatable {
    let id: Int
    let name: String
    let status: String
    let updated_at: String
    let store_type: String
}

struct UpdateResponse: Codable {
    let success: Bool
    let data: [StoreUpdate]
    let timestamp: String
}

// MARK: - Real-time Store Update Service
class StoreUpdateService: ObservableObject {
    @Published var storeUpdates: [StoreUpdate] = []
    @Published var isPolling: Bool = false
    
    private var pollingTimer: Timer?
    private let updateInterval: TimeInterval = 60 // ⚡ Check every 60 seconds (was 10) - reduced polling frequency
    private var lastCheckedTime: Date = Date()
    
    // MARK: - Start/Stop Polling
    func startPolling(forType type: String) {
        // Silent polling to reduce log noise
        isPolling = true
        lastCheckedTime = Date().addingTimeInterval(-60) // Start with 1 minute ago
        
        // Check immediately
        Task {
            await checkForUpdates(type: type)
        }
        
        // Then check every 30 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForUpdates(type: type)
            }
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
    }
    
    // MARK: - Check for Updates
    @MainActor
    private func checkForUpdates(type: String) async {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso8601String = iso8601Formatter.string(from: lastCheckedTime)
        // Silent update check
        
        var lastError: Error?
        
        // Try each candidate URL with fallover
        for baseURL in AppConstants.baseURLCandidates {
            do {
                let urlString = "\(baseURL)/stores/updates-since/\(iso8601String)?type=\(type)"
                
                guard let url = URL(string: urlString) else {
                    throw NSError(domain: "Invalid URL", code: -1)
                }
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 4
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode)
                }
                
                let decoder = JSONDecoder()
                let updateResponse = try decoder.decode(UpdateResponse.self, from: data)
                
                if !updateResponse.data.isEmpty {
                    self.storeUpdates = updateResponse.data
                }
                
                // Update timestamp for next check
                lastCheckedTime = Date()
                return // Success, exit retry loop
            } catch {
                lastError = error
                continue
            }
        }
    }
}


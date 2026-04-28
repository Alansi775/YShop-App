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
    private let updateInterval: TimeInterval = 30 // Check every 30 seconds
    private var lastCheckedTime: Date = Date()
    private let baseURL = AppConstants.baseURL
    
    // MARK: - Start/Stop Polling
    func startPolling(forType type: String) {
        print("🔄 [POLLING] Starting smart polling for type: \(type)")
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
        print("⏹ [POLLING] Stopping polling")
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
        
        let urlString = "\(baseURL)/stores/updates-since/\(iso8601String)?type=\(type)"
        
        print("🔍 [POLLING] Checking for updates since: \(iso8601String)")
        print("📍 [POLLING] URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [POLLING] Invalid URL")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [POLLING] Invalid response")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [POLLING] HTTP \(httpResponse.statusCode)")
                return
            }
            
            let decoder = JSONDecoder()
            let updateResponse = try decoder.decode(UpdateResponse.self, from: data)
            
            if !updateResponse.data.isEmpty {
                print("✅ [POLLING] Found \(updateResponse.data.count) updated stores!")
                self.storeUpdates = updateResponse.data
                
                // Log each update
                for update in updateResponse.data {
                    print("   📱 Store: \(update.name) - Status: \(update.status)")
                }
            } else {
                print("✓ [POLLING] No updates")
            }
            
            // Update timestamp for next check
            if let newTime = ISO8601DateFormatter().date(from: updateResponse.timestamp) {
                self.lastCheckedTime = newTime
            }
            
        } catch {
            print("❌ [POLLING] Error: \(error.localizedDescription)")
        }
    }
}

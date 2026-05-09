//
//  StoreService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation
import UIKit

class StoreService {
    static let shared = StoreService()
    private init() {}

    // MARK: - Get Stores
    static func getStores(page: Int = 1) async throws -> [Store] {
        try await APIClient.shared.request(.stores)
    }

    // MARK: - Get Public Stores
    static func getPublicStores(latitude: Double?, longitude: Double?) async throws -> [Store] {
        try await APIClient.shared.request(.publicStores)
    }

    // MARK: - Get Public Stores by Type/Category
    static func getPublicStoresByType(_ type: String) async throws -> [Store] {
        // Capitalize first letter to match database values (Food, Pharmacy, Clothes, Market)
        let capitalizedType = type.prefix(1).uppercased() + type.dropFirst()
        let typeEncoded = capitalizedType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var lastError: Error?
        
        // Try each candidate URL with fallover
        for baseURL in AppConstants.baseURLCandidates {
            do {
                let urlString = "\(baseURL)/stores/public?type=\(typeEncoded)"
                
                print("📍 [API] Requesting stores with URL: \(urlString)")
                
                guard let url = URL(string: urlString) else {
                    throw NSError(domain: "Invalid URL", code: -1)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 10
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "HTTP Error", code: -1)
                }
                
                struct StoresResponse: Decodable {
                    let data: [Store]
                }
                
                let decoder = JSONDecoder()
                let storesResponse = try decoder.decode(StoresResponse.self, from: data)
                print("✅ [API] Response returned \(storesResponse.data.count) stores")
                return storesResponse.data
            } catch {
                lastError = error
                print("🔁 [API] Failed with \(baseURL), trying next...")
                continue
            }
        }
        
        // If all failed, throw the last error
        throw lastError ?? NSError(domain: "All endpoints failed", code: -1)
    }

    // MARK: - Get Store Detail
    static func getStoreDetail(id: String) async throws -> Store {
        try await APIClient.shared.request(.storeDetail(id))
    }

    // MARK: - Get Store Categories
    static func getStoreCategories(storeId: String) async throws -> [Category] {
        try await APIClient.shared.request(.storeCategories(storeId))
    }
    
    // MARK: - Get Store Products
    static func getStoreProducts(storeId: Int) async throws -> [Product] {
        let response: APIResponse<[Product]> = try await APIClient.shared.request(.storeProducts(storeId))
        return response.data
    }
}

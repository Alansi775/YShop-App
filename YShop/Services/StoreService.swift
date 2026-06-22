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

    // MARK: - Get Public Stores by Type/Category (cache-first)
    static func getPublicStoresByType(_ type: String) async throws -> [Store] {
        let cacheKey = AppCache.Key.stores(category: type)

        // Return fresh cache immediately — no network call needed
        if let hit: CacheResult<[Store]> = AppCache.shared.get(cacheKey), !hit.isStale {
            return hit.value
        }

        // Capitalize first letter to match database values (Food, Pharmacy, Clothes, Market)
        let capitalizedType = type.prefix(1).uppercased() + type.dropFirst()
        let typeEncoded = capitalizedType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        var lastError: Error?

        for baseURL in AppConstants.baseURLCandidates {
            do {
                let urlString = "\(baseURL)/stores/public?type=\(typeEncoded)"
                guard let url = URL(string: urlString) else { throw NSError(domain: "Invalid URL", code: -1) }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 4

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw NSError(domain: "HTTP Error", code: -1)
                }

                struct StoresResponse: Decodable { let data: [Store] }
                let stores = try JSONDecoder().decode(StoresResponse.self, from: data).data
                AppCache.shared.set(cacheKey, value: stores)
                return stores
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError ?? NSError(domain: "All endpoints failed", code: -1)
    }

    // MARK: - Get Store Detail (cache-first)
    static func getStoreDetail(id: String) async throws -> Store {
        let cacheKey = AppCache.Key.storeDetail(id: id)
        if let hit: CacheResult<Store> = AppCache.shared.get(cacheKey), !hit.isStale {
            return hit.value
        }
        let store: Store
        do {
            let response: APIResponse<Store> = try await APIClient.shared.request(.storeDetail(id))
            store = response.data
        } catch {
            store = try await APIClient.shared.request(.storeDetail(id))
        }
        AppCache.shared.set(cacheKey, value: store)
        return store
    }

    // MARK: - Get Store Categories (cache-first)
    static func getStoreCategories(storeId: String) async throws -> [Category] {
        let cacheKey = AppCache.Key.categories(storeId: storeId)
        if let hit: CacheResult<[Category]> = AppCache.shared.get(cacheKey), !hit.isStale {
            return hit.value
        }
        let cats: [Category] = try await APIClient.shared.request(.storeCategories(storeId))
        AppCache.shared.set(cacheKey, value: cats)
        return cats
    }

    // MARK: - Get Store Products (cache-first)
    static func getStoreProducts(storeId: Int) async throws -> [Product] {
        let cacheKey = AppCache.Key.products(storeId: storeId)
        if let hit: CacheResult<[Product]> = AppCache.shared.get(cacheKey), !hit.isStale {
            return hit.value
        }
        let response: APIResponse<[Product]> = try await APIClient.shared.request(.storeProducts(storeId))
        AppCache.shared.set(cacheKey, value: response.data)
        return response.data
    }
}

//
//  ProductService.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

class ProductService {
    static let shared = ProductService()
    private init() {}

    // MARK: - Get Products
    static func getProducts(page: Int = 1, pageSize: Int = 20) async throws -> [Product] {
        struct Query: Encodable {
            let page: Int
            let pageSize: Int

            enum CodingKeys: String, CodingKey {
                case page
                case pageSize = "page_size"
            }
        }

        // Note: This would need pagination support in APIClient
        return try await APIClient.shared.request(.products)
    }

    // MARK: - Get Product Detail
    static func getProductDetail(id: String) async throws -> Product {
        try await APIClient.shared.request(.productDetail(id))
    }

    // MARK: - Create Product
    static func createProduct(
        name: String,
        description: String?,
        price: Double,
        categoryId: String,
        images: [Data],
        quantity: Int?
    ) async throws -> Product {
        struct CreateRequest: Encodable {
            let name: String
            let description: String?
            let price: Double
            let categoryId: String
            let quantity: Int?

            enum CodingKeys: String, CodingKey {
                case name, description, price, quantity
                case categoryId = "category_id"
            }
        }

        let request = CreateRequest(name: name, description: description, price: price, categoryId: categoryId, quantity: quantity)
        return try await APIClient.shared.request(.createProduct, body: request)
    }

    // MARK: - Update Product
    static func updateProduct(
        id: String,
        name: String?,
        description: String?,
        price: Double?,
        quantity: Int?
    ) async throws -> Product {
        struct UpdateRequest: Encodable {
            let name: String?
            let description: String?
            let price: Double?
            let quantity: Int?
        }

        let request = UpdateRequest(name: name, description: description, price: price, quantity: quantity)
        return try await APIClient.shared.request(.updateProduct(id), body: request)
    }

    // MARK: - Delete Product
    static func deleteProduct(id: String) async throws -> EmptyResponse {
        try await APIClient.shared.request(.deleteProduct(id))
    }
}

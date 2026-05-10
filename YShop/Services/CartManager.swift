import Foundation
import SwiftUI

@MainActor
final class CartManager: ObservableObject {
    static let shared = CartManager()

    @Published private(set) var cartItems: [CartItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private init() {}

    var itemCount: Int {
        cartItems.count
    }

    var totalPrice: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    func refreshCart() async {
        isLoading = true
        errorMessage = nil

        do {
            let items = try await CartService.getCart()
            cartItems = items
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addToCart(product: Product, quantity: Int) async throws {
        let previousItems = cartItems

        let optimisticItem = CartItem(
            id: "local_\(product.id)_\(UUID().uuidString)",
            userId: "",
            productId: String(product.id),
            storeId: String(product.store_id),
            quantity: quantity,
            price: product.priceDouble,
            product: product,
            name: product.name,
            imageUrl: product.image_url,
            currency: product.currency,
            stock: product.stock,
            status: product.status
        )

        cartItems.append(optimisticItem)

        do {
            _ = try await CartService.addToCart(
                productId: String(product.id),
                quantity: quantity
            )
            await refreshCart()
        } catch {
            cartItems = previousItems
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updateQuantity(cartItemId: String, quantity: Int) async throws {
        let updatedItem = try await CartService.updateCartItem(itemId: cartItemId, quantity: quantity)
        if let index = cartItems.firstIndex(where: { $0.id == cartItemId }) {
            cartItems[index] = updatedItem
        } else {
            await refreshCart()
        }
    }

    func removeItem(_ itemId: String) async throws {
        try await CartService.removeCartItem(itemId: itemId)
        if let index = cartItems.firstIndex(where: { $0.id == itemId }) {
            cartItems.remove(at: index)
        } else {
            await refreshCart()
        }
    }

    func clearLocalState() {
        cartItems = []
        isLoading = false
        errorMessage = nil
    }
}
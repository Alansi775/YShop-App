import Foundation
import SwiftUI

@MainActor
final class CartManager: ObservableObject {
    static let shared = CartManager()

    private let lastOrderIdKey = "lastOrderId"

    @Published private(set) var cartItems: [CartItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastOrderId: String?
    @Published private(set) var pendingTrackingOrderId: String?
    @Published private(set) var activeTrackingOrder: Order?

    private init() {
        lastOrderId = UserDefaults.standard.string(forKey: lastOrderIdKey)
    }

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

    func clearCart() async {
        do {
            try await CartService.clearCart()
        } catch {
            errorMessage = error.localizedDescription
        }

        cartItems = []
    }

    func setLastOrderId(_ orderId: String?) {
        lastOrderId = orderId

        if let orderId {
            UserDefaults.standard.set(orderId, forKey: lastOrderIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastOrderIdKey)
        }
    }

    func setActiveTrackingOrder(_ order: Order?) {
        activeTrackingOrder = order?.status.isTrackable == true ? order : nil
    }

    func refreshActiveTrackingOrder() async {
        do {
            if let orderId = lastOrderId, !orderId.isEmpty {
                let order = try await OrderService.getOrderDetail(id: orderId)
                if order.status.isTrackable {
                    setActiveTrackingOrder(order)
                    return
                }

                setActiveTrackingOrder(nil)
                setLastOrderId(nil)
                return
            }

            let orders = try await OrderService.getUserOrders()
            if let latestOrder = orders
                .filter({ $0.status.isTrackable })
                .max(by: Self.orderPriorityComparator) {
                setActiveTrackingOrder(latestOrder)
                setLastOrderId(latestOrder.id)
            } else {
                setActiveTrackingOrder(nil)
                setLastOrderId(nil)
            }
        } catch {
            let orders = (try? await OrderService.getUserOrders()) ?? []
            if let latestOrder = orders
                .filter({ $0.status.isTrackable })
                .max(by: Self.orderPriorityComparator) {
                setActiveTrackingOrder(latestOrder)
                setLastOrderId(latestOrder.id)
            } else {
                setActiveTrackingOrder(nil)
                setLastOrderId(nil)
            }

            errorMessage = error.localizedDescription
        }
    }

    private static func orderPriorityComparator(_ lhs: Order, _ rhs: Order) -> Bool {
        let lhsId = Int(lhs.id) ?? 0
        let rhsId = Int(rhs.id) ?? 0
        if lhsId != rhsId {
            return lhsId < rhsId
        }

        return (lhs.updatedAt ?? lhs.createdAt ?? "") < (rhs.updatedAt ?? rhs.createdAt ?? "")
    }

    func presentTrackingOrder(id: String) {
        pendingTrackingOrderId = id
    }

    func clearPendingTrackingOrder() {
        pendingTrackingOrderId = nil
    }

    func clearLocalState() {
        cartItems = []
        isLoading = false
        errorMessage = nil
        setLastOrderId(nil)
        clearPendingTrackingOrder()
        setActiveTrackingOrder(nil)
    }
}
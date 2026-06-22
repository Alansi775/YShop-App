import Foundation
import SwiftUI
import UserNotifications

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

    private var orderUpdateObserver: NSObjectProtocol?

    private init() {
        lastOrderId = UserDefaults.standard.string(forKey: lastOrderIdKey)
        startListeningForOrderUpdates()
    }

    // Automatically refresh the active order and Live Activity whenever the
    // server pushes an order_updated socket event — no manual tap required.
    private func startListeningForOrderUpdates() {
        orderUpdateObserver = NotificationCenter.default.addObserver(
            forName: .yshopOrderUpdated,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let incomingId = notification.object as? String
                await self.handleSocketOrderUpdate(incomingId)
            }
        }
    }

    private func handleSocketOrderUpdate(_ incomingId: String?) async {
        // Capture previous status before refresh so we can detect changes
        let previousStatus = activeTrackingOrder?.status

        AppCache.shared.invalidate(.userOrders)
        if let id = incomingId { AppCache.shared.invalidate(.activeOrder(id: id)) }

        await refreshActiveTrackingOrder()

        guard let order = activeTrackingOrder else { return }

        // Update Live Activity without waiting for APNs
        LiveActivityManager.shared.update(with: order)

        // Schedule a local notification if status changed
        // This fires even when OrderTrackingView is closed
        if order.status != previousStatus {
            scheduleOrderStatusNotification(order: order, newStatus: order.status)
        }
    }

    // Local notification so the customer knows the order changed
    // without needing to open the tracking view or Live Activity
    private func scheduleOrderStatusNotification(order: Order, newStatus: OrderStatus) {
        let store = order.storeName ?? "Your store"
        var title: String?
        var body: String?

        switch newStatus {
        case .confirmed:
            title = "✅ Order Confirmed"
            body  = "\(store) confirmed your order and started preparing it."
        case .shipped, .outForDelivery:
            title = "🛵 Driver is on the way!"
            body  = "Your order from \(store) has been picked up."
        case .delivered:
            title = "🎉 Order Delivered!"
            body  = "Your order from \(store) has arrived. Enjoy!"
        case .cancelled:
            title = "❌ Order Cancelled"
            body  = "Your order from \(store) was cancelled."
        case .failed:
            title = "⚠️ Order Failed"
            body  = "There was a problem with your order from \(store)."
        default:
            return
        }

        guard let title, let body else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "order-\(order.id)-\(newStatus.rawValue)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
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
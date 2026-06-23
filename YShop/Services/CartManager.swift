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
    private var pollingTask: Task<Void, Never>?

    private init() {
        lastOrderId = UserDefaults.standard.string(forKey: lastOrderIdKey)
        startListeningForOrderUpdates()
        startListeningForSocketReconnect()
        startPollingFallback()
        restoreLiveActivityOnLaunch()
    }

    // On app launch, if we have a known active order, sync the Live Activity immediately.
    // This ensures the Live Activity reflects the real status even if it was changed while
    // the app was terminated — without waiting for the user to open the tracking screen.
    private func restoreLiveActivityOnLaunch() {
        guard lastOrderId != nil else { return }
        Task {
            await refreshActiveTrackingOrder()
            if let order = activeTrackingOrder {
                LiveActivityManager.shared.start(for: order)
                print("[CartManager] 🚀 Restored Live Activity on launch — order=\(order.id) status=\(order.status.rawValue)")
            }
        }
    }

    // Polls the active order every 15s as fallback when socket events are missed.
    // This ensures the tracking icon and Live Activity always reflect the real status,
    // even on unstable networks where socket events are dropped.
    private func startPollingFallback() {
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
                guard !Task.isCancelled else { break }
                await MainActor.run { [weak self] in
                    guard let self, self.lastOrderId != nil || self.activeTrackingOrder != nil else { return }
                    Task {
                        let previousStatus = self.activeTrackingOrder?.status
                        await self.refreshActiveTrackingOrder()
                        guard let order = self.activeTrackingOrder else { return }
                        LiveActivityManager.shared.update(with: order)
                        if order.status != previousStatus {
                            print("[CartManager] 📊 Poll detected status change: \(previousStatus?.rawValue ?? "nil") → \(order.status.rawValue)")
                            self.scheduleOrderStatusNotification(order: order, newStatus: order.status)
                        }
                    }
                }
            }
        }
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

    // When socket reconnects after a brief disconnect, refresh the active order so any
    // status change that arrived while we were offline is reflected immediately.
    private func startListeningForSocketReconnect() {
        NotificationCenter.default.addObserver(
            forName: .yshopSocketReconnected,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.lastOrderId != nil || self.activeTrackingOrder != nil else { return }
                await self.refreshActiveTrackingOrder()
                if let order = self.activeTrackingOrder {
                    LiveActivityManager.shared.start(for: order)
                }
            }
        }
    }

    private func handleSocketOrderUpdate(_ incomingId: String?) async {
        let previousStatus = activeTrackingOrder?.status

        print("[CartManager] 📡 Socket order update — orderId=\(incomingId ?? "nil") previousStatus=\(previousStatus?.rawValue ?? "nil")")

        AppCache.shared.invalidate(.userOrders)
        if let id = incomingId { AppCache.shared.invalidate(.activeOrder(id: id)) }

        await refreshActiveTrackingOrder()

        guard let order = activeTrackingOrder else {
            print("[CartManager] ⚠️ No active order after refresh")
            return
        }

        print("[CartManager] ✅ Active order — id=\(order.id) status=\(order.status.rawValue)")

        // Update the Live Activity with the new order state
        LiveActivityManager.shared.update(with: order)

        // Schedule a local notification if status changed
        if order.status != previousStatus {
            print("[CartManager] 🔔 Status changed \(previousStatus?.rawValue ?? "nil") → \(order.status.rawValue)")
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
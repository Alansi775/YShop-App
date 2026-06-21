import AppIntents
import Foundation

struct TrackOrderIntent: AppIntent {
    static var title: LocalizedStringResource = "Track YShop Order"
    static var description = IntentDescription(
        "Check the status of your latest active YShop order."
    )
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let orders: [Order]
        do {
            orders = try await OrderService.getUserOrders()
        } catch {
            return .result(dialog: "Couldn't reach YShop right now. Please check the app.")
        }

        let terminalStatuses: Set<OrderStatus> = [.delivered, .cancelled, .failed]
        let active = orders.first { !terminalStatuses.contains($0.status) }
        let target = active ?? orders.first

        guard let order = target else {
            return .result(dialog: "You have no recent orders in YShop.")
        }

        await MainActor.run {
            CartManager.shared.presentTrackingOrder(id: order.id)
        }

        let store = order.storeName ?? "your store"
        let status = order.status.siriDescription
        let id = order.id

        return .result(
            dialog: active != nil
                ? "Your active order #\(id) from \(store) is \(status)."
                : "Your last order #\(id) from \(store) was \(status)."
        )
    }
}

import ActivityKit
import Foundation

/// Shared between the App target and YShopWidgets extension.
/// Add this file to BOTH targets in Xcode → Target Membership.
struct OrderLiveActivityAttributes: ActivityAttributes {
    public typealias OrderTrackingStatus = ContentState

    // MARK: - Dynamic (updated via socket)
    public struct ContentState: Codable, Hashable {
        var statusTitle: String
        var statusStep: Int      // 1=Placed 2=Confirmed 3=OutForDelivery 4=Delivered 0=Cancelled
        var driverName: String?
        var storeName: String
        var storeType: String    // "Food" | "Pharmacy" | "Clothes" | "Market"
        var isDelivered: Bool
        var isCancelled: Bool
    }

    // MARK: - Static (set once at creation)
    var orderNumber: String
    var totalPrice: String
}

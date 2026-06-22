import ActivityKit
import CoreLocation
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<OrderLiveActivityAttributes>?

    // MARK: - Start

    func start(for order: Order) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // If one already running for this order, just update it
        if let existing = Activity<OrderLiveActivityAttributes>.activities.first(where: {
            $0.attributes.orderNumber == "#\(order.id)"
        }) {
            activity = existing
            update(with: order)
            return
        }

        let attrs = OrderLiveActivityAttributes(
            orderNumber: "#\(order.id)",
            totalPrice: String(format: "%.0f TRY", order.totalPrice)
        )
        let state = contentState(from: order)

        // Try with APNs push token first (needed for remote updates when app is closed).
        // Falls back to nil pushType if Push Notifications capability is missing —
        // the Live Activity still shows and updates while the app is in the foreground.
        let newActivity: Activity<OrderLiveActivityAttributes>
        do {
            newActivity = try Activity<OrderLiveActivityAttributes>.request(
                attributes: attrs,
                content: ActivityContent(state: state, staleDate: .now + 3600),
                pushType: .token
            )
            observePushToken(for: newActivity, orderId: order.id)
            print("[LiveActivity] started with push token support ✓")
        } catch {
            print("[LiveActivity] push token not available (\(error.localizedDescription)) — starting without APNs")
            do {
                newActivity = try Activity<OrderLiveActivityAttributes>.request(
                    attributes: attrs,
                    content: ActivityContent(state: state, staleDate: .now + 3600),
                    pushType: nil
                )
                print("[LiveActivity] started without push token (socket-only updates)")
            } catch {
                print("[LiveActivity] start failed entirely: \(error.localizedDescription)")
                return
            }
        }
        activity = newActivity
    }

    // Observe the Live Activity push token and send it to the backend
    // so the backend can push updates directly without the app being open.
    private nonisolated func observePushToken(
        for activity: Activity<OrderLiveActivityAttributes>,
        orderId: String
    ) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                struct Body: Encodable { let pushToken: String }
                struct Empty: Decodable {}
                let _: Empty? = try? await APIClient.shared.request(
                    .saveLiveActivityToken(orderId),
                    body: Body(pushToken: token)
                )
            }
        }
    }

    // MARK: - Update

    func update(with order: Order) {
        guard let activity else { return }
        let state = contentState(from: order)
        Task {
            await activity.update(ActivityContent(state: state, staleDate: .now + 3600))
        }
    }

    // MARK: - End

    func end(with order: Order) {
        guard let activity else { return }
        let state = contentState(from: order)
        Task {
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: order.status == .delivered
                    ? .after(.now + 7200)   // keep 2h on Lock Screen after delivery
                    : .immediate
            )
            self.activity = nil
        }
    }

    // MARK: - Helpers

    private func contentState(from order: Order) -> OrderLiveActivityAttributes.ContentState {
        let (proximityFraction, distanceText) = Self.proximityInfo(from: order)
        return OrderLiveActivityAttributes.ContentState(
            statusTitle: order.status.liveActivityTitle,
            statusStep: order.status.stepNumber,
            driverName: order.driverName,
            storeName: order.storeName ?? "Store",
            storeType: order.storeType ?? "Food",
            isDelivered: order.status == .delivered,
            isCancelled: order.status == .cancelled || order.status == .failed,
            proximityFraction: proximityFraction,
            distanceText: distanceText
        )
    }

    // Calculate driver→customer proximity fraction and distance label.
    // Returns (1.0, nil) when delivered; (0.95 max, label) while en route.
    private static func proximityInfo(from order: Order) -> (Double, String?) {
        if order.status == .delivered { return (1.0, nil) }
        guard order.status == .outForDelivery || order.status == .shipped,
              let driverLocation = order.driverLocation,
              let customerLat = order.customerLatitude,
              let customerLon = order.customerLongitude
        else { return (0.0, nil) }

        let parts = driverLocation
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count >= 2 else { return (0.0, nil) }

        let driverCL   = CLLocation(latitude: parts[0], longitude: parts[1])
        let customerCL = CLLocation(latitude: customerLat, longitude: customerLon)
        let meters     = driverCL.distance(from: customerCL)

        let label = meters < 1000
            ? "\(Int(meters)) m away"
            : String(format: "%.1f km away", meters / 1000)

        // 3 km = 0 %, 0 m = 95 % (100 % reserved for delivered state)
        let fraction = max(0, min(0.95, 1.0 - meters / 3000.0))
        return (fraction, label)
    }
}

// MARK: - OrderStatus extensions

extension OrderStatus {
    var liveActivityTitle: String {
        switch self {
        case .pending:               return "Order Placed"
        case .confirmed:             return "Confirmed by Restaurant"
        case .processing:            return "Being Prepared"
        case .shipped, .outForDelivery: return "Out for Delivery"
        case .delivered:             return "Delivered!"
        case .cancelled:             return "Order Cancelled"
        case .failed:                return "Order Failed"
        case .returnRequested:       return "Return Requested"
        }
    }

    var stepNumber: Int {
        switch self {
        case .pending:                  return 1
        case .confirmed, .processing:   return 2
        case .shipped, .outForDelivery: return 3
        case .delivered:                return 4
        default:                        return 0
        }
    }

    var siriDescription: String {
        switch self {
        case .pending:               return "placed and waiting for restaurant confirmation"
        case .confirmed, .processing: return "confirmed and being prepared"
        case .shipped, .outForDelivery: return "out for delivery"
        case .delivered:             return "delivered"
        case .cancelled:             return "cancelled"
        case .failed:                return "failed"
        case .returnRequested:       return "under return processing"
        }
    }
}

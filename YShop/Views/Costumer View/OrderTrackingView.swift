import SwiftUI
import MapKit

struct OrderTrackingView: View {
    let orderId: String

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss

    @State private var order: Order?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var lastRefreshedAt: Date?
    @State private var socketObserverId: UUID?
    @State private var store: Store?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedProduct: Product?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let order {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header(order)
                        statusTimeline(order.status)
                        liveUpdateCard(order)
                        itemsCard(order)
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            } else if let errorMessage {
                errorState(errorMessage)
            }
        }
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NativeCircleIconButton(
                    systemName: "chevron.left",
                    action: { dismiss() },
                    iconColor: .primary,
                    size: 35.5,
                    iconSize: 14,
                    showBackground: true
                )
            }
        }
        .task(id: orderId) {
            await startTrackingSession()
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product, store: storeForProductDetails())
                .environmentObject(cartManager)
        }
        .onDisappear {
            stopTrackingSession()
        }
    }

    private func loadOrder() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedOrder = try await OrderService.getOrderDetail(id: orderId)
            order = loadedOrder
            lastRefreshedAt = Date()
            cartManager.setActiveTrackingOrder(loadedOrder)
            await loadStoreDetails(storeId: loadedOrder.storeId)
        } catch {
            errorMessage = error.localizedDescription
            order = nil
        }

        isLoading = false
    }

    private func refreshOrder() async {
        do {
            let loadedOrder = try await OrderService.getOrderDetail(id: orderId)

            if order?.status != loadedOrder.status || order?.updatedAt != loadedOrder.updatedAt {
                withAnimation(.easeInOut(duration: 0.25)) {
                    order = loadedOrder
                }
            } else {
                order = loadedOrder
            }

            lastRefreshedAt = Date()
            errorMessage = nil
            cartManager.setActiveTrackingOrder(loadedOrder)
            await loadStoreDetails(storeId: loadedOrder.storeId)

            if loadedOrder.status.isTerminal {
                stopTrackingSession()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startTrackingSession() async {
        stopTrackingSession()
        await loadOrder()

        if let token = authManager.token {
            SocketService.shared.connectIfNeeded(token: token)
        }

        socketObserverId = SocketService.shared.observeOrder(orderId: orderId) { [orderId] in
            Task {
                await refreshOrderFromSocket(orderId: orderId)
            }
        }
    }

    private func loadStoreDetails(storeId: String) async {
        guard store?.id != Int(storeId) else {
            updateMapPosition()
            return
        }

        do {
            store = try await StoreService.getStoreDetail(id: storeId)
            updateMapPosition()
        } catch {
            store = nil
            updateMapPosition()
        }
    }

    private func refreshOrderFromSocket(orderId: String) async {
        guard orderId == self.orderId else { return }

        await refreshOrder()

        if order?.status.isTerminal == true {
            stopTrackingSession()
        }
    }

    private func stopTrackingSession() {
        if let socketObserverId {
            SocketService.shared.removeObserver(orderId: orderId, observerId: socketObserverId)
            self.socketObserverId = nil
        }
    }

    private func header(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    storeIconView

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order #\(order.id)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(.label))

                        Text(store?.name ?? order.storeName ?? "Store")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                }

                Spacer()

                Text(order.status.displayTitle.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(order.status.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(order.status.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(order.shippingAddress ?? order.deliveryAddress ?? "No delivery address")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(3)

            if lastRefreshedAt != nil {
                Text("Updated just now")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func liveUpdateCard(_ order: Order) -> some View {
        let liveMessage: String

        switch order.status {
        case .pending:
            liveMessage = "Your order is waiting for the store to confirm it."
        case .confirmed:
            liveMessage = "The store accepted your order and is getting it ready."
        case .processing:
            liveMessage = "Your items are being prepared now."
        case .shipped, .outForDelivery:
            liveMessage = "Your order is out for delivery."
        case .delivered:
            liveMessage = "Your order has been delivered."
        case .cancelled:
            liveMessage = "This order was cancelled."
        case .failed:
            liveMessage = "This order could not be completed."
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Update")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.label))
                Spacer()
                Text(order.status.displayTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(order.status.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(order.status.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(liveMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                infoChip(title: "Customer", value: order.customerName ?? "You")
                infoChip(title: "Driver", value: order.driverId ?? "Not assigned")
            }

            HStack(spacing: 10) {
                infoChip(title: "Store", value: order.storeName ?? order.storeId)
                infoChip(title: "Created", value: order.createdAt ?? "Just now")
            }

            if shouldShowDriverMap(order) {
                driverMapSection(order)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var storeIconView: some View {
        Group {
            if let iconUrl = store?.fullIconUrl, let url = URL(string: iconUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    default:
                        placeholderStoreIcon
                    }
                }
            } else {
                placeholderStoreIcon
            }
        }
    }

    private var placeholderStoreIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)

            Image(systemName: "storefront.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }

    private func shouldShowDriverMap(_ order: Order) -> Bool {
        guard order.pickedUpAt != nil || order.status == .outForDelivery else { return false }
        return customerCoordinate(for: order) != nil && storeCoordinate(for: order) != nil
    }

    private func driverMapSection(_ order: Order) -> some View {
        let storeCoordinate = storeCoordinate(for: order)
        let customerCoordinate = customerCoordinate(for: order)
        let driverCoordinate = coordinate(from: order.driverLocation)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Live Driver")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(.label))

                    Text(driverCoordinate == nil ? "Waiting for the courier to share live location" : "Courier is live on the map")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                Text(order.status.displayTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(order.status.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(order.status.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Map(position: $mapPosition) {
                if let storeCoordinate {
                    Annotation("Store", coordinate: storeCoordinate) {
                        mapPin(label: "S", color: .black)
                    }
                }

                if let driverCoordinate {
                    Annotation("Courier", coordinate: driverCoordinate) {
                        mapPin(label: "D", color: .blue)
                    }
                }

                if let customerCoordinate {
                    Annotation("You", coordinate: customerCoordinate) {
                        mapPin(label: "Y", color: .green)
                    }
                }

                if let route = mapRouteCoordinates(storeCoordinate: storeCoordinate, driverCoordinate: driverCoordinate, customerCoordinate: customerCoordinate) {
                    MapPolyline(MKPolyline(coordinates: route, count: route.count))
                        .stroke(.blue.opacity(0.85), lineWidth: 4)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
            )

            Text(driverCoordinate == nil ? "The map appears after the courier picks up the order and shares location." : "Route updates live while the courier is on the way.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(14)
        .background(Color(.secondarySystemBackground).opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.label))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statusTimeline(_ status: OrderStatus) -> some View {
        let steps: [(String, String, OrderStatus?)] = [
            ("Placed", "bag.fill", .pending),
            ("Confirmed", "checkmark.seal.fill", .confirmed),
            ("Processing", "gearshape.fill", .processing),
            ("Out for delivery", "car.fill", .outForDelivery),
            ("Delivered", "checkmark.circle.fill", .delivered)
        ]

        return VStack(alignment: .leading, spacing: 14) {
            Text("Tracking")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(.label))

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                let isDone = status.progressIndex >= index
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isDone ? step.2?.accentColor ?? .green : Color(.tertiarySystemBackground))
                            .frame(width: 30, height: 30)

                        Image(systemName: step.1)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isDone ? .white : Color(.secondaryLabel))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.0)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.label))
                        Text(isDone ? "Completed" : "Waiting")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    Spacer()
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(Color(.separator).opacity(0.35))
                        .frame(width: 2, height: 18)
                        .padding(.leading, 14)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func itemsCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(.label))

            ForEach(order.items) { item in
                Button {
                    if let product = productForTrackingItem(item: item, order: order) {
                        selectedProduct = product
                    }
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: item.fullImageUrl ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Color(.secondarySystemBackground)
                                    .overlay(Image(systemName: "photo").foregroundColor(Color(.tertiaryLabel)))
                            }
                        }
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(2)

                            Text("\(item.currencySymbol)\(String(format: "%.2f", item.price)) x \(item.quantity)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))

                            Text("Line total: \(item.currencySymbol)\(String(format: "%.2f", item.price * Double(item.quantity)))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(item.formattedPrice)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.top, 4)

            HStack {
                Text("Order total")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))

                Spacer()

                Text(orderTotalText(order))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func orderTotalText(_ order: Order) -> String {
        let symbol = order.items.first?.currencySymbol ?? "₺"
        return "\(symbol)\(String(format: "%.2f", order.totalPrice))"
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.label))
                .lineLimit(1)
        }
    }

    private func mapPin(label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(color)
                .clipShape(Circle())

            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 10, height: 10)
        }
    }

    private func mapRouteCoordinates(
        storeCoordinate: CLLocationCoordinate2D?,
        driverCoordinate: CLLocationCoordinate2D?,
        customerCoordinate: CLLocationCoordinate2D?
    ) -> [CLLocationCoordinate2D]? {
        var coordinates = [CLLocationCoordinate2D]()

        if let driverCoordinate {
            coordinates.append(driverCoordinate)
        } else if let storeCoordinate {
            coordinates.append(storeCoordinate)
        }

        if let customerCoordinate {
            coordinates.append(customerCoordinate)
        }

        return coordinates.count > 1 ? coordinates : nil
    }

    private func storeCoordinate(for order: Order) -> CLLocationCoordinate2D? {
        if let storeLatitude = order.storeLatitude, let storeLongitude = order.storeLongitude {
            return CLLocationCoordinate2D(latitude: storeLatitude, longitude: storeLongitude)
        }

        if let store, let latitude = store.latitude, let longitude = store.longitude {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        return nil
    }

    private func customerCoordinate(for order: Order) -> CLLocationCoordinate2D? {
        guard let latitude = order.customerLatitude, let longitude = order.customerLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func coordinate(from rawValue: String?) -> CLLocationCoordinate2D? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else { return nil }

        if let data = rawValue.data(using: .utf8) {
            if let payload = try? JSONDecoder().decode(CoordinatePayload.self, from: data) {
                return payload.coordinate
            }
        }

        let cleaned = rawValue
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        let parts = cleaned.split { $0 == "," || $0 == " " }
            .map(String.init)
            .filter { !$0.isEmpty }

        guard parts.count >= 2, let latitude = Double(parts[0]), let longitude = Double(parts[1]) else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func updateMapPosition() {
        guard let order = order else { return }

        let storeCoordinate = storeCoordinate(for: order)
        let customerCoordinate = customerCoordinate(for: order)
        let driverCoordinate = coordinate(from: order.driverLocation)

        let coordinates = [storeCoordinate, customerCoordinate, driverCoordinate].compactMap { $0 }
        guard !coordinates.isEmpty else { return }

        let averageLatitude = coordinates.map(\ .latitude).reduce(0, +) / Double(coordinates.count)
        let averageLongitude = coordinates.map(\ .longitude).reduce(0, +) / Double(coordinates.count)
        let latitudeDelta = max(0.02, (coordinates.map(\ .latitude).max() ?? averageLatitude) - (coordinates.map(\ .latitude).min() ?? averageLatitude) + 0.04)
        let longitudeDelta = max(0.02, (coordinates.map(\ .longitude).max() ?? averageLongitude) - (coordinates.map(\ .longitude).min() ?? averageLongitude) + 0.04)

        mapPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude),
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        )
    }

    private func productForTrackingItem(item: CartItem, order: Order) -> Product? {
        if let directProduct = item.product {
            return directProduct
        }

        let productId = Int(item.productId.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Int(item.id)
        guard let productId else { return nil }

        let storeId = Int(order.storeId) ?? Int(item.storeId) ?? 0
        let stock = max(item.stock ?? item.quantity, item.quantity)

        return Product(
            id: productId,
            name: item.displayName,
            description: nil,
            price: String(format: "%.2f", item.price),
            currency: item.currency,
            image_url: item.imageUrl,
            imageURLs: nil,
            category_id: 0,
            store_id: storeId,
            stock: stock,
            status: item.status,
            is_active: 1,
            created_at: nil,
            updated_at: nil,
            store_name: order.storeName,
            store_phone: order.phone,
            owner_email: nil,
            owner_uid: nil,
            category_name: nil
        )
    }

    private func storeForProductDetails() -> Store {
        if let store {
            return store
        }

        return Store(
            id: Int(order?.storeId ?? "0") ?? 0,
            name: order?.storeName ?? "Store",
            storeType: nil,
            iconUrl: nil,
            address: order?.shippingAddress,
            phone: order?.phone,
            latitude: order?.storeLatitude,
            longitude: order?.storeLongitude,
            status: nil,
            email: nil,
            ownerUid: nil,
            uid: nil
        )
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundColor(.orange)
            Text("Could not load tracking")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(.label))
            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

private struct CoordinatePayload: Decodable {
    let latitude: Double?
    let longitude: Double?
    let lat: Double?
    let lng: Double?
    let coordinates: [Double]?

    var coordinate: CLLocationCoordinate2D? {
        if let latitude, let longitude {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        if let lat, let lng {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }

        if let coordinates, coordinates.count >= 2 {
            return CLLocationCoordinate2D(latitude: coordinates[0], longitude: coordinates[1])
        }

        return nil
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case lat
        case lng
        case coordinates
    }
}

extension OrderStatus {
    var displayTitle: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .processing: return "Processing"
        case .shipped: return "Out for delivery"
        case .outForDelivery: return "Out for delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }

    var accentColor: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .blue
        case .processing: return .purple
        case .shipped: return .green
        case .outForDelivery: return .green
        case .delivered: return .green
        case .cancelled, .failed: return .red
        }
    }

    var progressIndex: Int {
        switch self {
        case .pending: return 0
        case .confirmed: return 1
        case .processing: return 2
        case .shipped: return 3
        case .outForDelivery: return 3
        case .delivered: return 4
        case .cancelled, .failed: return 0
        }
    }

    var isTrackable: Bool {
        self != .delivered && self != .cancelled && self != .failed
    }

    var isTerminal: Bool {
        self == .delivered || self == .cancelled || self == .failed
    }
}

import SwiftUI
import MapKit
import CoreLocation
import AVFoundation
import UIKit

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 1. DELIVERY OFFER SHEET (لما يجي طلب جديد)
// ═══════════════════════════════════════════════════════════════════════════════

struct DeliveryOfferSheet: View {
    let offer: DeliveryOffer
    let driverLocation: CLLocationCoordinate2D?
    let onAccept: () async -> Void
    let onSkip: () async -> Void
    let onTimeout: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var remainingSeconds: Int
    @State private var countdownTimer: Timer?
    @State private var isProcessing = false
    @State private var routeToStore: [CLLocationCoordinate2D] = []
    @State private var routeToCustomer: [CLLocationCoordinate2D] = []
    @State private var showFullRoute = false
    @State private var storeETA: String = "—"
    @State private var customerETA: String = "—"
    @State private var totalDistanceMeters: Double = 0

    init(offer: DeliveryOffer,
         driverLocation: CLLocationCoordinate2D?,
         onAccept: @escaping () async -> Void,
         onSkip: @escaping () async -> Void,
         onTimeout: @escaping () -> Void) {
        self.offer = offer
        self.driverLocation = driverLocation
        self.onAccept = onAccept
        self.onSkip = onSkip
        self.onTimeout = onTimeout

        if let expiresAt = offer.expiresAt,
           let date = ISO8601DateFormatter.deliveryFormatter.date(from: expiresAt) {
            _remainingSeconds = State(initialValue: max(1, Int(date.timeIntervalSinceNow.rounded())))
        } else {
            _remainingSeconds = State(initialValue: 120)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            mapView.frame(maxHeight: .infinity)
            routeToggle
            infoChips
            actionButtons
        }
        .background(DeliveryTheme.darkBackground)
        .onAppear {
            startCountdown()
            fetchRoutes()
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
        .presentationDragIndicator(.visible)
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(remainingSeconds) / 120.0)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                Text("\(remainingSeconds)s")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(timerColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("New Delivery Request")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DeliveryTheme.primaryText)
                Text(offer.order?.storeName ?? "Store")
                    .font(.system(size: 13))
                    .foregroundColor(DeliveryTheme.secondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(DeliveryTheme.cardBackground)
    }

    private var timerColor: Color {
        remainingSeconds > 30 ? DeliveryTheme.accentGreen :
            remainingSeconds > 10 ? DeliveryTheme.accentOrange : DeliveryTheme.accentRed
    }

    private var mapView: some View {
        Map {
            if let store = storeCoordinate {
                Annotation("Store", coordinate: store) {
                    mapPin(color: DeliveryTheme.accentOrange, icon: "storefront.fill")
                }
            }
            if showFullRoute, let customer = customerCoordinate {
                Annotation("Customer", coordinate: customer) {
                    mapPin(color: DeliveryTheme.accentGreen, icon: "person.fill")
                }
            }
            if let driver = driverLocation {
                Annotation("You", coordinate: driver) {
                    mapPin(color: DeliveryTheme.accentBlue, icon: "location.north.fill")
                }
            }
            if !routeToStore.isEmpty {
                MapPolyline(coordinates: routeToStore)
                    .stroke(.white, lineWidth: 4)
            }
            if showFullRoute && !routeToCustomer.isEmpty {
                MapPolyline(coordinates: routeToCustomer)
                    .stroke(DeliveryTheme.accentGreen.opacity(0.8), lineWidth: 4)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
    }

    private func mapPin(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                .shadow(radius: 3)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var routeToggle: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation { showFullRoute.toggle() }
            } label: {
                HStack {
                    Image(systemName: showFullRoute ? "point.topleft.down.to.point.bottomright.curvepath" : "storefront")
                        .font(.system(size: 14, weight: .semibold))
                    Text(showFullRoute ? "Full Route" : "To Store Only")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(showFullRoute ? DeliveryTheme.accentBlue : DeliveryTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    showFullRoute ? DeliveryTheme.accentBlue.opacity(0.15) : DeliveryTheme.cardBackground,
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(showFullRoute ? DeliveryTheme.accentBlue : DeliveryTheme.separator)
                )
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(DeliveryTheme.accentGreen)
                Text(showFullRoute ? "\(storeETA) + \(customerETA)" : storeETA)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DeliveryTheme.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var infoChips: some View {
        HStack(spacing: 0) {
            infoChip(
                icon: "dollarsign.circle.fill",
                value: String(format: "$%.2f", offer.order?.totalPrice ?? 0),
                label: "Order"
            )
            infoChip(
                icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                value: formattedDistance,
                label: "Distance"
            )
            infoChip(
                icon: "banknote.fill",
                value: String(format: "$%.2f", offer.bidPrice),
                label: "Your Earn"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func infoChip(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(DeliveryTheme.accentBlue)
                .padding(8)
                .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(DeliveryTheme.primaryText)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(DeliveryTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    countdownTimer?.invalidate()
                    await onSkip()
                    dismiss()
                }
            } label: {
                Text("Skip")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DeliveryTheme.accentRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DeliveryTheme.accentRed, lineWidth: 1.5)
                    )
            }
            .disabled(isProcessing)

            Button {
                Task {
                    isProcessing = true
                    countdownTimer?.invalidate()
                    await onAccept()
                    dismiss()
                }
            } label: {
                Group {
                    if isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Accept Order")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DeliveryTheme.accentGreen, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isProcessing)
        }
        .padding(16)
    }

    private var storeCoordinate: CLLocationCoordinate2D? {
        guard let coord = offer.order?.storeCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
    }

    private var customerCoordinate: CLLocationCoordinate2D? {
        guard let coord = offer.order?.customerCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
    }

    private var formattedDistance: String {
        if totalDistanceMeters < 1000 {
            return "\(Int(totalDistanceMeters))m"
        }
        return String(format: "%.1fkm", totalDistanceMeters / 1000)
    }

    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                countdownTimer?.invalidate()
                onTimeout()
                dismiss()
            }
        }
    }

    private func fetchRoutes() {
        guard let driver = driverLocation, let store = storeCoordinate else { return }

        Task {
            if let route = await MKRouteHelper.calculateRoute(from: driver, to: store) {
                await MainActor.run {
                    routeToStore = route.points
                    storeETA = formatDuration(route.expectedTime)
                    totalDistanceMeters = route.distance
                }
            }

            if let customer = customerCoordinate,
               let route = await MKRouteHelper.calculateRoute(from: store, to: customer) {
                await MainActor.run {
                    routeToCustomer = route.points
                    customerETA = formatDuration(route.expectedTime)
                    totalDistanceMeters += route.distance
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60).rounded()))
        return "\(minutes)m"
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 2. DELIVERY NAVIGATION VIEW
// ═══════════════════════════════════════════════════════════════════════════════

struct DeliveryNavigationView: View {
    let order: Order
    let onComplete: () -> Void

    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var phase: DeliveryPhase
    @State private var routePoints: [CLLocationCoordinate2D] = []
    @State private var routeDistance: Double = 0
    @State private var routeDuration: Int = 0
    @State private var isAtDestination = false
    @State private var showQRScanner = false
    @State private var showSuccessDialog = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var lastRouteRefresh = Date.distantPast
    @State private var locationUpdateTimer: Timer?

    private let arrivalThreshold: CLLocationDistance = 100

    init(order: Order, onComplete: @escaping () -> Void) {
        self.order = order
        self.onComplete = onComplete
        _phase = State(initialValue: (order.pickedUpAt != nil || order.status == .outForDelivery) ? .goingToCustomer : .goingToStore)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            topHeader
            VStack {
                Spacer()
                bottomCard
            }
            if isProcessing {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .sheet(isPresented: $showQRScanner) {
            DeliveryQRScanner(orderId: order.id) { scannedValue in
                Task { await handleScan(scannedValue) }
            }
        }
        .alert("Delivery Complete! 🎉", isPresented: $showSuccessDialog) {
            Button("Back to Dashboard") {
                onComplete()
                dismiss()
            }
        } message: {
            Text("Great job! The order has been delivered successfully.")
        }
        .task {
            await refreshRoute()
            startLocationTracking()
        }
        .onDisappear {
            locationUpdateTimer?.invalidate()
        }
        .onReceive(locationManager.$currentLocation) { newLocation in
            checkProximity(to: newLocation)
            if Date().timeIntervalSince(lastRouteRefresh) > 10 {
                Task { await refreshRoute() }
            }
        }
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage)
                    .padding()
                    .background(DeliveryTheme.accentRed, in: Capsule())
                    .foregroundColor(.white)
                    .padding(.bottom, 280)
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $mapPosition) {
            if let store = storeCoordinate {
                Annotation("Store", coordinate: store) {
                    pinView(
                        color: phase == .goingToStore ? DeliveryTheme.accentOrange : .gray,
                        icon: "storefront.fill"
                    )
                }
            }
            if let customer = customerCoordinate {
                Annotation("Customer", coordinate: customer) {
                    pinView(
                        color: phase == .goingToCustomer ? DeliveryTheme.accentGreen : .gray,
                        icon: "person.fill"
                    )
                }
            }
            if let driver = locationManager.currentLocation {
                Annotation("You", coordinate: driver) {
                    ZStack {
                        Circle()
                            .fill(DeliveryTheme.accentBlue)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                            .shadow(color: DeliveryTheme.accentBlue.opacity(0.5), radius: 8)
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            if !routePoints.isEmpty {
                MapPolyline(coordinates: routePoints)
                    .stroke(phase == .goingToStore ? .white : DeliveryTheme.accentBlue, lineWidth: 5)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .ignoresSafeArea()
    }

    private func pinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                .shadow(radius: 4)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var topHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(DeliveryTheme.cardBackground, in: Circle())
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phase == .goingToStore ? "Pick up from" : "Deliver to")
                        .font(.system(size: 10))
                        .foregroundColor(DeliveryTheme.secondaryText)
                    Text(destinationName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DeliveryTheme.primaryText)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(routeDuration > 0 ? "\(routeDuration)m" : "—")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(DeliveryTheme.accentBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(DeliveryTheme.accentBlue.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DeliveryTheme.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))

            Button {
                openInAppleMaps()
            } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(DeliveryTheme.accentGreen, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }

    private var bottomCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                phaseDot(icon: "storefront.fill", label: "Store",
                         isActive: phase == .goingToStore,
                         isCompleted: phase != .goingToStore)

                Rectangle()
                    .fill(phase != .goingToStore ? DeliveryTheme.accentGreen : DeliveryTheme.separator)
                    .frame(width: 30, height: 2)

                phaseDot(icon: "person.fill", label: "Customer",
                         isActive: phase == .goingToCustomer,
                         isCompleted: false)
            }

            HStack(spacing: 6) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 13))
                Text(formatDistance(routeDistance))
                    .font(.system(size: 13))
            }
            .foregroundColor(DeliveryTheme.secondaryText)

            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundColor(DeliveryTheme.accentOrange)
                Text(String(format: "Your earnings: $%.2f", order.totalPrice * 0.10))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DeliveryTheme.accentOrange)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DeliveryTheme.accentOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            Button {
                Task { await performMainAction() }
            } label: {
                HStack {
                    Image(systemName: mainActionIcon)
                        .font(.system(size: 18, weight: .bold))
                    Text(mainActionLabel)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(mainActionBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isMainActionEnabled || isProcessing)
        }
        .padding(16)
        .background(DeliveryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
        .padding(.horizontal, 12)
        .padding(.bottom, 30)
    }

    private func phaseDot(icon: String, label: String, isActive: Bool, isCompleted: Bool) -> some View {
        let color: Color = isCompleted ? DeliveryTheme.accentGreen : (isActive ? DeliveryTheme.accentBlue : DeliveryTheme.separator)
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(color, lineWidth: 2))
                Image(systemName: isCompleted ? "checkmark" : icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
    }

    private var mainActionLabel: String {
        switch phase {
        case .goingToStore:
            return isAtDestination ? "Scan QR to Pickup" : "Drive to Store"
        case .goingToCustomer:
            return isAtDestination ? "Mark Delivered" : "Drive to Customer"
        }
    }

    private var mainActionIcon: String {
        switch phase {
        case .goingToStore:
            return isAtDestination ? "qrcode.viewfinder" : "car.fill"
        case .goingToCustomer:
            return isAtDestination ? "checkmark.seal.fill" : "car.fill"
        }
    }

    private var mainActionBackground: Color {
        if !isMainActionEnabled { return Color.gray.opacity(0.5) }
        switch phase {
        case .goingToStore: return DeliveryTheme.accentBlue
        case .goingToCustomer: return DeliveryTheme.accentGreen
        }
    }

    private var isMainActionEnabled: Bool {
        isAtDestination
    }

    private func performMainAction() async {
        guard isAtDestination else {
            errorMessage = "You need to arrive at the destination first"
            try? await Task.sleep(for: .seconds(2))
            errorMessage = nil
            return
        }

        switch phase {
        case .goingToStore:
            showQRScanner = true
        case .goingToCustomer:
            await markDelivered()
        }
    }

    private func handleScan(_ scannedValue: String) async {
        let normalized = scannedValue.trimmingCharacters(in: .whitespaces)
        let isMatch = normalized == order.id ||
                      normalized == "ORDER-\(order.id)" ||
                      normalized.contains(order.id)

        guard isMatch else {
            await MainActor.run {
                errorMessage = "QR code doesn't match this order"
            }
            return
        }

        await MainActor.run { isProcessing = true }
        do {
            _ = try await DeliveryService.pickupOrder(orderId: order.id)
            await MainActor.run {
                showQRScanner = false
                phase = .goingToCustomer
                isAtDestination = false
                isProcessing = false
            }
            await refreshRoute()
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = "Pickup failed: \(error.localizedDescription)"
            }
        }
    }

    private func markDelivered() async {
        await MainActor.run { isProcessing = true }
        do {
            _ = try await DeliveryService.deliverOrder(orderId: order.id)
            await MainActor.run {
                isProcessing = false
                showSuccessDialog = true
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = "Delivery failed: \(error.localizedDescription)"
            }
        }
    }

    private func checkProximity(to location: CLLocationCoordinate2D?) {
        guard let location else { return }
        let target = phase == .goingToStore ? storeCoordinate : customerCoordinate
        guard let target else { return }

        let driverLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let targetLoc = CLLocation(latitude: target.latitude, longitude: target.longitude)
        let distance = driverLoc.distance(from: targetLoc)

        isAtDestination = distance <= arrivalThreshold
    }

    private func refreshRoute() async {
        guard let driver = locationManager.currentLocation else { return }
        let target = phase == .goingToStore ? storeCoordinate : customerCoordinate
        guard let target else { return }

        lastRouteRefresh = Date()

        if let route = await MKRouteHelper.calculateRoute(from: driver, to: target) {
            await MainActor.run {
                routePoints = route.points
                routeDistance = route.distance
                routeDuration = max(1, Int((route.expectedTime / 60).rounded()))
                updateMapCamera(driver: driver, target: target)
            }
        }
    }

    private func updateMapCamera(driver: CLLocationCoordinate2D, target: CLLocationCoordinate2D) {
        let center = CLLocationCoordinate2D(
            latitude: (driver.latitude + target.latitude) / 2,
            longitude: (driver.longitude + target.longitude) / 2
        )
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        mapPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func startLocationTracking() {
        locationManager.startUpdatingLocation()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            guard let coord = locationManager.currentLocation else { return }
            Task {
                _ = try? await DeliveryService.updateDriverLocation(latitude: coord.latitude, longitude: coord.longitude)
                if phase == .goingToCustomer {
                    _ = try? await DeliveryService.updateDeliveryLocation(orderId: order.id, latitude: coord.latitude, longitude: coord.longitude)
                }
            }
        }
    }

    private func openInAppleMaps() {
        let target = phase == .goingToStore ? storeCoordinate : customerCoordinate
        guard let target else { return }
        let url = "https://maps.apple.com/?daddr=\(target.latitude),\(target.longitude)&dirflg=d"
        if let u = URL(string: url) { openURL(u) }
    }

    private var destinationName: String {
        phase == .goingToStore ? (order.storeName ?? "Store") : (order.customerName ?? "Customer")
    }

    private var storeCoordinate: CLLocationCoordinate2D? {
        guard let coord = order.storeCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
    }

    private var customerCoordinate: CLLocationCoordinate2D? {
        guard let coord = order.customerCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 { return "\(Int(meters))m" }
        return String(format: "%.1fkm", meters / 1000)
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 3. DELIVERY DASHBOARD VIEW
// ═══════════════════════════════════════════════════════════════════════════════

struct DeliveryDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stats: DriverStats?
    @State private var history: [Order] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                DeliveryTheme.darkBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        statsCard
                        historySection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("My Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(DeliveryTheme.accentBlue)
                }
            }
            .task { await loadData() }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Earnings (10%)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DeliveryTheme.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "$%.2f", stats?.totalEarningsToday ?? 0))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(DeliveryTheme.primaryText)
                Text("today")
                    .font(.system(size: 13))
                    .foregroundColor(DeliveryTheme.secondaryText)
            }

            Divider().background(DeliveryTheme.separator)

            HStack(spacing: 12) {
                statItem(label: "Total", value: "\(stats?.totalDeliveries ?? 0)", icon: "bag.fill")
                statItem(label: "Today", value: "\(stats?.completedToday ?? 0)", icon: "calendar")
                statItem(label: "Rating", value: String(format: "%.1f", stats?.averageRating ?? 0), icon: "star.fill")
            }
        }
        .padding(20)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DeliveryTheme.accentBlue)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(DeliveryTheme.primaryText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DeliveryTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Deliveries")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(DeliveryTheme.primaryText)
                Spacer()
                if !history.isEmpty {
                    Text("\(history.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DeliveryTheme.secondaryText)
                }
            }
            .padding(.horizontal, 4)

            if isLoading {
                ProgressView().tint(DeliveryTheme.accentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if history.isEmpty {
                emptyHistory
            } else {
                ForEach(history, id: \.id) { order in
                    historyRow(order)
                }
            }
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag")
                .font(.system(size: 36))
                .foregroundColor(DeliveryTheme.secondaryText.opacity(0.5))
            Text("No deliveries yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(DeliveryTheme.secondaryText)
            Text("Your completed deliveries will appear here")
                .font(.system(size: 12))
                .foregroundColor(DeliveryTheme.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func historyRow(_ order: Order) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DeliveryTheme.accentGreen.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark")
                    .foregroundColor(DeliveryTheme.accentGreen)
                    .font(.system(size: 14, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(order.storeName ?? "Order #\(order.id)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DeliveryTheme.primaryText)
                Text("Order #\(order.id)")
                    .font(.system(size: 11))
                    .foregroundColor(DeliveryTheme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "+$%.2f", order.totalPrice * 0.10))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DeliveryTheme.accentGreen)
                Text("Earned")
                    .font(.system(size: 10))
                    .foregroundColor(DeliveryTheme.secondaryText)
            }
        }
        .padding(12)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadData() async {
        async let statsTask = try? await DeliveryService.getDriverStats()
        async let historyTask = try? await DeliveryService.getDeliveryHistory()

        let (statsResult, historyResult) = await (statsTask, historyTask)

        await MainActor.run {
            stats = statsResult
            history = historyResult ?? []
            isLoading = false
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 4. QR SCANNER
// ═══════════════════════════════════════════════════════════════════════════════

struct DeliveryQRScanner: UIViewControllerRepresentable {
    let orderId: String
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerVC {
        QRScannerVC(orderId: orderId, onScan: onScan)
    }

    func updateUIViewController(_ uiViewController: QRScannerVC, context: Context) {}
}

final class QRScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let orderId: String
    private let onScan: (String) -> Void
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didScan = false

    init(orderId: String, onScan: @escaping (String) -> Void) {
        self.orderId = orderId
        self.onScan = onScan
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
    }

    private func configureUI() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(overlay)

        let cutoutSize: CGFloat = 280
        let cutoutFrame = CGRect(
            x: (view.bounds.width - cutoutSize) / 2,
            y: (view.bounds.height - cutoutSize) / 2,
            width: cutoutSize,
            height: cutoutSize
        )

        let path = UIBezierPath(rect: overlay.bounds)
        path.append(UIBezierPath(roundedRect: cutoutFrame, cornerRadius: 20).reversing())
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        overlay.layer.mask = mask

        let border = UIView(frame: cutoutFrame)
        border.layer.borderWidth = 3
        border.layer.borderColor = UIColor.systemBlue.cgColor
        border.layer.cornerRadius = 20
        view.addSubview(border)

        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeBtn.layer.cornerRadius = 20
        closeBtn.frame = CGRect(x: 20, y: 60, width: 40, height: 40)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeBtn)

        let title = UILabel(frame: CGRect(x: 0, y: 110, width: view.bounds.width, height: 40))
        title.text = "Scan Order #\(orderId)"
        title.textAlignment = .center
        title.textColor = .white
        title.font = .systemFont(ofSize: 16, weight: .bold)
        view.addSubview(title)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        didScan = true
        session.stopRunning()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onScan(value)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 5. HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

enum DeliveryPhase {
    case goingToStore
    case goingToCustomer
}

struct MKRouteHelper {
    struct RouteResult {
        let points: [CLLocationCoordinate2D]
        let distance: Double
        let expectedTime: TimeInterval
    }

    static func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> RouteResult? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else { return nil }

            let count = route.polyline.pointCount
            var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: count)
            route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))

            return RouteResult(
                points: coords,
                distance: route.distance,
                expectedTime: route.expectedTravelTime
            )
        } catch {
            return nil
        }
    }
}

extension ISO8601DateFormatter {
    static let deliveryFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

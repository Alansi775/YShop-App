import SwiftUI
import MapKit
import CoreLocation
import AVFoundation
import UIKit

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 1. DELIVERY OFFER SHEET
// ═══════════════════════════════════════════════════════════════════════════════

struct DeliveryOfferSheet: View {
    let offer: DeliveryOffer
    let driverLocation: CLLocationCoordinate2D?
    let onAccept: () async -> Void
    let onSkip: () async -> Void
    let onTimeout: () -> Void

    @EnvironmentObject private var locationManager: LocationManager
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
        .onAppear { startCountdown(); fetchRoutes() }
        .onReceive(locationManager.$currentLocation) { _ in fetchRoutes() }
        .onDisappear { countdownTimer?.invalidate() }
        .presentationDragIndicator(.visible)
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().strokeBorder(Color.gray.opacity(0.3), lineWidth: 4).frame(width: 56, height: 56)
                Circle().trim(from: 0, to: CGFloat(remainingSeconds) / 120.0)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 56, height: 56)
                Text("\(remainingSeconds)s").font(.system(size: 14, weight: .bold)).foregroundColor(timerColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("New Delivery Request").font(.system(size: 18, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                Text(offer.order?.storeName ?? "Store").font(.system(size: 13)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Spacer()
        }
        .padding(16).background(DeliveryTheme.cardBackground)
    }

    private var timerColor: Color {
        remainingSeconds > 30 ? DeliveryTheme.accentGreen : remainingSeconds > 10 ? DeliveryTheme.accentOrange : DeliveryTheme.accentRed
    }

    private var mapView: some View {
        Map {
            if let store = storeCoordinate {
                Annotation("Store", coordinate: store) { mapPin(color: DeliveryTheme.accentOrange, icon: "storefront.fill") }
            }
            if showFullRoute, let customer = customerCoordinate {
                Annotation("Customer", coordinate: customer) { mapPin(color: DeliveryTheme.accentGreen, icon: "person.fill") }
            }
            if let driver = driverLocation {
                Annotation("You", coordinate: driver) { mapPin(color: DeliveryTheme.accentBlue, icon: "location.north.fill") }
            }
            if !routeToStore.isEmpty { MapPolyline(coordinates: routeToStore).stroke(DeliveryTheme.routeBlue, lineWidth: 5) }
            if showFullRoute && !routeToCustomer.isEmpty { MapPolyline(coordinates: routeToCustomer).stroke(DeliveryTheme.accentGreen.opacity(0.8), lineWidth: 4) }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
    }

    private func mapPin(color: Color, icon: String) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 36, height: 36).overlay(Circle().strokeBorder(.white, lineWidth: 2)).shadow(radius: 3)
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
        }
    }

    private var routeToggle: some View {
        HStack(spacing: 10) {
            Button { withAnimation { showFullRoute.toggle() } } label: {
                HStack {
                    Image(systemName: showFullRoute ? "point.topleft.down.to.point.bottomright.curvepath" : "storefront").font(.system(size: 14, weight: .semibold))
                    Text(showFullRoute ? "Full Route" : "To Store Only").font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(showFullRoute ? DeliveryTheme.accentBlue : DeliveryTheme.secondaryText)
                .padding(.horizontal, 14).padding(.vertical, 10).frame(maxWidth: .infinity)
                .background(showFullRoute ? DeliveryTheme.accentBlue.opacity(0.15) : DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(showFullRoute ? DeliveryTheme.accentBlue : DeliveryTheme.separator))
            }
            HStack(spacing: 6) {
                Image(systemName: "clock").font(.system(size: 12)).foregroundColor(DeliveryTheme.accentGreen)
                Text(showFullRoute ? "\(storeETA) + \(customerETA)" : storeETA).font(.system(size: 12, weight: .semibold)).foregroundColor(DeliveryTheme.primaryText)
            }
            .padding(.horizontal, 12).padding(.vertical, 10).background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private var infoChips: some View {
        HStack(spacing: 0) {
            infoChip(icon: "dollarsign.circle.fill", value: String(format: "$%.2f", offer.order?.totalPrice ?? 0), label: "Order")
            infoChip(icon: "point.topleft.down.curvedto.point.bottomright.up.fill", value: formattedDistance, label: "Distance")
            infoChip(icon: "banknote.fill", value: String(format: "$%.2f", offer.bidPrice), label: "Your Earn")
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func infoChip(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(DeliveryTheme.accentBlue)
                .padding(8).background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
            Text(label).font(.system(size: 10)).foregroundColor(DeliveryTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { Task { countdownTimer?.invalidate(); await onSkip(); dismiss() } } label: {
                Text("Skip").font(.system(size: 15, weight: .bold)).foregroundColor(DeliveryTheme.accentRed)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).strokeBorder(DeliveryTheme.accentRed, lineWidth: 1.5))
            }
            .disabled(isProcessing)
            Button { Task { isProcessing = true; countdownTimer?.invalidate(); await onAccept(); dismiss() } } label: {
                Group {
                    if isProcessing { ProgressView().tint(.white) }
                    else { Text("Accept Order").font(.system(size: 15, weight: .bold)) }
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
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
        totalDistanceMeters < 1000 ? "\(Int(totalDistanceMeters))m" : String(format: "%.1fkm", totalDistanceMeters / 1000)
    }
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 { remainingSeconds -= 1 }
            else { countdownTimer?.invalidate(); onTimeout(); dismiss() }
        }
    }
    private func fetchRoutes() {
        guard let driver = effectiveDriverLocation, let store = storeCoordinate else { return }
        Task {
            if let route = await MKRouteHelper.calculateRoute(from: driver, to: store) {
                await MainActor.run { routeToStore = route.points; storeETA = formatDuration(route.expectedTime); totalDistanceMeters = route.distance }
            }
            if let customer = customerCoordinate, let route = await MKRouteHelper.calculateRoute(from: store, to: customer) {
                await MainActor.run { routeToCustomer = route.points; customerETA = formatDuration(route.expectedTime); totalDistanceMeters += route.distance }
            }
        }
    }
    private var effectiveDriverLocation: CLLocationCoordinate2D? { locationManager.currentLocation ?? driverLocation }
    private func formatDuration(_ seconds: TimeInterval) -> String { "\(max(1, Int((seconds / 60).rounded())))m" }
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
    @State private var showSatellite = false
    @State private var isFollowingDriver = false
    @State private var isCardCollapsed = false
    @State private var cardOffset: CGFloat = 0
    @State private var heading: Double = 0
    @State private var headingTimer: Timer?
    @State private var traveledPoints: [CLLocationCoordinate2D] = []
    @State private var lastUserInteraction: Date = .distantPast
    @State private var autoRecenterTimer: Timer?

    private let arrivalThreshold: CLLocationDistance = 100
    private let collapsedOffset: CGFloat = 90

    init(order: Order, onComplete: @escaping () -> Void) {
        self.order = order
        self.onComplete = onComplete
        _phase = State(initialValue: (order.pickedUpAt != nil || order.status == .outForDelivery) ? .goingToCustomer : .goingToStore)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            topHeader
            VStack { Spacer(); draggableCard }
            if isProcessing {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView(orderId: order.id) { scannedValue in
                Task { await handleScan(scannedValue) }
            }
        }
        .alert("Delivery Complete! 🎉", isPresented: $showSuccessDialog) {
            Button("Back to Dashboard") { onComplete(); dismiss() }
        } message: {
            Text("Great job! The order has been delivered successfully.")
        }
        .task { await refreshRoute(); startLocationTracking(); startHeadingTracking() }
        .onDisappear {
            locationUpdateTimer?.invalidate()
            headingTimer?.invalidate()
            autoRecenterTimer?.invalidate()
        }
        .onReceive(locationManager.$currentLocation) { newLocation in
            checkProximity(to: newLocation)
            if let loc = newLocation {
                // أضف الموقع لمسار المقطوع
                traveledPoints.append(loc)
                // حدّث الكاميرا
                if isFollowingDriver { updateMapCamera(driver: loc) }
            }
            if routePoints.isEmpty || Date().timeIntervalSince(lastRouteRefresh) > 10 {
                Task { await refreshRoute() }
            }
            if !isFollowingDriver, let loc = newLocation {
                isFollowingDriver = true
                updateMapCamera(driver: loc)
            }
        }   
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage).padding()
                    .background(DeliveryTheme.accentRed, in: Capsule())
                    .foregroundColor(.white)
                    .padding(.bottom, isCardCollapsed ? 80 : 340)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $mapPosition) {
            if let store = storeCoordinate {
                Annotation("Store", coordinate: store) {
                    pinView(color: phase == .goingToStore ? DeliveryTheme.accentOrange : .gray.opacity(0.5), icon: "storefront.fill")
                }
            }
            if let customer = customerCoordinate {
                Annotation("Customer", coordinate: customer) {
                    pinView(color: phase == .goingToCustomer ? DeliveryTheme.accentGreen : .gray.opacity(0.5), icon: "person.fill")
                }
            }
            if let driver = locationManager.currentLocation {
                Annotation("You", coordinate: driver) { compassArrow }
            }
            // الجزء اللي مشى منه → رمادي
            if traveledPoints.count >= 2 {
                MapPolyline(coordinates: traveledPoints)
                    .stroke(.gray.opacity(0.5), lineWidth: 5)
            }
            // الجزء القادم → أزرق
            if !routePoints.isEmpty {
                MapPolyline(coordinates: routePoints)
                    .stroke(DeliveryTheme.routeBlue, lineWidth: 5)
            }
        }
        .mapStyle(showSatellite ? .imagery(elevation: .flat) : .standard(elevation: .flat))
        .ignoresSafeArea()
        .onMapCameraChange { _ in
            // لما يلمس المستخدم الخريطة → وقف الـ auto-follow
            lastUserInteraction = Date()
            isFollowingDriver = false
            // بعد ثانية → ارجع للـ follow
            autoRecenterTimer?.invalidate()
            autoRecenterTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                isFollowingDriver = true
                if let loc = locationManager.currentLocation {
                    updateMapCamera(driver: loc)
                }
            }
        }
    }

    // البوصلة الدوارة
    private var compassArrow: some View {
        ZStack {
            Circle().fill(DeliveryTheme.accentBlue).frame(width: 48, height: 48)
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .shadow(color: DeliveryTheme.accentBlue.opacity(0.5), radius: 8)
            Image(systemName: "location.north.fill")
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                // الأيقونة ثابتة — الخريطة هي اللي تدور مع heading
        }
    }

    private func pinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2)).shadow(radius: 4)
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
        }
    }

    // MARK: - Top Header

    private var topHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(10).background(DeliveryTheme.cardBackground, in: Circle())
            }
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phase == .goingToStore ? "Pick up from" : "Deliver to")
                        .font(.system(size: 10)).foregroundColor(DeliveryTheme.secondaryText)
                    Text(destinationName).font(.system(size: 14, weight: .bold)).foregroundColor(DeliveryTheme.primaryText).lineLimit(1)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 11))
                    Text(routeDuration > 0 ? "\(routeDuration)m" : "—").font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(DeliveryTheme.accentBlue).padding(.horizontal, 10).padding(.vertical, 5)
                .background(DeliveryTheme.accentBlue.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(DeliveryTheme.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))

            Button { withAnimation { showSatellite.toggle() } } label: {
                Image(systemName: showSatellite ? "globe.americas.fill" : "map.fill")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(10).background(showSatellite ? DeliveryTheme.accentOrange : DeliveryTheme.accentGreen, in: Circle())
            }
        }
        .padding(.horizontal, 16).padding(.top, 50)
    }

    // MARK: - Draggable Card

    private var draggableCard: some View {
        VStack(spacing: 0) {
            // Handle + hint
            VStack(spacing: 5) {
                Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4).padding(.top, 10)
                HStack(spacing: 4) {
                    Image(systemName: isCardCollapsed ? "chevron.up" : "chevron.down").font(.system(size: 10))
                    Text(isCardCollapsed ? "Show details" : "Swipe down to focus").font(.system(size: 11))
                }
                .foregroundColor(DeliveryTheme.secondaryText).padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCardCollapsed.toggle()
                    cardOffset = isCardCollapsed ? collapsedOffset : 0
                }
            }

            if isCardCollapsed {
                miniCard
            } else {
                cardContent.transition(.opacity)
            }
        }
        .background(DeliveryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
        .padding(.horizontal, 12).padding(.bottom, 16)
        .offset(y: cardOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let drag = value.translation.height
                    if isCardCollapsed {
                        let newOffset = collapsedOffset + drag
                        cardOffset = max(0, min(newOffset, collapsedOffset))
                    } else {
                        let newOffset = max(0, drag)
                        cardOffset = min(newOffset, collapsedOffset)
                    }
                }
            .onEnded { value in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if value.translation.height > 50 && !isCardCollapsed {
                        isCardCollapsed = true
                        cardOffset = collapsedOffset
                    } else if value.translation.height < -50 && isCardCollapsed {
                        isCardCollapsed = false
                        cardOffset = 0
                    } else if value.velocity.height > 500 && !isCardCollapsed {
                        isCardCollapsed = true
                        cardOffset = collapsedOffset
                    } else if value.velocity.height < -500 && isCardCollapsed {
                        isCardCollapsed = false
                        cardOffset = 0
                    } else {
                        cardOffset = isCardCollapsed ? collapsedOffset : 0
                    }
                }
            }
        )
    }

    // Full card
    private var cardContent: some View {
        VStack(spacing: 14) {
            if phase == .goingToStore { orderInfoCard } else { customerInfoCard }

            // Phase dots
            HStack(spacing: 16) {
                phaseDot(icon: "storefront.fill", label: "Store", isActive: phase == .goingToStore, isCompleted: phase != .goingToStore)
                Rectangle().fill(phase != .goingToStore ? DeliveryTheme.accentGreen : DeliveryTheme.separator).frame(width: 30, height: 2)
                phaseDot(icon: "person.fill", label: "Customer", isActive: phase == .goingToCustomer, isCompleted: false)
            }

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up").font(.system(size: 12))
                    Text(formatDistance(routeDistance)).font(.system(size: 13))
                }
                .foregroundColor(DeliveryTheme.secondaryText)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "banknote.fill").foregroundColor(DeliveryTheme.accentOrange)
                    Text(String(format: "₺%.0f earnings", order.totalPrice * 0.10))
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(DeliveryTheme.accentOrange)
                }
            }
            .padding(.horizontal, 4)

            Button { Task { await performMainAction() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: mainActionIcon).font(.system(size: 18, weight: .bold))
                    Text(mainActionLabel).font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(mainActionBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isProcessing)
        }
        .padding(.horizontal, 16).padding(.bottom, 30)
    }

    // Mini card
    private var miniCard: some View {
        HStack(spacing: 12) {
            Image(systemName: phase == .goingToStore ? "storefront.fill" : "person.fill")
                .foregroundColor(phase == .goingToStore ? DeliveryTheme.accentOrange : DeliveryTheme.accentGreen)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(destinationName).font(.system(size: 14, weight: .semibold)).foregroundColor(DeliveryTheme.primaryText)
                Text("\(formatDistance(routeDistance)) • \(routeDuration > 0 ? "\(routeDuration)m" : "—")")
                    .font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Spacer()
            Button { Task { await performMainAction() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: mainActionIcon).font(.system(size: 13, weight: .bold))
                    Text(isAtDestination ? (phase == .goingToStore ? "Scan" : "Deliver") : "Navigate")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                .background(mainActionBackground, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14).padding(.bottom, 20)
    }

    // MARK: - Order Info Card

    private var orderInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Store + Price
            HStack(spacing: 12) {
                if let iconUrl = order.storeIconFullUrl, let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
                        default:
                            RoundedRectangle(cornerRadius: 10).fill(DeliveryTheme.accentOrange.opacity(0.15)).frame(width: 44, height: 44)
                                .overlay(Image(systemName: "storefront.fill").foregroundColor(DeliveryTheme.accentOrange))
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(DeliveryTheme.accentOrange.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "storefront.fill").font(.system(size: 18)).foregroundColor(DeliveryTheme.accentOrange)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(order.storeName ?? "Store").font(.system(size: 15, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                    Text("Order #\(order.id)").font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "₺%.0f", order.totalPrice)).font(.system(size: 16, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                    Text("\(order.items.count) items").font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
                }
            }
            
            Divider().background(DeliveryTheme.separator)
            
            // Items section - always show
            if !order.items.isEmpty {
                ForEach(order.items.prefix(3)) { item in
                    HStack(spacing: 8) {
                        // Thumbnail
                        if let urlString = item.fullImageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                        .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                default:
                                    RoundedRectangle(cornerRadius: 8).fill(DeliveryTheme.cardBackground).frame(width: 44, height: 44)
                                        .overlay(Image(systemName: "photo").foregroundColor(DeliveryTheme.secondaryText))
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 8).fill(DeliveryTheme.cardBackground).frame(width: 44, height: 44)
                                .overlay(Image(systemName: "photo").foregroundColor(DeliveryTheme.secondaryText))
                        }

                        Text("×\(item.quantity)").font(.system(size: 12, weight: .bold)).foregroundColor(DeliveryTheme.accentBlue).frame(width: 24)
                        Text(item.displayName).font(.system(size: 13)).foregroundColor(DeliveryTheme.primaryText).lineLimit(1)
                        Spacer()
                        Text(String(format: "₺%.0f", item.price * Double(item.quantity))).font(.system(size: 12, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
                    }
                }
                if order.items.count > 3 {
                    Text("+\(order.items.count - 3) more items").font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
                }
            } else {
                // Show loading/empty state
                HStack(spacing: 8) {
                    Image(systemName: "bag.badge.questionmark").font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
                    Text("Loading order items...").font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
                }
                .padding(.vertical, 8)
            }
            
            Divider().background(DeliveryTheme.separator)
            
            // Address
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 13)).foregroundColor(DeliveryTheme.accentRed)
                Text(order.shippingAddress ?? order.deliveryAddress ?? "Delivery address")
                    .font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText).lineLimit(2)
            }
        }
        .padding(14).background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DeliveryTheme.separator, lineWidth: 0.5))
    }

    // MARK: - Customer Info Card

    private var customerInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(DeliveryTheme.accentGreen.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "person.fill").font(.system(size: 18)).foregroundColor(DeliveryTheme.accentGreen)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(order.customerName ?? "Customer").font(.system(size: 15, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                    Text(order.customerPhone ?? "—").font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
                }
                Spacer()
                if let phone = order.customerPhone, !phone.isEmpty {
                    Button {
                        let cleaned = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                        if let url = URL(string: "tel://\(cleaned)") { openURL(url) }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "phone.fill").font(.system(size: 13, weight: .bold))
                            Text("Call").font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(DeliveryTheme.accentGreen, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            Divider().background(DeliveryTheme.separator)
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 14)).foregroundColor(DeliveryTheme.accentRed).frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Delivery Address").font(.system(size: 10, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
                    Text(order.shippingAddress ?? order.deliveryAddress ?? "—").font(.system(size: 13)).foregroundColor(DeliveryTheme.primaryText).lineLimit(3)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "bag.fill").font(.system(size: 14)).foregroundColor(DeliveryTheme.accentBlue).frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order from \(order.storeName ?? "Store")").font(.system(size: 10, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
                    Text("\(order.items.count) items • ₺\(String(format: "%.0f", order.totalPrice))").font(.system(size: 13)).foregroundColor(DeliveryTheme.primaryText)
                }
            }
        }
        .padding(14).background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DeliveryTheme.accentGreen.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Phase Dot

    private func phaseDot(icon: String, label: String, isActive: Bool, isCompleted: Bool) -> some View {
        let color: Color = isCompleted ? DeliveryTheme.accentGreen : (isActive ? DeliveryTheme.accentBlue : DeliveryTheme.separator)
        return VStack(spacing: 4) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 36, height: 36).overlay(Circle().strokeBorder(color, lineWidth: 2))
                Image(systemName: isCompleted ? "checkmark" : icon).font(.system(size: 14, weight: .bold)).foregroundColor(color)
            }
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(color)
        }
    }

    // MARK: - Action Properties

    private var mainActionLabel: String {
        switch phase {
        case .goingToStore: return isAtDestination ? "Scan QR to Pickup" : "Drive to Store"
        case .goingToCustomer: return isAtDestination ? "Mark Delivered" : "Drive to Customer"
        }
    }
    private var mainActionIcon: String {
        switch phase {
        case .goingToStore: return isAtDestination ? "qrcode.viewfinder" : "car.fill"
        case .goingToCustomer: return isAtDestination ? "checkmark.seal.fill" : "car.fill"
        }
    }
    private var mainActionBackground: Color {
        isAtDestination ? DeliveryTheme.accentGreen : DeliveryTheme.accentBlue
    }

    // MARK: - Actions

    private func performMainAction() async {
        switch phase {
        case .goingToStore:
            if isAtDestination { showQRScanner = true } else { centerOnDriver() }
        case .goingToCustomer:
            if isAtDestination { await markDelivered() } else { centerOnDriver() }
        }
    }

    private func centerOnDriver() {
        guard let loc = locationManager.currentLocation else { return }
        withAnimation(.easeInOut(duration: 0.8)) {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
        isFollowingDriver = true
    }

    private func handleScan(_ scannedValue: String) async {
        let normalized = scannedValue.trimmingCharacters(in: .whitespaces)
        let isMatch = normalized == order.id || normalized == "ORDER-\(order.id)" || normalized.contains(order.id)
            || (Int(normalized) != nil && Int(order.id) != nil && Int(normalized) == Int(order.id))
        guard isMatch else {
            await MainActor.run { errorMessage = "QR code doesn't match this order" }
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { errorMessage = nil }
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCardCollapsed = false; cardOffset = 0
                }
            }
            await refreshRoute()
        } catch {
            await MainActor.run { isProcessing = false; errorMessage = "Pickup failed: \(error.localizedDescription)" }
        }
    }

    private func markDelivered() async {
        await MainActor.run { isProcessing = true }
        do {
            _ = try await DeliveryService.deliverOrder(orderId: order.id)
            await MainActor.run { isProcessing = false; showSuccessDialog = true }
        } catch {
            await MainActor.run { isProcessing = false; errorMessage = "Delivery failed: \(error.localizedDescription)" }
        }
    }

    private func checkProximity(to location: CLLocationCoordinate2D?) {
        guard let location else { return }
        let target = phase == .goingToStore ? storeCoordinate : customerCoordinate
        guard let target else { return }
        let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
            .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
        withAnimation { isAtDestination = distance <= arrivalThreshold }
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
                if isFollowingDriver { updateMapCamera(driver: driver) }
            }
        }
    }

    private func updateMapCamera(driver: CLLocationCoordinate2D) {
        guard isFollowingDriver else { return }
        // الكاميرا تنظر نفس اتجاه الموصل — heading-up مثل Apple Maps
        // نضع الموصل في أسفل الشاشة بزيادة offset للشمال
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .camera(MapCamera(
                centerCoordinate: driver,
                distance: 500,
                heading: heading,   // الكاميرا تواجه نفس اتجاه السواق
                pitch: 45           // زاوية perspective مثل navigation apps
            ))
        }
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

    // البوصلة — يقرأ الاتجاه من LocationManager
    private func startHeadingTracking() {
        headingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            guard let h = locationManager.heading else { return }
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.3)) { self.heading = h }
                // حدّث الكاميرا مع الـ heading
                if self.isFollowingDriver, let loc = self.locationManager.currentLocation {
                    self.updateMapCamera(driver: loc)
                }
            }
        }
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
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.1fkm", meters / 1000)
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
                    VStack(spacing: 16) { statsCard; historySection }.padding(16)
                }
            }
            .navigationTitle("My Dashboard").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() }.foregroundColor(DeliveryTheme.accentBlue) } }
            .task { await loadData() }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Earnings (10%)").font(.system(size: 13, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "$%.2f", stats?.totalEarningsToday ?? 0)).font(.system(size: 36, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                Text("today").font(.system(size: 13)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Divider().background(DeliveryTheme.separator)
            HStack(spacing: 12) {
                statItem(label: "Total", value: "\(stats?.totalDeliveries ?? 0)", icon: "bag.fill")
                statItem(label: "Today", value: "\(stats?.completedToday ?? 0)", icon: "calendar")
                statItem(label: "Rating", value: String(format: "%.1f", stats?.averageRating ?? 0), icon: "star.fill")
            }
        }
        .padding(20).background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(DeliveryTheme.accentBlue)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
            Text(label).font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Deliveries").font(.system(size: 17, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                Spacer()
                if !history.isEmpty { Text("\(history.count)").font(.system(size: 13, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText) }
            }
            .padding(.horizontal, 4)
            if isLoading { ProgressView().tint(DeliveryTheme.accentBlue).frame(maxWidth: .infinity).padding(.vertical, 40) }
            else if history.isEmpty { emptyHistory }
            else { ForEach(history, id: \.id) { order in historyRow(order) } }
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag").font(.system(size: 36)).foregroundColor(DeliveryTheme.secondaryText.opacity(0.5))
            Text("No deliveries yet").font(.system(size: 15, weight: .medium)).foregroundColor(DeliveryTheme.secondaryText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    private func historyRow(_ order: Order) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(DeliveryTheme.accentGreen.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "checkmark").foregroundColor(DeliveryTheme.accentGreen).font(.system(size: 14, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(order.storeName ?? "Order #\(order.id)").font(.system(size: 14, weight: .semibold)).foregroundColor(DeliveryTheme.primaryText)
                Text("Order #\(order.id)").font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "+$%.2f", order.totalPrice * 0.10)).font(.system(size: 14, weight: .bold)).foregroundColor(DeliveryTheme.accentGreen)
                Text("Earned").font(.system(size: 10)).foregroundColor(DeliveryTheme.secondaryText)
            }
        }
        .padding(12).background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadData() async {
        async let s = try? await DeliveryService.getDriverStats()
        async let h = try? await DeliveryService.getDeliveryHistory()
        let (sr, hr) = await (s, h)
        await MainActor.run { stats = sr; history = hr ?? []; isLoading = false }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 4. LEGACY QR SCANNER
// ═══════════════════════════════════════════════════════════════════════════════

struct DeliveryQRScanner: UIViewControllerRepresentable {
    let orderId: String; let onScan: (String) -> Void
    func makeUIViewController(context: Context) -> QRScannerVC { QRScannerVC(orderId: orderId, onScan: onScan) }
    func updateUIViewController(_ uiViewController: QRScannerVC, context: Context) {}
}

final class QRScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let orderId: String; private let onScan: (String) -> Void
    private let session = AVCaptureSession(); private var previewLayer: AVCaptureVideoPreviewLayer?; private var didScan = false
    init(orderId: String, onScan: @escaping (String) -> Void) { self.orderId = orderId; self.onScan = onScan; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = .black; configureSession() }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() } }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); session.stopRunning() }
    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output); output.setMetadataObjectsDelegate(self, queue: .main); output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill; preview.frame = view.bounds; view.layer.addSublayer(preview); previewLayer = preview
    }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan, let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let value = obj.stringValue else { return }
        didScan = true; session.stopRunning(); UINotificationFeedbackGenerator().notificationOccurred(.success); onScan(value)
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); previewLayer?.frame = view.bounds }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - 5. HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

enum DeliveryPhase { case goingToStore, goingToCustomer }

struct MKRouteHelper {
    struct RouteResult { let points: [CLLocationCoordinate2D]; let distance: Double; let expectedTime: TimeInterval }
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
            return RouteResult(points: coords, distance: route.distance, expectedTime: route.expectedTravelTime)
        } catch { return nil }
    }
}

extension ISO8601DateFormatter {
    static let deliveryFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
    }()
}
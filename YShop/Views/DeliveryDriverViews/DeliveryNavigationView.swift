// DeliveryNavigationView.swift
// ضع هذا الملف في: Views/DeliveryDriverViews/DeliveryNavigationView.swift
//
// هذا الـ View يعمل مستقل تماماً — يأخذ Order ويُعيد onComplete عند الانتهاء
// onComplete تُستدعى في حالتين:
//   1. الموصل يضغط "Back to Dashboard" بعد التوصيل
//   2. الموصل يضغط زر الرجوع (dismiss)

import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct DeliveryNavigationView: View {
    let order:      Order
    let onComplete: () -> Void
    let onPickupConfirmed: ((Order) -> Void)?
    let onDeliveredConfirmed: (() -> Void)?

    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL)  private var openURL

    // ─── Phase ──────────────────────────────────────────────────────────
    @State private var phase: DeliveryPhase

    // ─── Map ────────────────────────────────────────────────────────────
    @State private var mapPosition:    MapCameraPosition = .automatic
    @State private var routePoints:    [CLLocationCoordinate2D] = []
    @State private var traveledPoints: [CLLocationCoordinate2D] = []
    @State private var routeDistance:  Double = 0
    @State private var routeDuration:  Int    = 0
    @State private var heading:        Double = 0
    @State private var isFollowing     = false

    // ─── Auto-recenter ───────────────────────────────────────────────────
    @State private var lastInteraction: Date = .distantPast
    @State private var recenterTimer:   Timer?

    // ─── Card ────────────────────────────────────────────────────────────
    @State private var isCardCollapsed = false
    @State private var cardOffset:     CGFloat = 0
    private let collapsedOffset:       CGFloat = 90

    // ─── UI flags ────────────────────────────────────────────────────────
    @State private var showSatellite   = false
    @State private var isAtDest        = false
    @State private var isProcessing    = false
    @State private var showQRScanner   = false
    @State private var showSuccess     = false
    @State private var errorMessage:   String?
    @State private var customerInfoOrder: Order?

    // ─── Location sync ───────────────────────────────────────────────────
    @State private var lastSyncAt:    Date = .distantPast
    @State private var lastSyncCoord: CLLocationCoordinate2D?

    // ─── Timers ──────────────────────────────────────────────────────────
    @State private var headingTimer: Timer?

    // ─── Route refresh ───────────────────────────────────────────────────
    @State private var lastRouteAt:  Date = .distantPast

    // ────────────────────────────────────────────────────────────────────
    init(order: Order, onComplete: @escaping () -> Void, onPickupConfirmed: ((Order) -> Void)? = nil, onDeliveredConfirmed: (() -> Void)? = nil) {
        self.order      = order
        self.onComplete = onComplete
        self.onPickupConfirmed = onPickupConfirmed
        self.onDeliveredConfirmed = onDeliveredConfirmed
        _phase = State(initialValue:
            (order.pickedUpAt != nil || order.status == .outForDelivery)
                ? .goingToCustomer : .goingToStore
        )
    }

    // ────────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            topHeader
            VStack { Spacer(); draggableCard }
            if isProcessing {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView(orderId: order.id) { scanned in
                Task { await handleScan(scanned) }
            }
        }
        .alert("Delivery Complete! 🎉", isPresented: $showSuccess) {
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
            startHeadingTracking()
            // Haptic + ensure latest order data when this screen appears
            let h = UIImpactFeedbackGenerator(style: .light); h.impactOccurred()
            Task {
                if let updated = try? await DeliveryService.getActiveOrder(), updated.id == order.id {
                    await MainActor.run {
                        customerInfoOrder = updated
                        onPickupConfirmed?(updated)
                    }
                }
            }
        }
        .onDisappear {
            headingTimer?.invalidate()
            recenterTimer?.invalidate()
        }
        .onReceive(locationManager.$currentLocation) { coord in
            guard let coord else { return }
            traveledPoints.append(coord)
            checkProximity(to: coord)
            if isFollowing { updateCamera(to: coord) }
            Task { await syncLocation(coord) }
            if routePoints.isEmpty || Date().timeIntervalSince(lastRouteAt) > 10 {
                Task { await refreshRoute() }
            }
            if !isFollowing {
                isFollowing = true
                updateCamera(to: coord)
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = errorMessage {
                Text(msg).padding()
                    .background(DeliveryTheme.accentRed, in: Capsule())
                    .foregroundColor(.white)
                    .padding(.bottom, isCardCollapsed ? 80 : 340)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Map
    // ────────────────────────────────────────────────────────────────────
    private var mapLayer: some View {
        Map(position: $mapPosition) {
            // Store pin
            if let store = storeCoord {
                Annotation("Store", coordinate: store) {
                    pinView(color: phase == .goingToStore ? DeliveryTheme.accentOrange : .gray.opacity(0.5),
                            icon: "storefront.fill")
                }
            }
            // Customer pin
            if let customer = customerCoord {
                Annotation("Customer", coordinate: customer) {
                    pinView(color: phase == .goingToCustomer ? DeliveryTheme.accentGreen : .gray.opacity(0.5),
                            icon: "person.fill")
                }
            }
            // Driver arrow
            if let driver = locationManager.currentLocation {
                Annotation("You", coordinate: driver) { compassArrow }
            }
            // Traveled route (gray)
            if traveledPoints.count >= 2 {
                MapPolyline(coordinates: traveledPoints).stroke(.gray.opacity(0.5), lineWidth: 5)
            }
            // Remaining route (blue)
            if !routePoints.isEmpty {
                MapPolyline(coordinates: routePoints).stroke(DeliveryTheme.routeBlue, lineWidth: 5)
            }
        }
        .mapStyle(showSatellite ? .imagery(elevation: .flat) : .standard(elevation: .flat))
        .ignoresSafeArea()
        .simultaneousGesture(DragGesture().onChanged { _ in
            isFollowing = false
            recenterTimer?.invalidate()
            recenterTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                DispatchQueue.main.async {
                    isFollowing = true
                    if let loc = locationManager.currentLocation { updateCamera(to: loc) }
                }
            }
        })
    }

    private var compassArrow: some View {
        ZStack {
            Circle().fill(DeliveryTheme.accentBlue).frame(width: 48, height: 48)
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .shadow(color: DeliveryTheme.accentBlue.opacity(0.5), radius: 8)
            Image(systemName: "location.north.fill")
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
        }
    }

    private func pinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2)).shadow(radius: 4)
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Top Header
    // ────────────────────────────────────────────────────────────────────
    private var topHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(10)
                    .background(DeliveryTheme.cardBackground, in: Circle())
            }
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phase == .goingToStore ? "Pick up from" : "Deliver to")
                        .font(.system(size: 10)).foregroundColor(DeliveryTheme.secondaryText)
                    Text(destName)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 11))
                    Text(routeDuration > 0 ? "\(routeDuration)m" : "—")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(DeliveryTheme.accentBlue)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(DeliveryTheme.accentBlue.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(DeliveryTheme.cardBackground.opacity(0.95),
                        in: RoundedRectangle(cornerRadius: 14))

            Button { withAnimation { showSatellite.toggle() } } label: {
                Image(systemName: showSatellite ? "globe.americas.fill" : "map.fill")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(10)
                    .background(showSatellite ? DeliveryTheme.accentOrange : DeliveryTheme.accentGreen,
                                in: Circle())
            }
        }
        .padding(.horizontal, 16).padding(.top, 50)
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Draggable Card
    // ────────────────────────────────────────────────────────────────────
    private var draggableCard: some View {
        VStack(spacing: 0) {
            // Handle
            VStack(spacing: 5) {
                Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4).padding(.top, 10)
                HStack(spacing: 4) {
                    Image(systemName: isCardCollapsed ? "chevron.up" : "chevron.down").font(.system(size: 10))
                    Text(isCardCollapsed ? "Show details" : "Swipe down to focus").font(.system(size: 11))
                }
                .foregroundColor(DeliveryTheme.secondaryText).padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity).contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCardCollapsed.toggle()
                    cardOffset = isCardCollapsed ? collapsedOffset : 0
                    // Haptic feedback on tap toggle
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                }
            }

            if isCardCollapsed { miniCard } else { cardContent.transition(.opacity) }
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
                        cardOffset = max(0, min(collapsedOffset + drag, collapsedOffset))
                    } else {
                        cardOffset = min(max(0, drag), collapsedOffset)
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        let threshold: CGFloat = 50
                        let velocity = value.velocity.height
                        if (value.translation.height > threshold || velocity > 500) && !isCardCollapsed {
                            isCardCollapsed = true; cardOffset = collapsedOffset
                            // Haptic feedback for collapsing
                            let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred()
                        } else if (value.translation.height < -threshold || velocity < -500) && isCardCollapsed {
                            isCardCollapsed = false; cardOffset = 0
                            // Haptic feedback for expanding
                            let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred()
                        } else {
                            cardOffset = isCardCollapsed ? collapsedOffset : 0
                        }
                    }
                }
        )
    }

    // Full card content
    private var cardContent: some View {
        VStack(spacing: 14) {
            if phase == .goingToStore { orderInfoCard } else { customerInfoCard }

            // Phase dots
            HStack(spacing: 16) {
                phaseDot(icon: "storefront.fill", label: "Store",
                         isActive: phase == .goingToStore, isCompleted: phase != .goingToStore)
                Rectangle().fill(phase != .goingToStore ? DeliveryTheme.accentGreen : DeliveryTheme.separator)
                    .frame(width: 30, height: 2)
                phaseDot(icon: "person.fill", label: "Customer",
                         isActive: phase == .goingToCustomer, isCompleted: false)
            }

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 12))
                    Text(formatDist(routeDistance)).font(.system(size: 13))
                }
                .foregroundColor(DeliveryTheme.secondaryText)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "banknote.fill").foregroundColor(DeliveryTheme.accentOrange)
                    Text(String(format: "₺%.0f earnings", order.totalPrice * 0.10))
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(DeliveryTheme.accentOrange)
                }
            }.padding(.horizontal, 4)

            Button { Task { await performAction() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: actionIcon).font(.system(size: 18, weight: .bold))
                    Text(actionLabel).font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(actionColor, in: RoundedRectangle(cornerRadius: 14))
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
                Text(destName).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DeliveryTheme.primaryText)
                Text("\(formatDist(routeDistance)) • \(routeDuration > 0 ? "\(routeDuration)m" : "—")")
                    .font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Spacer()
            Button { Task { await performAction() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: actionIcon).font(.system(size: 13, weight: .bold))
                    Text(isAtDest ? (phase == .goingToStore ? "Scan" : "Deliver") : "Navigate")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                .background(actionColor, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14).padding(.bottom, 20)
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Info Cards
    // ────────────────────────────────────────────────────────────────────
    private var orderInfoCard: some View {
        let displayOrder = customerInfoOrder ?? order
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if let urlStr = displayOrder.storeIconFullUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        default:
                            storeIconPlaceholder
                        }
                    }
                } else { storeIconPlaceholder }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayOrder.storeName ?? "Store")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                    Text("Order #\(displayOrder.id)").font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "₺%.0f", displayOrder.totalPrice))
                        .font(.system(size: 16, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                    Text("\(displayOrder.items.count) items")
                        .font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
                }
            }
            Divider().background(DeliveryTheme.separator)
            if !displayOrder.items.isEmpty {
                ForEach(displayOrder.items.prefix(3)) { item in
                    HStack(spacing: 8) {
                        if let urlStr = item.fullImageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { p in
                                switch p {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                default:
                                    itemImagePlaceholder
                                }
                            }
                        } else { itemImagePlaceholder }
                        Text("×\(item.quantity)").font(.system(size: 12, weight: .bold))
                            .foregroundColor(DeliveryTheme.accentBlue).frame(width: 24)
                        Text(item.displayName).font(.system(size: 13))
                            .foregroundColor(DeliveryTheme.primaryText).lineLimit(1)
                        Spacer()
                        Text(String(format: "₺%.0f", item.price * Double(item.quantity)))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DeliveryTheme.secondaryText)
                    }
                }
                if displayOrder.items.count > 3 {
                    Text("+\(displayOrder.items.count - 3) more items")
                        .font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
                }
            }
            Divider().background(DeliveryTheme.separator)
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 13))
                    .foregroundColor(DeliveryTheme.accentRed)
                Text(displayOrder.shippingAddress ?? displayOrder.deliveryAddress ?? "Delivery address")
                    .font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText).lineLimit(2)
            }
        }
        .padding(14)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DeliveryTheme.separator, lineWidth: 0.5))
    }

    private var storeIconPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(DeliveryTheme.accentOrange.opacity(0.15))
                .frame(width: 44, height: 44)
            Image(systemName: "storefront.fill").font(.system(size: 18))
                .foregroundColor(DeliveryTheme.accentOrange)
        }
    }

    private var itemImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8).fill(DeliveryTheme.cardBackground).frame(width: 44, height: 44)
            .overlay(Image(systemName: "photo").foregroundColor(DeliveryTheme.secondaryText))
    }

    private var customerInfoCard: some View {
        let displayOrder = customerInfoOrder ?? order
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(DeliveryTheme.accentGreen.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "person.fill").font(.system(size: 18))
                        .foregroundColor(DeliveryTheme.accentGreen)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayOrder.customerName ?? "Customer")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                    Text(displayOrder.customerPhone ?? "—")
                        .font(.system(size: 12)).foregroundColor(DeliveryTheme.secondaryText)
                }
                Spacer()
                if let phone = displayOrder.customerPhone, !phone.isEmpty {
                    Button {
                        let cleaned = phone.replacingOccurrences(of: " ", with: "")
                                          .replacingOccurrences(of: "-", with: "")
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
                Image(systemName: "mappin.circle.fill").font(.system(size: 14))
                    .foregroundColor(DeliveryTheme.accentRed).frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Delivery Address").font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DeliveryTheme.secondaryText)
                    Text(displayOrder.shippingAddress ?? displayOrder.deliveryAddress ?? "—")
                        .font(.system(size: 13)).foregroundColor(DeliveryTheme.primaryText).lineLimit(3)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "bag.fill").font(.system(size: 14))
                    .foregroundColor(DeliveryTheme.accentBlue).frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order from \(displayOrder.storeName ?? "Store")")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
                    Text("\(displayOrder.items.count) items • ₺\(String(format: "%.0f", displayOrder.totalPrice))")
                        .font(.system(size: 13)).foregroundColor(DeliveryTheme.primaryText)
                }
            }
        }
        .padding(14)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DeliveryTheme.accentGreen.opacity(0.3), lineWidth: 1))
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Phase Dot
    // ────────────────────────────────────────────────────────────────────
    private func phaseDot(icon: String, label: String, isActive: Bool, isCompleted: Bool) -> some View {
        let color: Color = isCompleted ? DeliveryTheme.accentGreen
                         : isActive    ? DeliveryTheme.accentBlue
                         :               DeliveryTheme.separator
        return VStack(spacing: 4) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(color, lineWidth: 2))
                Image(systemName: isCompleted ? "checkmark" : icon)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(color)
            }
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(color)
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Action Properties
    // ────────────────────────────────────────────────────────────────────
    private var actionLabel: String {
        switch phase {
        case .goingToStore:    return isAtDest ? "Scan QR to Pickup" : "Drive to Store"
        case .goingToCustomer: return isAtDest ? "Mark Delivered"    : "Drive to Customer"
        }
    }
    private var actionIcon: String {
        switch phase {
        case .goingToStore:    return isAtDest ? "qrcode.viewfinder" : "car.fill"
        case .goingToCustomer: return isAtDest ? "checkmark.seal.fill" : "car.fill"
        }
    }
    private var actionColor: Color { isAtDest ? DeliveryTheme.accentGreen : DeliveryTheme.accentBlue }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Actions
    // ────────────────────────────────────────────────────────────────────
    private func performAction() async {
        switch phase {
        case .goingToStore:
            if isAtDest { showQRScanner = true } else { centerOnDriver() }
        case .goingToCustomer:
            if isAtDest { await markDelivered() } else { centerOnDriver() }
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
        isFollowing = true
    }

    private func handleScan(_ scanned: String) async {
        let normalized = scanned.trimmingCharacters(in: .whitespaces)
        let isMatch = normalized == order.id
            || normalized == "ORDER-\(order.id)"
            || normalized.contains(order.id)
            || (Int(normalized) != nil && Int(order.id) != nil && Int(normalized) == Int(order.id))

        guard isMatch else {
            await MainActor.run { errorMessage = "QR code doesn't match this order" }
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { errorMessage = nil }
            return
        }

        await MainActor.run { isProcessing = true }
        do {
            let updatedOrder = try await DeliveryService.pickupOrder(orderId: order.id)
            await MainActor.run {
                customerInfoOrder = updatedOrder
                showQRScanner = false
                phase = .goingToCustomer
                isAtDest = false
                isProcessing = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCardCollapsed = false; cardOffset = 0
                }
                onPickupConfirmed?(updatedOrder)
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
                showSuccess = true
                onDeliveredConfirmed?()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = "Delivery failed: \(error.localizedDescription)"
            }
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Navigation Helpers
    // ────────────────────────────────────────────────────────────────────
    private func checkProximity(to location: CLLocationCoordinate2D) {
        guard let target = phase == .goingToStore ? storeCoord : customerCoord else { return }
        let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
            .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
        withAnimation { isAtDest = distance <= 100 }
    }

    private func refreshRoute() async {
        guard let driver = locationManager.currentLocation,
              let target = phase == .goingToStore ? storeCoord : customerCoord else { return }
        lastRouteAt = Date()
        if let route = await MKRouteHelper.calculateRoute(from: driver, to: target) {
            await MainActor.run {
                routePoints  = route.points
                routeDistance = route.distance
                routeDuration = max(1, Int((route.expectedTime / 60).rounded()))
                if isFollowing { updateCamera(to: driver) }
            }
        }
    }

    private func updateCamera(to coord: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .camera(MapCamera(
                centerCoordinate: coord,
                distance: 500,
                heading: heading,
                pitch: 45
            ))
        }
    }

    private func startLocationTracking() {
        locationManager.startUpdatingLocation()
        if let coord = locationManager.currentLocation {
            Task { await syncLocation(coord, force: true) }
        }
    }

    private func startHeadingTracking() {
        headingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            guard let h = locationManager.heading else { return }
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.3)) { self.heading = h }
                if self.isFollowing, let loc = self.locationManager.currentLocation {
                    self.updateCamera(to: loc)
                }
            }
        }
    }

    private func syncLocation(_ location: CLLocationCoordinate2D, force: Bool = false) async {
        let now = Date()
        let shouldSync: Bool
        if force || lastSyncCoord == nil {
            shouldSync = true
        } else {
            let last    = CLLocation(latitude: lastSyncCoord!.latitude, longitude: lastSyncCoord!.longitude)
            let current = CLLocation(latitude: location.latitude,       longitude: location.longitude)
            shouldSync  = current.distance(from: last) >= 15 || now.timeIntervalSince(lastSyncAt) >= 12
        }
        guard shouldSync else { return }
        lastSyncCoord = location
        lastSyncAt    = now

        if phase == .goingToStore {
            _ = try? await DeliveryService.updateDriverLocation(latitude: location.latitude, longitude: location.longitude)
        } else {
            _ = try? await DeliveryService.updateDeliveryLocation(orderId: order.id, latitude: location.latitude, longitude: location.longitude)
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Computed
    // ────────────────────────────────────────────────────────────────────
    private var destName: String {
        phase == .goingToStore ? (order.storeName ?? "Store") : (order.customerName ?? "Customer")
    }
    private var storeCoord: CLLocationCoordinate2D? {
        guard let c = order.storeCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
    }
    private var customerCoord: CLLocationCoordinate2D? {
        guard let c = order.customerCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
    }
    private func formatDist(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.1fkm", meters / 1000)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - Delivery Phase
// ────────────────────────────────────────────────────────────────────────────
enum DeliveryPhase { case goingToStore, goingToCustomer }

// ────────────────────────────────────────────────────────────────────────────
// MARK: - Route Helper
// ────────────────────────────────────────────────────────────────────────────
struct MKRouteHelper {
    struct RouteResult {
        let points:       [CLLocationCoordinate2D]
        let distance:     Double
        let expectedTime: TimeInterval
    }
    static func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> RouteResult? {
        let request = MKDirections.Request()
        request.source      = MKMapItem(placemark: MKPlacemark(coordinate: from))
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

// ────────────────────────────────────────────────────────────────────────────
// MARK: - ISO8601 Extension
// ────────────────────────────────────────────────────────────────────────────
extension ISO8601DateFormatter {
    static let deliveryFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

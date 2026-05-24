import SwiftUI
import CoreLocation



// MARK: - Delivery Home View

struct DeliveryHomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var locationManager: LocationManager
    @AppStorage("deliveryActiveOrderId") private var storedActiveOrderId: String = ""

    @State private var driverProfile: DeliveryProfile?
    @State private var activeOrder: Order?
    @State private var journeyOrder: Order?
    @State private var pendingOffer: DeliveryOffer?
    @State private var isWorking = false
    @State private var isLoading = true
    @State private var isUpdatingWorking = false
    @State private var errorMessage: String?
    @State private var showProfileSheet = false
    @State private var showDashboard = false
    @State private var pulseAnimation = false

    @State private var locationUpdateTimer: Timer?
    @State private var offerPollingTimer: Timer?
    @State private var socketObserverId: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                DeliveryTheme.darkBackground.ignoresSafeArea()
                
                if isLoading && driverProfile == nil {
                    ProgressView()
                        .tint(DeliveryTheme.accentBlue)
                } else {
                    VStack(spacing: 0) {
                        workingToggle
                        Spacer()
                        mainContent
                        Spacer()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showDashboard = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(DeliveryTheme.accentBlue)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfileSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(DeliveryTheme.cardBackground)
                                .frame(width: 36, height: 36)
                            Text(driverInitial)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(DeliveryTheme.accentBlue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                profileSheet
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showDashboard) {
                DeliveryDashboardView()
            }
            .sheet(item: $pendingOffer) { offer in
                DeliveryOfferSheet(
                    offer: offer,
                    driverLocation: locationManager.currentLocation,
                    onAccept: { await acceptOffer(offer) },
                    onSkip: { await skipOffer(offer) },
                    onTimeout: { pendingOffer = nil }
                )
                .interactiveDismissDisabled(true)
                .presentationDetents([.large])
            }
            .fullScreenCover(item: $journeyOrder, onDismiss: {
                journeyOrder = nil
            }) { order in
                DeliveryNavigationView(order: order, onComplete: {
                    activeOrder = nil
                    journeyOrder = nil
                    Task { await loadDriverStatus() }
                }, onPickupConfirmed: { updatedOrder in
                    activeOrder = updatedOrder
                    journeyOrder = updatedOrder
                    storedActiveOrderId = updatedOrder.id
                }, onDeliveredConfirmed: {
                    // Stop observing the old order to avoid socket re-populating it
                    stopOrderSocketObserver()
                    activeOrder = nil
                    journeyOrder = nil
                    storedActiveOrderId = ""
                }
            )
        }
        
            .task {
                await loadDriverStatus()
            }
            .onChange(of: authManager.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    Task { await loadDriverStatus() }
                } else {
                    resetDeliverySessionState()
                }
            }
            .onDisappear {
                stopAllTracking()
            }
            .overlay(alignment: .bottom) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DeliveryTheme.accentRed, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Working Toggle

    private var workingToggle: some View {
        let isApproved = driverProfile?.isApproved ?? false

        return Button {
            Task { await toggleWorking() }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: isWorking ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isWorking ? "You are Online" : "You are Offline")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(isWorking ? "Receiving orders..." : "Go online to work")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isWorking },
                    set: { _ in Task { await toggleWorking() } }
                ))
                .labelsHidden()
                .tint(.white)
                .disabled(!isApproved || isUpdatingWorking)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isWorking
                        ? [Color(red: 0.0, green: 0.78, blue: 0.33), Color(red: 0.41, green: 0.94, blue: 0.68)]
                        : [Color(white: 0.25), Color(white: 0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: isWorking ? Color.green.opacity(0.3) : Color.black.opacity(0.2), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isApproved || isUpdatingWorking)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        let isApproved = driverProfile?.isApproved ?? false

        if !isApproved {
            emptyState(
                icon: "hourglass",
                title: "Pending Approval",
                message: "Your application is under review."
            )
        } else if !isWorking {
            emptyState(
                icon: "power",
                title: "You are Offline",
                message: "Go online to receive orders."
            )
        } else if let activeOrder {
            activeDeliveryCard(order: activeOrder)
        } else {
            waitingForOrders
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DeliveryTheme.cardBackground)
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(DeliveryTheme.secondaryText.opacity(0.6))
            }

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DeliveryTheme.primaryText)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(DeliveryTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var waitingForOrders: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DeliveryTheme.accentBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                Circle()
                    .strokeBorder(DeliveryTheme.accentBlue.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                Image(systemName: "bicycle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(DeliveryTheme.accentBlue)
            }
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            .onAppear { pulseAnimation = true }

            VStack(spacing: 6) {
                Text("Looking for orders nearby...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DeliveryTheme.primaryText)
                Text("Stay close to restaurants")
                    .font(.system(size: 13))
                    .foregroundColor(DeliveryTheme.secondaryText)
            }

            if locationManager.currentLocation != nil {
                HStack(spacing: 6) {
                    Circle()
                        .fill(DeliveryTheme.accentGreen)
                        .frame(width: 8, height: 8)
                    Text("GPS Active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DeliveryTheme.accentGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DeliveryTheme.cardBackground, in: Capsule())
            }
        }
    }

    private func activeDeliveryCard(order: Order) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Delivery")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DeliveryTheme.primaryText)
                    Text("You already accepted this order")
                        .font(.system(size: 13))
                        .foregroundColor(DeliveryTheme.secondaryText)
                }

                Spacer()

                Text(order.status.displayTitle)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DeliveryTheme.accentBlue.opacity(0.12), in: Capsule())
                    .foregroundColor(DeliveryTheme.accentBlue)
            }

            Text("New offers stay paused until this delivery is completed or cancelled.")
                .font(.system(size: 12))
                .foregroundColor(DeliveryTheme.secondaryText)

            profileRow(icon: "storefront", text: order.storeName ?? "Store")
            profileRow(icon: "person.fill", text: order.customerName ?? "Customer")
            profileRow(icon: "mappin.and.ellipse", text: order.shippingAddress ?? order.deliveryAddress ?? "Delivery address")

            Button {
                journeyOrder = order
            } label: {
                Text("Open Journey")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DeliveryTheme.accentBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Profile Sheet

    private var profileSheet: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            ZStack {
                Circle()
                    .fill(DeliveryTheme.accentBlue.opacity(0.2))
                    .frame(width: 80, height: 80)
                Text(driverInitial)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(DeliveryTheme.accentBlue)
            }

            VStack(spacing: 6) {
                Text(driverProfile?.name ?? "Driver")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DeliveryTheme.primaryText)

                if let status = driverProfile?.status {
                    Text(status.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            (driverProfile?.isApproved == true ? DeliveryTheme.accentGreen : DeliveryTheme.accentOrange).opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundColor(driverProfile?.isApproved == true ? DeliveryTheme.accentGreen : DeliveryTheme.accentOrange)
                }
            }

            VStack(spacing: 12) {
                profileRow(icon: "envelope", text: driverProfile?.email ?? "-")
                profileRow(icon: "phone", text: driverProfile?.phone ?? "-")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                Task {
                    stopAllTracking()
                    await MainActor.run {
                        resetDeliverySessionState()
                        authManager.logout()
                    }
                }
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DeliveryTheme.accentRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DeliveryTheme.accentRed.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(DeliveryTheme.darkBackground)
    }

    private func profileRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(DeliveryTheme.secondaryText)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(DeliveryTheme.primaryText)
            Spacer()
        }
    }

    private var driverInitial: String {
        let name = driverProfile?.name ?? authManager.currentUser?.name ?? "?"
        return name.first.map { String($0).uppercased() } ?? "?"
    }

    // MARK: - Actions

    private func loadDriverStatus() async {
        await MainActor.run {
            activeOrder = nil
            journeyOrder = nil
            pendingOffer = nil
        }

        do {
            let profile = try await DeliveryService.getDriverProfile()
            await MainActor.run {
                driverProfile = profile
                isWorking = profile.isWorking
                isLoading = false
            }

            await refreshActiveOrderState()

            if profile.isWorking && profile.isApproved {
                startLocationTracking()
                startOfferPolling()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func resetDeliverySessionState() {
        driverProfile = nil
        activeOrder = nil
        journeyOrder = nil
        pendingOffer = nil
        isWorking = false
        isLoading = true
        isUpdatingWorking = false
        errorMessage = nil
        showProfileSheet = false
        showDashboard = false
        storedActiveOrderId = ""
        stopAllTracking()
    }

    private func checkActiveOrder() async {
        await refreshActiveOrderState()
    }

    private func refreshActiveOrderState() async {
        do {
            print("🔍 Checking active order...")

            if !storedActiveOrderId.isEmpty {
                do {
                    let storedOrder = try await OrderService.getOrderDetail(id: storedActiveOrderId)
                    if storedOrder.status.isTrackable {
                        print("✅ Restored active order from stored id: \(storedOrder.id)")
                        await MainActor.run {
                            activeOrder = storedOrder
                            journeyOrder = storedOrder
                        }
                        startOrderSocketObserver(orderId: storedOrder.id)
                        return
                    }
                } catch {
                    print("⚠️ Stored active order restore failed: \(error)")
                }
            }

            let order = try await DeliveryService.getActiveOrder()
            if let order = order {
                print("✅ Active order found: \(order.id)")
                await MainActor.run {
                    activeOrder = order
                    journeyOrder = order
                    storedActiveOrderId = order.id
                }
                startOrderSocketObserver(orderId: order.id)
            } else {
                print("❌ Server returned nil")
                await MainActor.run {
                    activeOrder = nil
                    storedActiveOrderId = ""
                }
            }
        } catch {
            print("❌ Error: \(error)")
            await MainActor.run {
                activeOrder = nil
                storedActiveOrderId = ""
            }
        }
    }

    private func startOrderSocketObserver(orderId: String) {
        // امسح القديم أول
        stopOrderSocketObserver()
        
        if let token = authManager.token {
            SocketService.shared.connectIfNeeded(token: token)
        }
        
        socketObserverId = SocketService.shared.observeOrder(orderId: orderId) {
            Task {
                // جاء تحديث من الـ server — تحقق من الـ order من واجهة السائق
                if let updatedOrder = try? await DeliveryService.getActiveOrder(), updatedOrder.id == orderId {
                    await MainActor.run {
                        self.activeOrder = updatedOrder
                    }
                } else {
                    // لا يوجد طلب نشط أو طلب مختلف → اعتبره انتهى
                    await MainActor.run {
                        self.activeOrder = nil
                        self.journeyOrder = nil
                        self.storedActiveOrderId = ""
                        self.startOfferPolling()
                    }
                }
            }
        }
    }

private func stopOrderSocketObserver() {
    if let id = socketObserverId, let orderId = activeOrder?.id {
        SocketService.shared.removeObserver(orderId: orderId, observerId: id)
        socketObserverId = nil
    }
}

    private func toggleWorking() async {
        guard let profile = driverProfile, profile.isApproved, !isUpdatingWorking else { return }

        let newValue = !isWorking
        await MainActor.run {
            isUpdatingWorking = true
            errorMessage = nil
        }

        do {
            if newValue {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                }
                locationManager.startUpdatingLocation()
                if let coord = locationManager.currentLocation {
                    _ = try? await DeliveryService.updateDriverLocation(latitude: coord.latitude, longitude: coord.longitude)
                }
            } else {
                locationManager.stopUpdatingLocation()
            }

            _ = try await DeliveryService.toggleWorking(uid: profile.uid, isWorking: newValue)

            await MainActor.run {
                isWorking = newValue
                isUpdatingWorking = false
            }

            if newValue {
                startLocationTracking()
                startOfferPolling()
            } else {
                stopAllTracking()
            }
        } catch {
            await MainActor.run {
                isUpdatingWorking = false
                errorMessage = "Failed to update: \(error.localizedDescription)"
            }
        }
    }

    private func startLocationTracking() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            guard isWorking, let coord = locationManager.currentLocation else { return }
            Task {
                _ = try? await DeliveryService.updateDriverLocation(latitude: coord.latitude, longitude: coord.longitude)
            }
        }
    }

    private func startOfferPolling() {
        offerPollingTimer?.invalidate()
        Task { await checkForOffer() }
        offerPollingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { await checkForOffer() }
        }
    }

    private func checkForOffer() async {
        guard isWorking, activeOrder == nil, journeyOrder == nil, pendingOffer == nil,
              let coord = locationManager.currentLocation else { return }

        do {
            let offer = try await DeliveryService.getDeliveryOffer(
                latitude: coord.latitude,
                longitude: coord.longitude
            )
            await MainActor.run {
                pendingOffer = offer
            }
        } catch {
            // No offer available, that's fine
        }
    }

    private func acceptOffer(_ offer: DeliveryOffer) async {
        do {
            _ = try await DeliveryService.acceptDeliveryOffer(orderId: offer.orderId)
            let serverOrder = try? await DeliveryService.getActiveOrder()
            let resolverOrder = serverOrder ?? offer.order ?? buildOrderFromOffer(offer)

            await MainActor.run {
                pendingOffer = nil
                activeOrder = resolverOrder
                journeyOrder = resolverOrder
                storedActiveOrderId = resolverOrder?.id ?? offer.orderId
                offerPollingTimer?.invalidate()
            }

            // ابدأ مراقبة الـ order عبر Socket
            if let orderId = resolverOrder?.id {
                startOrderSocketObserver(orderId: orderId)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to accept: \(error.localizedDescription)"
            }
        }
    }

    private func buildOrderFromOffer(_ offer: DeliveryOffer) -> Order? {
        let json: [String: Any] = [
            "id": offer.orderId,
            "user_id": "",
            "store_id": offer.order?.storeId ?? "0",
            "items": [] as [[String: Any]],
            "total_price": offer.order?.totalPrice ?? offer.bidPrice,
            "status": "confirmed",
            "store_name": offer.order?.storeName ?? "Store",
            "shipping_address": offer.order?.shippingAddress ?? "",
            "store_latitude": offer.order?.storeLatitude ?? 0,
            "store_longitude": offer.order?.storeLongitude ?? 0,
            "location_Latitude": offer.order?.customerLatitude ?? 0,
            "location_Longitude": offer.order?.customerLongitude ?? 0
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let order = try? JSONDecoder().decode(Order.self, from: data) else { return nil }
        return order
    }

    private func skipOffer(_ offer: DeliveryOffer) async {
        do {
            _ = try await DeliveryService.skipDeliveryOffer(orderId: offer.orderId)
            await MainActor.run {
                pendingOffer = nil
            }
        } catch {
            await MainActor.run {
                pendingOffer = nil
            }
        }
    }

    private func stopAllTracking() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        offerPollingTimer?.invalidate()
        offerPollingTimer = nil
        stopOrderSocketObserver()
    }
}

#Preview {
    DeliveryHomeView()
        .environmentObject(AuthManager.shared)
        .environmentObject(LocationManager())
}


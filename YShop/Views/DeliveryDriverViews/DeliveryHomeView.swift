import SwiftUI
import CoreLocation

// MARK: - Brand Colors

enum DeliveryTheme {
    static let darkBackground = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let primaryText = Color(red: 0.93, green: 0.93, blue: 0.93)
    static let secondaryText = Color(red: 0.69, green: 0.69, blue: 0.69)
    static let accentBlue = Color(red: 0.16, green: 0.47, blue: 1.0)
    static let accentGreen = Color(red: 0.0, green: 0.90, blue: 0.46)
    static let accentRed = Color(red: 1.0, green: 0.32, blue: 0.32)
    static let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.0)
    static let separator = Color(red: 0.20, green: 0.20, blue: 0.20)
}

// MARK: - Delivery Home View

struct DeliveryHomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var locationManager: LocationManager

    @State private var driverProfile: DeliveryProfile?
    @State private var activeOrder: Order?
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
            }
            .fullScreenCover(item: $activeOrder) { order in
                DeliveryNavigationView(order: order) {
                    activeOrder = nil
                    Task { await loadDriverStatus() }
                }
            }
            .task {
                await loadDriverStatus()
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
        do {
            let profile = try await DeliveryService.getDriverProfile()
            await MainActor.run {
                driverProfile = profile
                isWorking = profile.isWorking
                isLoading = false
            }

            await checkActiveOrder()

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

    private func checkActiveOrder() async {
        do {
            let order = try await DeliveryService.getActiveOrder()
            // ✅ تأكد إن الطلب فعلاً موجود (id غير فاضي)
            await MainActor.run {
                if !order.id.isEmpty {
                    activeOrder = order
                } else {
                    activeOrder = nil
                }
            }
        } catch {
            // No active order — that's fine
            await MainActor.run {
                activeOrder = nil
            }
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
        guard isWorking, activeOrder == nil, pendingOffer == nil,
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
            let order = (try? await DeliveryService.getActiveOrder()) ?? offer.order ?? nil

            await MainActor.run {
                pendingOffer = nil
                activeOrder = order
                offerPollingTimer?.invalidate()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to accept: \(error.localizedDescription)"
            }
        }
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
    }
}

#Preview {
    DeliveryHomeView()
        .environmentObject(AuthManager.shared)
        .environmentObject(LocationManager())
}

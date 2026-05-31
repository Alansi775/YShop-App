import SwiftUI
import MapKit
import UIKit

// MARK: - Delivery Return View
// Driver sees pending return orders and handles pickup → store delivery

struct DeliveryReturnView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var returnOrders: [ReturnOrderItem] = []
    @State private var activeDriverReturn: ReturnOrderItem?
    @State private var driverProfile: DeliveryProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var activeReturn: ReturnOrderItem?
    @State private var showConfirmPickup = false
    @State private var showConfirmDelivery = false
    @State private var showReturnJourney = false
    @State private var isUpdating = false
    @State private var successMessage: String?
    @State private var isDriverWorking = false
    @State private var returnPollingTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                DeliveryTheme.darkBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(DeliveryTheme.accentBlue)
                } else if let errorMessage {
                    errorState(message: errorMessage)
                } else if !isDriverWorking {
                    inactiveState
                } else if returnOrders.isEmpty && activeReturn == nil && activeDriverReturn == nil {
                    emptyState
                } else {
                    returnList
                }
            }
            .navigationTitle("Return Pickups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(DeliveryTheme.accentBlue)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadDriverContext() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(DeliveryTheme.accentBlue)
                    }
                }
            }
        }
        .task { await loadDriverContext() }
        .onDisappear {
            returnPollingTimer?.invalidate()
            returnPollingTimer = nil
        }
        .confirmationDialog("Picked up from customer?", isPresented: $showConfirmPickup, titleVisibility: .visible) {
            Button("Yes, Picked Up") {
                Task { await confirmPickup() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Confirm you have collected the item from the customer.")
        }
        .confirmationDialog("Delivered to store?", isPresented: $showConfirmDelivery, titleVisibility: .visible) {
            Button("Yes, Delivered to Store") {
                Task { await confirmDeliveredToStore() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Confirm you have delivered the return item to the store.")
        }
        .alert("Done!", isPresented: Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })) {
            Button("OK") { successMessage = nil }
        } message: {
            Text(successMessage ?? "")
        }
        .sheet(isPresented: $showReturnJourney) {
            if let item = activeReturn {
                ReturnJourneyView(item: item) {
                    showReturnJourney = false
                    activeReturn = nil
                    Task {
                        if let driverUid = driverProfile?.uid {
                            await loadReturns(for: driverUid)
                        }
                    }
                }
            }
        }
    }

    // MARK: - List
    private var returnList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if let active = activeReturn ?? activeDriverReturn {
                    activeReturnCard(active)
                }

                ForEach(returnOrders) { item in
                    returnCard(item)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Active Return Card (driver is handling this)
    private func activeReturnCard(_ item: ReturnOrderItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(DeliveryTheme.accentOrange)
                    .font(.system(size: 18))
                Text("Active Return")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DeliveryTheme.accentOrange)
                Spacer()
                statusBadge(item.status)
            }

            returnDetails(item)

            // Navigation buttons
            HStack(spacing: 10) {
                if let lat = item.customerLatitude, let lon = item.customerLongitude {
                    navigationButton(
                        title: "Navigate to Customer",
                        icon: "location.fill",
                        color: DeliveryTheme.accentBlue,
                        lat: lat, lon: lon
                    )
                }
                if let lat = item.storeLatitude, let lon = item.storeLongitude {
                    navigationButton(
                        title: "Navigate to Store",
                        icon: "storefront.fill",
                        color: DeliveryTheme.accentGreen,
                        lat: lat, lon: lon
                    )
                }
            }

            Divider().background(DeliveryTheme.separator)

            HStack(spacing: 10) {
                Button {
                    showConfirmPickup = true
                } label: {
                    Label("Picked Up", systemImage: "hand.raised.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(DeliveryTheme.accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    showConfirmDelivery = true
                } label: {
                    Label("Store Received", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(DeliveryTheme.accentGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(DeliveryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DeliveryTheme.accentOrange.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Return Card (available)
    private func returnCard(_ item: ReturnOrderItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Return #\(item.id)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(DeliveryTheme.primaryText)
                    Text("Order #\(item.orderId)")
                        .font(.system(size: 12))
                        .foregroundColor(DeliveryTheme.secondaryText)
                }
                Spacer()
                statusBadge(item.status)
            }

            returnDetails(item)

            Button {
                activeReturn = item
                showReturnJourney = true
            } label: {
                Label("Accept Pickup", systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(DeliveryTheme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(DeliveryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DeliveryTheme.separator.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Shared Details
    private func returnDetails(_ item: ReturnOrderItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                productThumbnail(urlString: item.fullProductImageUrl)
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.productName ?? "Returned item")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DeliveryTheme.primaryText)
                        .lineLimit(2)

                    if let qty = item.quantity {
                        detailInline(icon: "number", value: "x\(qty)")
                    }

                    if let price = item.productPrice {
                        detailInline(icon: "tag.fill", value: "\(item.productCurrency ?? "") \(String(format: "%.0f", price))")
                    }
                }
            }

            if let name = item.customerName {
                detailRow(icon: "person.fill", label: "Customer", value: name)
            }
            if let address = item.customerAddress {
                detailRow(icon: "mappin.and.ellipse", label: "Address", value: address)
            }
            if let storeName = item.storeName {
                detailRow(icon: "storefront", label: "Store", value: storeName)
            }
            if let deliveredAt = item.deliveredAt {
                detailRow(icon: "clock.fill", label: "Delivered", value: deliveredAt)
            }
            if let requestedAt = item.returnRequestedAt {
                detailRow(icon: "calendar", label: "Returned", value: requestedAt)
            }
        }
    }

    private func productThumbnail(urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderThumb
                    }
                }
            } else {
                placeholderThumb
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholderThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DeliveryTheme.cardBackground)
            Image(systemName: "photo")
                .foregroundColor(DeliveryTheme.secondaryText)
        }
    }

    private func detailInline(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(DeliveryTheme.accentBlue)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DeliveryTheme.primaryText)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(DeliveryTheme.accentBlue)
                .frame(width: 16)
            Text(label + ":")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DeliveryTheme.secondaryText)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(DeliveryTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func navigationButton(title: String, icon: String, color: Color, lat: Double, lon: Double) -> some View {
        Button {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let placemark = MKPlacemark(coordinate: coord)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = title
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func statusBadge(_ status: String) -> some View {
        let color: Color = status == "pending" ? .orange : status == "picked_up" ? .blue : .green
        return Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.uturn.backward.circle")
                .font(.system(size: 52))
                .foregroundColor(DeliveryTheme.secondaryText)
            Text("No Return Pickups")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DeliveryTheme.primaryText)
            Text("There are no pending return orders to pick up.")
                .font(.system(size: 14))
                .foregroundColor(DeliveryTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var inactiveState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(DeliveryTheme.accentOrange)
            Text("You are offline")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DeliveryTheme.primaryText)
            Text("Go online to receive return pickups assigned to you.")
                .font(.system(size: 14))
                .foregroundColor(DeliveryTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(DeliveryTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") { Task { await loadDriverContext() } }
                .foregroundColor(DeliveryTheme.accentBlue)
        }
    }

    // MARK: - Actions
    private func loadDriverContext() async {
        isLoading = true
        errorMessage = nil
        do {
            let profile = try await DeliveryService.getDriverProfile()
            await MainActor.run {
                driverProfile = profile
                isDriverWorking = profile.isWorking && profile.isApproved
            }

            guard profile.isWorking && profile.isApproved else {
                await MainActor.run {
                    returnOrders = []
                    activeReturn = nil
                    activeDriverReturn = nil
                    isLoading = false
                }
                returnPollingTimer?.invalidate()
                returnPollingTimer = nil
                return
            }

            await loadReturns(for: profile.uid)
            startReturnPolling()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadReturns(for driverUid: String) async {
        do {
            let allReturns = try await ReturnService.getDriverPendingReturns()
            let available = allReturns.filter { item in
                item.driverId == driverUid
                && (item.adminAccepted ?? 1) == 1
                && (item.storeReceived ?? 0) == 0
                && (item.driverPickedUp ?? 0) == 0
            }
            let active = allReturns.first(where: { item in
                item.driverId == driverUid
                && (item.adminAccepted ?? 1) == 1
                && (item.storeReceived ?? 0) == 0
                && (item.driverPickedUp ?? 0) == 1
            })

            await MainActor.run {
                returnOrders = available.filter { $0.id != activeReturn?.id && $0.id != activeDriverReturn?.id }
                activeDriverReturn = active
                if activeReturn == nil {
                    activeReturn = active
                }
                isDriverWorking = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startReturnPolling() {
        returnPollingTimer?.invalidate()
        returnPollingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task {
                guard let driverUid = driverProfile?.uid, isDriverWorking else { return }
                await loadReturns(for: driverUid)
            }
        }
    }

    private func confirmPickup() async {
        guard let active = activeReturn else { return }
        isUpdating = true
        do {
            try await ReturnService.markDriverPickedUp(returnId: String(active.id))
            await MainActor.run {
                activeDriverReturn = active
                returnOrders.removeAll { $0.id == active.id }
                successMessage = "Pickup confirmed. Now deliver to the store."
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
                showConfirmPickup = false
            }
        } catch {
            successMessage = "Pickup marked. Please deliver to store."
        }
        isUpdating = false
    }

    private func confirmDeliveredToStore() async {
        guard let active = activeReturn else { return }
        isUpdating = true
        do {
            try await ReturnService.markStoreReceived(returnId: String(active.id))
            await MainActor.run {
                successMessage = "Return delivered to store successfully!"
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
                activeReturn = nil
                activeDriverReturn = nil
                returnOrders.removeAll { $0.id == active.id }
                showConfirmDelivery = false
            }
            if let driverUid = driverProfile?.uid {
                await loadReturns(for: driverUid)
            }
        } catch {
            errorMessage = "Failed to confirm delivery: \(error.localizedDescription)"
        }
        isUpdating = false
    }
}

#Preview {
    DeliveryReturnView()
}

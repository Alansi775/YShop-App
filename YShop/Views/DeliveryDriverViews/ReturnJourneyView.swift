import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct ReturnJourneyView: View {
    let item: ReturnOrderItem
    let onComplete: () -> Void

    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var phase: ReturnJourneyPhase
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var routePoints: [CLLocationCoordinate2D] = []
    @State private var traveledPoints: [CLLocationCoordinate2D] = []
    @State private var isFollowing = false
    @State private var isAtDestination = false
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var heading: Double = 0
    @State private var headingTimer: Timer?
    @State private var recenterTimer: Timer?
    @State private var routeTimer: Timer?
    @State private var lastRouteAt: Date = .distantPast

    init(item: ReturnOrderItem, onComplete: @escaping () -> Void) {
        self.item = item
        self.onComplete = onComplete
        _phase = State(initialValue: .goingToCustomer)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            topHeader
            VStack { Spacer(); bottomCard }
            if isProcessing {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            startTracking()
            refreshRoute()
        }
        .onDisappear {
            headingTimer?.invalidate()
            recenterTimer?.invalidate()
            routeTimer?.invalidate()
        }
        .onReceive(locationManager.$currentLocation) { coord in
            guard let coord else { return }
            traveledPoints.append(coord)
            checkProximity(to: coord)
            if isFollowing { updateCamera(to: coord) }
            if !isFollowing {
                isFollowing = true
                updateCamera(to: coord)
            }
            if routePoints.isEmpty || Date().timeIntervalSince(lastRouteAt) > 10 {
                refreshRoute()
            }
        }
        .alert("Return Complete", isPresented: $showSuccess) {
            Button("Back") {
                onComplete()
                dismiss()
            }
        } message: {
            Text("The return has been delivered to the store successfully.")
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
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $mapPosition) {
            if let customer = customerCoord {
                Annotation("Customer", coordinate: customer) {
                    pinView(color: DeliveryTheme.accentOrange, icon: "person.fill")
                }
            }
            if let store = storeCoord {
                Annotation("Store", coordinate: store) {
                    pinView(color: DeliveryTheme.accentGreen, icon: "storefront.fill")
                }
            }
            if let driver = locationManager.currentLocation {
                Annotation("You", coordinate: driver) { compassArrow }
            }
            if traveledPoints.count >= 2 {
                MapPolyline(coordinates: traveledPoints).stroke(.gray.opacity(0.5), lineWidth: 5)
            }
            if !routePoints.isEmpty {
                MapPolyline(coordinates: routePoints).stroke(phase == .goingToCustomer ? DeliveryTheme.routeBlue : DeliveryTheme.accentGreen, lineWidth: 5)
            }
        }
        .mapStyle(.standard(elevation: .flat))
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

    private var topHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(DeliveryTheme.cardBackground, in: Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(phase == .goingToCustomer ? "Return to Customer" : "Deliver to Store")
                    .font(.system(size: 10))
                    .foregroundColor(DeliveryTheme.secondaryText)
                Text(item.productName ?? "Returned item")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DeliveryTheme.primaryText)
                    .lineLimit(1)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(phase == .goingToCustomer ? "Customer" : "Store")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(DeliveryTheme.accentBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DeliveryTheme.accentBlue.opacity(0.15), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                productThumbnail
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.customerName ?? "Customer")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(DeliveryTheme.primaryText)
                    Text(item.storeName ?? "Store")
                        .font(.system(size: 12))
                        .foregroundColor(DeliveryTheme.secondaryText)
                }
                Spacer()
                Text(item.status.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DeliveryTheme.accentOrange.opacity(0.12), in: Capsule())
                    .foregroundColor(DeliveryTheme.accentOrange)
            }

            Text(item.productDescription ?? "Take the return item to the next stop.")
                .font(.system(size: 12))
                .foregroundColor(DeliveryTheme.secondaryText)
                .lineLimit(2)

            HStack(spacing: 10) {
                Button {
                    if isAtDestination {
                        Task { await performPrimaryAction() }
                    } else {
                        centerOnDriver()
                    }
                } label: {
                    Text(primaryButtonTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(primaryButtonColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var primaryButtonTitle: String {
        switch phase {
        case .goingToCustomer:
            return isAtDestination ? "Pick Up" : "Drive to Customer"
        case .goingToStore:
            return isAtDestination ? "Store Received" : "Drive to Store"
        }
    }

    private var primaryButtonColor: Color {
        switch phase {
        case .goingToCustomer:
            return isAtDestination ? DeliveryTheme.accentOrange : DeliveryTheme.accentBlue
        case .goingToStore:
            return isAtDestination ? DeliveryTheme.accentGreen : DeliveryTheme.accentBlue
        }
    }

    private var productThumbnail: some View {
        Group {
            if let urlString = item.fullProductImageUrl, let url = URL(string: urlString) {
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
                .fill(DeliveryTheme.darkBackground)
            Image(systemName: "photo")
                .foregroundColor(DeliveryTheme.secondaryText)
        }
    }

    private var customerCoord: CLLocationCoordinate2D? {
        guard let lat = item.customerLatitude, let lon = item.customerLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var storeCoord: CLLocationCoordinate2D? {
        guard let lat = item.storeLatitude, let lon = item.storeLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func pinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2)).shadow(radius: 4)
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
        }
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

    private func startTracking() {
        locationManager.startUpdatingLocation()
        if let loc = locationManager.currentLocation {
            updateCamera(to: loc)
        }
        headingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let h = locationManager.heading else { return }
            DispatchQueue.main.async {
                self.heading = h
            }
        }
    }

    private func checkProximity(to location: CLLocationCoordinate2D) {
        let target = phase == .goingToCustomer ? customerCoord : storeCoord
        guard let target else { return }
        let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
            .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
        isAtDestination = distance <= 100
    }

    private func centerOnDriver() {
        guard let loc = locationManager.currentLocation else { return }
        updateCamera(to: loc)
        isFollowing = true
    }

    private func updateCamera(to coord: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .camera(MapCamera(centerCoordinate: coord, distance: 500, heading: heading, pitch: 45))
        }
    }

    private func refreshRoute() {
        guard let driver = locationManager.currentLocation else { return }
        lastRouteAt = Date()
        let target = phase == .goingToCustomer ? customerCoord : storeCoord
        guard let target else { return }

        Task {
            if let route = await MKRouteHelper.calculateRoute(from: driver, to: target) {
                await MainActor.run {
                    routePoints = route.points
                    if isFollowing { updateCamera(to: driver) }
                }
            }
        }
    }

    private func performPrimaryAction() async {
        guard isAtDestination else { return }
        await MainActor.run { isProcessing = true }
        do {
            switch phase {
            case .goingToCustomer:
                try await ReturnService.markDriverPickedUp(returnId: String(item.id))
                await MainActor.run {
                    phase = .goingToStore
                    routePoints = []
                    traveledPoints = []
                    isAtDestination = false
                    isProcessing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                refreshRoute()
            case .goingToStore:
                try await ReturnService.markStoreReceived(returnId: String(item.id))
                await MainActor.run {
                    showSuccess = true
                    isProcessing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

private enum ReturnJourneyPhase {
    case goingToCustomer
    case goingToStore
}

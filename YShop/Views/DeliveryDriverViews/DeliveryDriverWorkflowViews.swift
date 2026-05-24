// DeliveryDriverWorkflowViews.swift
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
            infoChip(icon: "dollarsign.circle.fill", value: String(format: "$%.2f", offer.order?.totalPrice ?? 0.0), label: "Order")
            infoChip(icon: "point.topleft.down.curvedto.point.bottomright.up.fill", value: formattedDistance, label: "Distance")
            infoChip(icon: "banknote.fill", value: String(format: "$%.2f", Double(offer.bidPrice)), label: "Your Earn")
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


private struct DashboardSummary {
    let grossCollected: Double
    let driverEarnings: Double
    let cashToTransfer: Double
    let onlineCollected: Double
    let cashOrders: Int
    let onlineOrders: Int
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



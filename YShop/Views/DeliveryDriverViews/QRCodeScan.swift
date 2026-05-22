import SwiftUI
import AVFoundation
import UIKit

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - QR Scanner View (SwiftUI Wrapper)
// ═══════════════════════════════════════════════════════════════════════════════

struct QRScannerView: View {
    let orderId: String
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isFlashOn = false
    @State private var scanResult: ScanResult = .scanning
    @State private var animationOffset: CGFloat = -140
    @State private var pulseScale: CGFloat = 1.0

    enum ScanResult {
        case scanning
        case success(String)
        case error(String)
    }

    var body: some View {
        ZStack {
            // Camera layer
            QRCameraView(
                orderId: orderId,
                isFlashOn: $isFlashOn,
                onSuccess: { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        scanResult = .success(value)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        onScan(value)
                        dismiss()
                    }
                },
                onError: { message in
                    withAnimation {
                        scanResult = .error(message)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { scanResult = .scanning }
                    }
                }
            )
            .ignoresSafeArea()

            // Overlay
            overlayView
        }
        .navigationBarHidden(true)
        .onAppear {
            startScanAnimation()
        }
    }

    // MARK: - Overlay

    private var overlayView: some View {
        ZStack {
            // Dark overlay with cutout
            QROverlayShape(cutoutSize: 260)
                .fill(Color.black.opacity(0.65))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // Scanner frame
                scannerFrame
                    .frame(width: 260, height: 260)

                Spacer()

                // Bottom card
                bottomCard
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Text("Scan QR Code")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button {
                isFlashOn.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isFlashOn ? .black : .white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Scanner Frame

    private var scannerFrame: some View {
        ZStack {
            // Corner brackets
            QRCornerBrackets(size: 260, cornerLength: 36, lineWidth: 4, color: cornerColor)

            // Scan line animation
            if case .scanning = scanResult {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, DeliveryTheme.routeBlue.opacity(0.8), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 230, height: 2.5)
                    .offset(y: animationOffset)
                    .shadow(color: DeliveryTheme.routeBlue.opacity(0.6), radius: 6)
            }

            // Success overlay
            if case .success = scanResult {
                successOverlay
            }

            // Error overlay
            if case .error(let msg) = scanResult {
                errorOverlay(message: msg)
            }
        }
    }

    private var cornerColor: Color {
        switch scanResult {
        case .scanning: return .white
        case .success: return DeliveryTheme.accentGreen
        case .error: return DeliveryTheme.accentRed
        }
    }

    private var successOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(DeliveryTheme.accentGreen.opacity(0.15))
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundColor(DeliveryTheme.accentGreen)
                    .scaleEffect(pulseScale)
                Text("QR Verified!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
            }
        }
    }

    private func errorOverlay(message: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(DeliveryTheme.accentRed.opacity(0.15))
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(DeliveryTheme.accentRed)
                Text("Wrong QR Code")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Bottom Card

    private var bottomCard: some View {
        VStack(spacing: 20) {
            // Order info
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DeliveryTheme.accentBlue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "qrcode")
                        .font(.system(size: 20))
                        .foregroundColor(DeliveryTheme.accentBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Scan Store QR Code")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Point camera at the QR code shown by the store")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(.white.opacity(0.12))

            // Order ID chip
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DeliveryTheme.accentBlue)
                Text("Order #\(orderId)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                statusBadge
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    private var statusBadge: some View {
        Group {
            switch scanResult {
            case .scanning:
                HStack(spacing: 5) {
                    Circle()
                        .fill(DeliveryTheme.accentGreen)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseScale)
                    Text("Scanning")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DeliveryTheme.accentGreen)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(DeliveryTheme.accentGreen.opacity(0.12), in: Capsule())

            case .success:
                Label("Matched", systemImage: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DeliveryTheme.accentGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DeliveryTheme.accentGreen.opacity(0.12), in: Capsule())

            case .error:
                Label("No Match", systemImage: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DeliveryTheme.accentRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DeliveryTheme.accentRed.opacity(0.12), in: Capsule())
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }

    // MARK: - Animation

    private func startScanAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 140
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Camera UIViewControllerRepresentable
// ═══════════════════════════════════════════════════════════════════════════════

struct QRCameraView: UIViewControllerRepresentable {
    let orderId: String
    @Binding var isFlashOn: Bool
    let onSuccess: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> QRCameraVC {
        QRCameraVC(orderId: orderId, onSuccess: onSuccess, onError: onError)
    }

    func updateUIViewController(_ vc: QRCameraVC, context: Context) {
        vc.setFlash(isFlashOn)
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Camera ViewController
// ═══════════════════════════════════════════════════════════════════════════════

final class QRCameraVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let orderId: String
    private let onSuccess: (String) -> Void
    private let onError: (String) -> Void

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var device: AVCaptureDevice?
    private var didScan = false

    init(orderId: String,
         onSuccess: @escaping (String) -> Void,
         onError: @escaping (String) -> Void) {
        self.orderId = orderId
        self.onSuccess = onSuccess
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        self.device = device
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
    }

    func setFlash(_ on: Bool) {
        guard let device, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !didScan,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }

        let isMatch = value == orderId
                   || value == "ORDER-\(orderId)"
                   || value.contains(orderId)
                   || (Int(value) != nil && Int(orderId) != nil && Int(value) == Int(orderId))

        if isMatch {
            didScan = true
            session.stopRunning()
            onSuccess(value)
        } else {
            onError("QR code doesn't match order #\(orderId)")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - QR Overlay Cutout Shape
// ═══════════════════════════════════════════════════════════════════════════════

struct QROverlayShape: Shape {
    let cutoutSize: CGFloat

    func path(in rect: CGRect) -> Path {
        let cutout = CGRect(
            x: rect.midX - cutoutSize / 2,
            y: rect.midY - cutoutSize / 2,
            width: cutoutSize,
            height: cutoutSize
        )
        var path = Path(rect)
        path.addRoundedRect(in: cutout, cornerSize: CGSize(width: 20, height: 20))
        return path
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Corner Brackets View
// ═══════════════════════════════════════════════════════════════════════════════

struct QRCornerBrackets: View {
    let size: CGFloat
    let cornerLength: CGFloat
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Top-left
            bracket(rotation: 0)
            // Top-right
            bracket(rotation: 90)
            // Bottom-right
            bracket(rotation: 180)
            // Bottom-left
            bracket(rotation: 270)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.3), value: color)
    }

    private func bracket(rotation: Double) -> some View {
        BracketShape(cornerLength: cornerLength, lineWidth: lineWidth)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
    }
}

struct BracketShape: Shape {
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = lineWidth / 2
        let x = rect.minX + inset
        let y = rect.minY + inset
        let l = cornerLength

        // Top-left corner only
        path.move(to: CGPoint(x: x, y: y + l))
        path.addLine(to: CGPoint(x: x, y: y + 12))
        path.addQuadCurve(
            to: CGPoint(x: x + 12, y: y),
            control: CGPoint(x: x, y: y)
        )
        path.addLine(to: CGPoint(x: x + l, y: y))
        return path
    }
}

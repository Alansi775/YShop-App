import SwiftUI

struct AIShoppingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var manager = AIConversationManager.shared
    @StateObject private var tts     = TTSService.shared

    @State private var inputText = ""
    @State private var navTarget: AINavTarget?
    @State private var isLoadingDetail = false
    @State private var showCartToast = false
    @FocusState private var isTextFocused: Bool

    private var userId: String { authManager.currentUser?.id ?? "guest" }

    // MARK: - Adaptive Colors

    private var bgColor: Color          { Color(UIColor.systemBackground) }
    private var labelColor: Color       { Color(UIColor.label) }
    private var secondaryColor: Color   { Color(UIColor.secondaryLabel) }
    private var surfaceColor: Color     { Color(UIColor.secondarySystemBackground) }
    private var separatorColor: Color   { Color(UIColor.separator) }
    private var accentBlue: Color       { Color(red: 0.24, green: 0.56, blue: 0.96) }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor
                    .ignoresSafeArea()
                    .onTapGesture { isTextFocused = false }

                VStack(spacing: 0) {
                    topBar
                    Divider()
                    Spacer(minLength: 0)
                    centerStage
                        .animation(.easeInOut(duration: 0.35), value: manager.phase)
                    Spacer(minLength: 0)
                    if case .results = manager.phase, !manager.products.isEmpty {
                        productStrip
                        Divider()
                    }
                    bottomBar
                }
                .allowsHitTesting(true)

                if isLoadingDetail {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView().tint(.white).scaleEffect(1.3)
                }

                // Cart toast
                if showCartToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Added to cart").font(.system(size: 14, weight: .medium))
                                .foregroundColor(labelColor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            .navigationDestination(item: $navTarget) { target in
                ProductDetailView(product: target.product, store: target.store)
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
        }
        .onDisappear { manager.reset() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(secondaryColor)
                    .frame(width: 36, height: 36)
                    .background(surfaceColor, in: Circle())
            }
            Spacer()
            phaseChip
            Spacer()
            Button(action: { manager.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(secondaryColor)
                    .frame(width: 36, height: 36)
                    .background(surfaceColor, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var phaseChip: some View {
        HStack(spacing: 6) {
            Circle().fill(phaseColor).frame(width: 6, height: 6)
            Text(phaseTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(surfaceColor, in: Capsule())
    }

    // MARK: - Center Stage

    @ViewBuilder
    private var centerStage: some View {
        switch manager.phase {
        case .welcome:
            welcomeView
        case .listening:
            listeningView
        case .thinking:
            thinkingView
        case .results(let message):
            responseView(message: message)
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 32) {
            // Y monogram — same as HomeView AI bar
            Text("Y")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.white.opacity(0.13)))
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1.5))

            VStack(spacing: 8) {
                Text("YShop AI")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(labelColor)
                Text("What can I help you find?")
                    .font(.system(size: 15))
                    .foregroundColor(secondaryColor)
            }

            VStack(spacing: 10) {
                ForEach(quickPrompts, id: \.self) { p in
                    Button(action: { sendText(p) }) {
                        Text(p)
                            .font(.system(size: 14))
                            .foregroundColor(accentBlue)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(accentBlue.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    private var listeningView: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(accentBlue.opacity(0.12 - Double(i) * 0.03), lineWidth: 1.5)
                        .frame(width: CGFloat(76 + i * 34), height: CGFloat(76 + i * 34))
                        .scaleEffect(manager.isListening ? 1.08 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(Double(i) * 0.25),
                            value: manager.isListening
                        )
                }
                Circle()
                    .fill(accentBlue.opacity(0.1))
                    .frame(width: 76, height: 76)
                Image(systemName: "waveform")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(accentBlue)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: true)
            }

            VStack(spacing: 6) {
                Text(manager.transcript.isEmpty ? "Listening..." : manager.transcript)
                    .font(.system(size: manager.transcript.isEmpty ? 15 : 17))
                    .foregroundColor(manager.transcript.isEmpty ? secondaryColor : labelColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.15), value: manager.transcript)

                if !manager.transcript.isEmpty {
                    Text("Sends automatically after silence")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var thinkingView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(accentBlue.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(manager.phase == .thinking ? 1.4 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: manager.phase == .thinking
                        )
                }
            }
            Text("Thinking...")
                .font(.system(size: 14))
                .foregroundColor(secondaryColor)
        }
    }

    private func responseView(message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(8)
                .padding(.horizontal, 32)

            Button(action: { Task { await manager.replayResponse() } }) {
                HStack(spacing: 6) {
                    Image(systemName: tts.isPlaying ? "stop.circle" : "speaker.wave.2")
                        .font(.system(size: 13))
                    Text(tts.isPlaying ? "Stop" : "Play")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(accentBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(accentBlue.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Products

    private var productStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(manager.products.enumerated()), id: \.offset) { _, p in
                    AIProductCard(
                        product: p,
                        onAddToCart: { addToCart(p) },
                        onTap: { openDetail(p) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("Y")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(accentBlue.opacity(0.8)))
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))

                TextField(
                    manager.isListening ? "Listening..." : "Ask me anything...",
                    text: $inputText
                )
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(labelColor)
                .submitLabel(.send)
                .focused($isTextFocused)
                .onSubmit { sendText(inputText) }

                if !inputText.isEmpty {
                    Button(action: { inputText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(secondaryColor)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(surfaceColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button(action: {
                isTextFocused = false
                Task { await manager.toggleVoice() }
            }) {
                Image(systemName: manager.isListening ? "stop.fill" : "mic")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(manager.isListening ? .red : secondaryColor)
                    .frame(width: 44, height: 44)
                    .background(
                        manager.isListening
                            ? Color.red.opacity(0.1)
                            : surfaceColor,
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)

            // Persistent replay button — visible whenever there's a response to replay
            if manager.lastAIMessage != nil && !manager.isListening {
                Button(action: {
                    isTextFocused = false
                    Task {
                        if tts.isPlaying { tts.stop() }
                        else { await manager.replayResponse() }
                    }
                }) {
                    Image(systemName: tts.isPlaying ? "stop.circle.fill" : "speaker.wave.2")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(tts.isPlaying ? accentBlue : secondaryColor)
                        .frame(width: 44, height: 44)
                        .background(
                            tts.isPlaying ? accentBlue.opacity(0.1) : surfaceColor,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: { sendText(inputText) }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 44, height: 44)
                        .background(labelColor, in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .padding(.bottom, 4)
        .animation(.spring(duration: 0.2), value: inputText.isEmpty)
    }

    // MARK: - Computed

    private var phaseTitle: String {
        switch manager.phase {
        case .welcome:   return "YShop AI"
        case .listening: return "Listening"
        case .thinking:  return "Thinking"
        case .results:   return tts.isPlaying ? "Speaking" : "YShop AI"
        }
    }

    private var phaseColor: Color {
        switch manager.phase {
        case .listening: return .green
        case .thinking:  return .orange
        case .results:   return tts.isPlaying ? accentBlue : separatorColor
        default:         return separatorColor
        }
    }

    private let quickPrompts = [
        "Show me fresh fruits and vegetables",
        "I need a gift under 500 TL",
        "What's trending today?",
    ]

    // MARK: - Actions

    private func sendText(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        inputText = ""
        isTextFocused = false
        Task { await manager.sendText(t, userId: userId) }
    }

    private func addToCart(_ product: [String: Any]) {
        guard let parsed = parseProduct(product) else { return }
        manager.trackAddToCart(product: product)
        Task {
            try? await cartManager.addToCart(product: parsed, quantity: 1)
            withAnimation(.spring(duration: 0.3)) { showCartToast = true }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.25)) { showCartToast = false }
        }
    }

    private func openDetail(_ product: [String: Any]) {
        guard let productId = product["id"] as? Int else { return }
        isLoadingDetail = true
        Task {
            do {
                // AI response omits store_id — fetch full product to get it
                let full = try await fetchProduct(id: productId)
                let storeId = String(full.store_id)
                guard storeId != "0" else { isLoadingDetail = false; return }
                let store = try await StoreService.getStoreDetail(id: storeId)
                navTarget = AINavTarget(product: full, store: store)
            } catch {}
            isLoadingDetail = false
        }
    }

    private func fetchProduct(id: Int) async throws -> Product {
        // Try wrapped response first, then direct decode
        do {
            let resp: APIResponse<Product> = try await APIClient.shared.request(.productDetail(String(id)))
            return resp.data
        } catch {
            return try await APIClient.shared.request(.productDetail(String(id)))
        }
    }

    private func parseProduct(_ dict: [String: Any]) -> Product? {
        guard let id = dict["id"] as? Int else { return nil }
        let price = dict["price"] as? Double ?? Double(dict["price"] as? String ?? "0") ?? 0
        let rawImg = ["image_url", "imageUrl", "image", "thumbnail"]
            .compactMap { dict[$0] as? String }
            .first { !$0.isEmpty }
        let resolvedImg: String? = rawImg.map { $0.hasPrefix("http") ? $0 : "\(AppConstants.mediaBaseURL)\($0)" }
        return Product(
            id: id,
            name:          dict["name"]        as? String ?? "Product",
            description:   dict["description"] as? String,
            price:         String(format: "%.2f", price),
            currency:      dict["currency"]    as? String,
            image_url:     resolvedImg,
            imageURLs:     nil,
            category_id:   dict["category_id"] as? Int ?? 0,
            store_id:      dict["store_id"]    as? Int ?? 0,
            stock:         dict["stock"]       as? Int ?? 99,
            status:        dict["status"]      as? String ?? "approved",
            is_active:     1,
            created_at:    nil, updated_at: nil,
            store_name:    dict["store_name"]  as? String,
            store_phone:   nil, owner_email: nil, owner_uid: nil,
            category_name: dict["store_type"]  as? String
        )
    }
}

// MARK: - Navigation Target

struct AINavTarget: Identifiable, Hashable {
    let id      = UUID()
    let product: Product
    let store:   Store

    static func == (lhs: AINavTarget, rhs: AINavTarget) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

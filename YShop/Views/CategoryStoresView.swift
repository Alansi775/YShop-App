import SwiftUI

// MARK: - Custom Liquid Glass Back Button (Circular - Apple style)
struct LiquidGlassBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .foregroundColor(colorScheme == .dark ? .white : .black)
        .background(
            ZStack {
                // Frosted Glass Effect - Perfect Circle
                BlurView(style: colorScheme == .dark ? .dark : .extraLight)
                    .clipShape(Circle())
                
                // Add subtle border for native feel
                Circle()
                    .stroke(
                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                        lineWidth: 0.5
                    )
            }
        )
        .clipShape(Circle())
    }
}

// MARK: - Blur Effect View (Liquid Glass)
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CategoryStoresView: View {
    let categoryName: String
    @State private var stores: [Store] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @StateObject private var updateService = StoreUpdateService()
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Modern Adaptive Background - Light/Dark Mode Support
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.12)
                ] : [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.95, green: 0.95, blue: 0.97)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Elegant Header with Back Button (Liquid Glass)
                VStack(spacing: 16) {
                    HStack {
                        LiquidGlassBackButton()
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 44)

                    // Large Title with Category Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text(categoryName)
                            .font(.system(size: 42, weight: .light))
                            .tracking(0.5)
                            .foregroundColor(colorScheme == .dark ? .white : .black)

                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("\(stores.count) locations available")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)

                // Content
                if isLoading {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(colorScheme == .dark ? .white : .black)
                                .tint(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                .scaleEffect(1.2)
                            Text("Loading stores...")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red.opacity(0.7))
                            Text("Oops!")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        Spacer()
                    }
                } else if stores.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "storefront.circle")
                                .font(.system(size: 56))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No Stores")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text("No \(categoryName.lowercased()) stores available yet")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                } else {
                    // Grid Layout - Modern Luxury Style
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
                            ],
                            spacing: 20
                        ) {
                            ForEach(stores) { store in
                                NavigationLink(destination: StoreDetailView(store: store)) {
                                    StoreCardView(store: store)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadStores()
            updateService.startPolling(forType: categoryName)
        }
        .onDisappear {
            updateService.stopPolling()
        }
        .onChange(of: updateService.storeUpdates) { updates in
            applyUpdates(updates)
        }
    }

    private func applyUpdates(_ updates: [StoreUpdate]) {
        print("🔄 [UPDATE] Applying \(updates.count) store updates")
        for update in updates {
            if let index = stores.firstIndex(where: { $0.id == update.id }) {
                print("  ✏️ Updated store: \(update.name) - Status: \(update.status)")
                stores[index].status = update.status
            }
        }
    }

    private func loadStores() {
        isLoading = true
        errorMessage = nil
        print("🔍 [STORES] Starting to load stores for category: \(categoryName)")

        Task {
            do {
                let fetchedStores = try await StoreService.getPublicStoresByType(categoryName)
                print("✅ [STORES] Successfully fetched stores: \(fetchedStores.count)")
                for store in fetchedStores {
                    print("  • \(store.name) - Type: \(store.storeType ?? "Unknown")")
                }
                
                await MainActor.run {
                    self.stores = fetchedStores
                    self.isLoading = false
                }
            } catch {
                print("❌ [STORES] Error loading stores for '\(self.categoryName)': \(error)")
                print("  Error description: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.errorMessage = "Failed to load stores: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Store Card View - Luxury Design
struct StoreCardView: View {
    let store: Store
    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Store Image Container with Frosted Effect
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.05),
                        Color.black.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Circular Icon in Center with Border
                VStack {
                    if let fullIconUrl = store.fullIconUrl, let url = URL(string: fullIconUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                                    )
                            case .empty:
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                                        )
                                    ProgressView()
                                        .tint(.gray.opacity(0.5))
                                }
                                .frame(width: 90, height: 90)
                            case .failure:
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                                        )
                                    Image(systemName: "storefront.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                .frame(width: 90, height: 90)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                                )
                            Image(systemName: "storefront.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(width: 90, height: 90)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            }
            .frame(height: 140)

            // Text Content Section
            VStack(alignment: .leading, spacing: 6) {
                // Store Name
                Text(store.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
                    .truncationMode(.tail)

                // Store Type Badge
                if let storeType = store.storeType {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)
                        Text(storeType)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                // Address with Icon
                if let address = store.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(address)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .frame(height: 240)
        .background(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .scaleEffect(isHovering ? 0.98 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Store Detail View
struct StoreDetailView: View {
    let store: Store
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.12)
                ] : [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.95, green: 0.95, blue: 0.97)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header - Liquid Glass Back Button
                HStack {
                    LiquidGlassBackButton()
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal, 20)
                .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)
                .border(Color.black.opacity(0.05), width: 1)

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Store Image Banner
                        if let fullIconUrl = store.fullIconUrl, let url = URL(string: fullIconUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                case .empty:
                                    ZStack {
                                        Color.gray.opacity(0.1)
                                        ProgressView()
                                    }
                                    .frame(height: 200)
                                default:
                                    Color.gray.opacity(0.05)
                                        .frame(height: 200)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            // Store Name & Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text(store.name)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)

                                if let storeType = store.storeType {
                                    HStack(spacing: 12) {
                                        Text(storeType)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.orange.opacity(0.8))
                                            .cornerRadius(6)

                                        if let status = store.status {
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 6, height: 6)
                                                Text(status)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()
                                .background(Color.black.opacity(0.08))

                            // Info Sections
                            if let address = store.address {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.orange)
                                            .frame(width: 24)
                                        Text("Address")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    Text(address)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(3)
                                }
                            }

                            if let phone = store.phone {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                        Text("Phone")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    Text(phone)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                            }

                            if let email = store.email {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.green)
                                            .frame(width: 24)
                                        Text("Email")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    Text(email)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(20)
                        .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)
                        .cornerRadius(12)
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    CategoryStoresView(categoryName: "Food")
}

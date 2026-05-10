import SwiftUI

struct CategoryStoresView: View {
    let categoryName: String
    @State private var stores: [Store] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @StateObject private var updateService = StoreUpdateService()
    @EnvironmentObject var cartManager: CartManager
    @State private var showCartSheet = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Adaptive background - True black in dark, white in light
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color(red: 0.0, green: 0.0, blue: 0.0),
                    Color(red: 0.0, green: 0.0, blue: 0.0)
                ] : [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.95, green: 0.95, blue: 0.97)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Subtitle row (locations count) — sits below native large title
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(stores.count) locations available")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)

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
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 6) {
                    CartBadgeButton(itemCount: cartManager.itemCount, action: { showCartSheet = true }, iconColor: colorScheme == .dark ? .white : .black)
                    if cartManager.itemCount > 0 {
                        CartCountBadge(count: cartManager.itemCount)
                    }
                }
            }
        }
        .sheet(isPresented: $showCartSheet) {
            CartView(showsCloseButton: true)
        }
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


// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Product Image
            if let fullImageUrl = product.fullImageUrl, let url = URL(string: fullImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                        .frame(height: 100)
                        .cornerRadius(8)
                    default:
                        Color.gray.opacity(0.05)
                            .frame(height: 100)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Product Name
            Text(product.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(2)
            
            // Product Price
            Text(product.formattedPrice)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)
            
            // Stock Badge
            if let is_active = product.is_active, is_active > 0 && product.stock > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 4, height: 4)
                    Text("In Stock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                    Spacer()
                    Text("×\(product.stock)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else {
                Text("Out of Stock")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    CategoryStoresView(categoryName: "Food")
}
import SwiftUI

// MARK: - Product Detail View
struct ProductDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    let product: Product
    let store: Store
    
    @State private var showFullScreenImage: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var quantity: Int = 1
    @State private var isLiked: Bool = false
    @State private var showAddedToCart: Bool = false
    @State private var showCartSheet: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header — Minimal, elegant
            headerView
            
            Divider()
                .background(Color(.separator).opacity(0.3))
            
            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Product Image
                    productImageView
                    
                    // Product Info
                    productInfoView
                    
                    // Description
                    descriptionView
                    
                    // Store Info Card (Sold by)
                    storeInfoCard
                }
                .padding(.vertical, 20)
            }
            // السحر هنا: يثبت البوكس تحت ويضيف مسافة تلقائياً للسكرول
            .safeAreaInset(edge: .bottom) {
                bottomAddToCartBar
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack(spacing: 6) {
                    CartBadgeButton(
                        itemCount: cartManager.itemCount,
                        action: { showCartSheet = true },
                        iconColor: colorScheme == .dark ? .white : .black
                    )

                    if cartManager.itemCount > 0 {
                        CartCountBadge(count: cartManager.itemCount)
                    }
                }
            }
        }
        .sheet(isPresented: $showFullScreenImage) {
            NavigationStack {
                FullScreenImageView(imageUrls: resolvedImageUrls, initialIndex: selectedImageIndex)
            }
        }
        .sheet(isPresented: $showCartSheet) {
            CartView(showsCloseButton: true)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack(spacing: 12) {
            if let iconUrl = store.fullIconUrl, let url = URL(string: iconUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color(.separator).opacity(0.2), lineWidth: 1))
                    default:
                        placeholderStoreIcon
                    }
                }
            } else {
                placeholderStoreIcon
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                
                Text(store.storeType ?? "Store")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Spacer()
            
            Button(action: { isLiked.toggle() }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isLiked ? .red : Color(.tertiaryLabel))
                    .animation(.spring(), value: isLiked)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var placeholderStoreIcon: some View {
        Image(systemName: "building.2")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(.secondaryLabel))
            .frame(width: 40, height: 40)
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())
    }
    
    private var productImageView: some View {
        Group {
            if resolvedImageUrls.count > 1 {
                TabView(selection: $selectedImageIndex) {
                    ForEach(resolvedImageUrls.indices, id: \.self) { index in
                        productImageCell(urlString: resolvedImageUrls[index], index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            } else {
                if let imageUrl = resolvedImageUrls.first {
                    productImageCell(urlString: imageUrl, index: 0)
                } else {
                    fallbackImageView
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private func productImageCell(urlString: String, index: Int) -> some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color(.secondarySystemBackground)
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        fallbackImageView
                    @unknown default:
                        fallbackImageView
                    }
                }
            } else {
                fallbackImageView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedImageIndex = index
            showFullScreenImage = true
        }
    }
    
    private var fallbackImageView: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
    
    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(.label))
                .lineSpacing(2)
            
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(product.stock > 0 ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(product.stock > 0 ? "In Stock" : "Out of Stock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(product.stock > 0 ? Color.green : Color.red)
                }
                
                Divider().frame(height: 16)
                
                Text(product.category_name ?? "Uncategorized")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Text(product.formattedPrice)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
    }
    
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this product")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.label))
            
            Text(product.description ?? "No description available")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .lineSpacing(5)
        }
        .padding(.horizontal, 16)
    }
    
    private var storeInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SOLD BY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.tertiaryLabel))
            
            HStack(spacing: 12) {
                if let iconUrl = store.fullIconUrl, let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            placeholderStoreIcon.frame(width: 48, height: 48)
                        }
                    }
                } else {
                    placeholderStoreIcon.frame(width: 48, height: 48)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.label))
                    
                    if let phone = store.phone {
                        Text(phone)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var resolvedImageUrls: [String] {
        let urls = product.imageGalleryUrls.compactMap { resolvedURLString(from: $0) }
        return urls.isEmpty ? (product.primaryImageUrl.flatMap { resolvedURLString(from: $0) }.map { [$0] } ?? []) : urls
    }

    private func resolvedURLString(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.starts(with: "http") {
            if trimmed.contains("localhost:3000") {
                let baseHost = AppConstants.baseURLCandidates.first ?? "http://10.155.83.72:3000"
                let cleanBase = baseHost.replacingOccurrences(of: "/api/v1", with: "")
                return trimmed.replacingOccurrences(of: "http://localhost:3000", with: cleanBase)
            }
            return trimmed
        }

        let baseHost = AppConstants.baseURLCandidates.first ?? "http://10.155.83.72:3000"
        let cleanBase = baseHost.replacingOccurrences(of: "/api/v1", with: "")
        return cleanBase + trimmed
    }
    
    private var bottomAddToCartBar: some View {
        VStack(spacing: 16) {
            HStack {
                // Quantity Selector (Pill Style)
                HStack(spacing: 16) {
                    Button(action: { if quantity > 1 { quantity -= 1 } }) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(quantity > 1 ? Color(.label) : Color(.tertiaryLabel))
                    }
                    
                    Text("\(quantity)")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(minWidth: 24, alignment: .center)
                    
                    Button(action: { if quantity < product.stock { quantity += 1 } }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(quantity < product.stock ? Color(.label) : Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                
                Spacer()
                
                // Total Price Info (Dynamic - changes with quantity)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    let totalPrice = product.priceDouble * Double(quantity)
                    let currencySymbol = product.currencySymbol
                    Text("\(currencySymbol)\(String(format: "%.2f", totalPrice))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(.label))
                }
            }
            .padding(.horizontal, 20)
            
            // Add to Cart Button
            Button(action: {
                Task {
                    do {
                        try await cartManager.addToCart(product: product, quantity: quantity)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            showAddedToCart = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showAddedToCart = false
                            }
                        }
                    } catch {
                        print("❌ [CART] Failed to add item: \(error.localizedDescription)")
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: showAddedToCart ? "checkmark.circle.fill" : "bag.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(showAddedToCart ? "Added to Cart" : "Add to Cart")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(showAddedToCart ? Color.green : Color.blue)
                .cornerRadius(14)
                .scaleEffect(showAddedToCart ? 1.01 : 1.0)
                .shadow(color: (showAddedToCart ? Color.green : Color.blue).opacity(0.22), radius: 12, x: 0, y: 6)
            }
            .disabled(product.stock <= 0)
            .opacity(product.stock <= 0 ? 0.5 : 1.0)
            .padding(.horizontal, 16)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        // ظل خفيف يفصل البوكس عن باقي الصفحة
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4) 
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let imageUrls: [String]
    let initialIndex: Int
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()

            VStack {
                Spacer()

                if imageUrls.isEmpty {
                    Image(systemName: "photo")
                        .font(.system(size: 42))
                        .foregroundColor(.gray)
                } else {
                    TabView(selection: $selectedIndex) {
                        ForEach(imageUrls.indices, id: \.self) { index in
                            if let url = URL(string: imageUrls[index]) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFit().padding(.horizontal, 12)
                                    case .empty:
                                        ProgressView().tint(colorScheme == .dark ? .white : .black)
                                    case .failure:
                                        Image(systemName: "photo").foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: imageUrls.count > 1 ? .automatic : .never))
                    .onAppear {
                        selectedIndex = min(max(initialIndex, 0), max(imageUrls.count - 1, 0))
                    }
                }

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NativeCircleIconButton(
                    systemName: "xmark",
                    action: { dismiss() },
                    iconColor: .primary,
                    size: 35.5,
                    iconSize: 15,
                    showBackground: false
                )
            }
        }
    }
}
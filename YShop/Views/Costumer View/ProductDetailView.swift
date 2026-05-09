import SwiftUI

// MARK: - Product Detail View
struct ProductDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let product: Product
    let store: Store
    
    @State private var showFullScreenImage: Bool = false
    @State private var quantity: Int = 1
    @State private var isLiked: Bool = false
    @State private var showAddedToCart: Bool = false
    
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
        .sheet(isPresented: $showFullScreenImage) {
            FullScreenImageView(imageUrl: product.fullImageUrl ?? "")
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
            if let fullImageUrl = product.fullImageUrl, let url = URL(string: fullImageUrl) {
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
                            .onTapGesture { showFullScreenImage = true }
                    case .failure:
                        fallbackImageView
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                fallbackImageView
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal, 16)
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
                showAddedToCart = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showAddedToCart = false }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add to Cart")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.blue)
                .cornerRadius(14)
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
    
    let imageUrl: String
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(16)
                
                Spacer()
                
                if let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .empty:
                            ProgressView().tint(colorScheme == .dark ? .white : .black)
                        case .failure:
                            Image(systemName: "photo").foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}
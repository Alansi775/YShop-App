import SwiftUI

// MARK: - Product Detail View
struct ProductDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    let product: Product
    let store: Store
    
    @State private var selectedImageIndex: Int = 0
    @State private var showFullScreenImage: Bool = false
    @State private var quantity: Int = 1
    @State private var showAddedToCart: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                    
                    Text(store.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(colorScheme == .dark ? Color.black : Color.white)
                
                Divider()
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Image Gallery
                        VStack(spacing: 12) {
                            // Main Image
                            ZStack {
                                if let fullImageUrl = product.fullImageUrl, let url = URL(string: fullImageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 350)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 350)
                                                .clipped()
                                        case .failure:
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                                .frame(height: 350)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .frame(height: 350)
                                }
                                
                                // Full Screen Button
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: { showFullScreenImage = true }) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(12)
                                    }
                                    Spacer()
                                }
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Product Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text(product.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            // Category Badge
                            HStack {
                                Text(product.category_name ?? "Uncategorized")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 0.258, green: 0.647, blue: 0.961))
                                    .cornerRadius(6)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Price and Stock
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                
                                Text(product.formattedPrice)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 0.258, green: 0.647, blue: 0.961))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stock")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(product.stock > 0 ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("\(product.stock) available")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                            }
                        }
                        .padding(16)
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text(product.description ?? "No description available")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Store Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Store Information")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            HStack(spacing: 12) {
                                if let iconUrl = store.fullIconUrl, let url = URL(string: iconUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(8)
                                        default:
                                            Image(systemName: "building.2")
                                                .frame(width: 50, height: 50)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
                                    Text(store.phone ?? "No phone")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Add to Cart Button (Fixed at Bottom)
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Quantity Selector
                    HStack(spacing: 16) {
                        Text("Quantity:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        HStack(spacing: 12) {
                            Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color(red: 0.258, green: 0.647, blue: 0.961))
                                    .cornerRadius(8)
                            }
                            
                            Text("\(quantity)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(minWidth: 40)
                            
                            Button(action: { if quantity < product.stock { quantity += 1 } }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color(red: 0.258, green: 0.647, blue: 0.961))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Add to Cart Button
                    Button(action: {
                        // TODO: Add to cart logic
                        showAddedToCart = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showAddedToCart = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "bag")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Add to Cart - \(product.formattedPrice)")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.258, green: 0.647, blue: 0.961))
                        .cornerRadius(12)
                    }
                    .disabled(product.stock <= 0)
                    .opacity(product.stock <= 0 ? 0.5 : 1.0)
                }
                .padding(16)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .border(Color(.systemGray5), width: 0.5)
            }
        }
        .sheet(isPresented: $showFullScreenImage) {
            FullScreenImageView(imageUrl: product.fullImageUrl ?? "")
        }
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    @Environment(\.dismiss) var dismiss
    
    let imageUrl: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
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
                            image
                                .resizable()
                                .scaledToFit()
                        case .empty:
                            ProgressView()
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
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

#Preview {
    ProductDetailView(product: Product.mock, store: Store.mock)
}

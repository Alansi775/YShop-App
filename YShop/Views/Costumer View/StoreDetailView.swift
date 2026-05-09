import SwiftUI

// MARK: - Store Detail View
struct StoreDetailView: View {
    let store: Store
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var products: [Product] = []
    @State private var isLoadingProducts = true
    @State private var productsError: String?
    
    // Animation States
    @State private var headerVisible = false
    @State private var menuVisible = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 1. الخلفية الديناميكية
            backgroundLayer
            
            // 2. اللمسة الجمالية: النجوم العائمة في الخلفية
            FloatingStarsView()
                .opacity(headerVisible ? 0.6 : 0)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    // 3. الهيدر المطور (العنوان فوق والرقم تحت)
                    storeProfileHeader
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 30)
                    
                    Divider()
                        .background(Color(.separator).opacity(0.2))
                        .padding(.horizontal, 24)
                    
                    // 4. قسم "The Menu" والمنتجات
                    if menuVisible {
                        productsSection
                    }
                }
                .padding(.bottom, 40)
                // تتبع حركة السكرول لتصغير الشعار برفق
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                })
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { scrollOffset = $0 }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // انيميشن دخول العناصر
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                headerVisible = true
            }
            withAnimation(.easeInOut.delay(0.5)) {
                menuVisible = true
            }
            loadProducts()
        }
    }
    
    // MARK: - Components
    
    private var backgroundLayer: some View {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark ? 
                [Color(hex: "0F0F0F"), Color.black] : 
                [Color.white, Color(hex: "F8F8F8")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var storeProfileHeader: some View {
        VStack(spacing: 20) {
            // Avatar (Store Logo)
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    .frame(width: 110, height: 110)
                
                Group {
                    if let fullIconUrl = store.fullIconUrl, let url = URL(string: fullIconUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .empty:
                                ProgressView()
                            default:
                                Image(systemName: "building.2")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    } else {
                        Image(systemName: "building.2")
                            .font(.system(size: 32))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            }
            .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 2))
            .shadow(color: .blue.opacity(0.1), radius: 15, x: 0, y: 10)
            .scaleEffect(max(0.8, 1 - (scrollOffset / 1000))) // تأثير تفاعلي مع السكرول
            .padding(.top, 20)
            
            // Name & Status & Info (العنوان فوق، التفاصيل تحت)
            VStack(spacing: 12) {
                Text(store.name)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.center)
                
                if let storeType = store.storeType {
                    Text(storeType.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(3)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // العنوان والرقم (تحت بعض)
                VStack(spacing: 6) {
                    if let address = store.address {
                        infoItem(icon: "mappin.and.ellipse", text: address)
                    }
                    if let phone = store.phone {
                        infoItem(icon: "phone.fill", text: phone)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func infoItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.blue)
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
        }
    }
    
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("THE MENU")
                .font(.system(size: 14, weight: .black))
                .tracking(8)
                .foregroundColor(Color(.tertiaryLabel))
                .frame(maxWidth: .infinity)
            
            if isLoadingProducts {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 50)
            } else if let error = productsError {
                Text(error).foregroundColor(.red).frame(maxWidth: .infinity)
            } else {
                let groupedProducts = Dictionary(grouping: products) { $0.category_name ?? "Other" }
                let sortedCategories = groupedProducts.keys.sorted()
                
                ForEach(sortedCategories, id: \.self) { categoryName in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(categoryName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(.label))
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            ForEach(Array((groupedProducts[categoryName] ?? []).enumerated()), id: \.offset) { index, product in
                                NavigationLink(destination: ProductDetailView(product: product, store: store)) {
                                    StoreMinimalProductCard(product: product)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(menuVisible ? 1 : 0)
                                .offset(y: menuVisible ? 0 : 40)
                                .animation(.spring().delay(Double(index) * 0.05), value: menuVisible)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    private func loadProducts() {
        Task {
            do {
                let fetchedProducts = try await StoreService.getStoreProducts(storeId: store.id)
                DispatchQueue.main.async {
                    products = fetchedProducts
                    isLoadingProducts = false
                }
            } catch {
                DispatchQueue.main.async {
                    productsError = error.localizedDescription
                    isLoadingProducts = false
                }
            }
        }
    }
}

// MARK: - Minimal Product Card
struct StoreMinimalProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let imageUrl = product.fullImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                } else {
                    Color(.secondarySystemBackground)
                        .overlay(Image(systemName: "photo").foregroundColor(Color(.tertiaryLabel)))
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(2)
                
                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(.secondaryLabel).opacity(0.3))
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator).opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Floating Stars View (اللمسة الجمالية)
// MARK: - Floating Stars View (نسخة العوم البطيء والانسيابي)
struct FloatingStarsView: View {
    @State private var animate = false
    
    // الألوان الأنيقة (أزرق وذهبي)
    let colors: [Color] = [
        Color.blue.opacity(0.3),
        Color(red: 1.0, green: 0.65, blue: 0.1).opacity(0.25)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<20) { i in // زدنا العدد لملء الفراغات أثناء العوم
                    Circle()
                        .fill(colors[i % colors.count])
                        .frame(width: CGFloat.random(in: 2...4.5))
                        // مكان البداية العشوائي
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        // حركة العوم البطيئة (تتحرك في الاتجاهين X و Y)
                        .offset(
                            x: animate ? CGFloat.random(in: -30...30) : CGFloat.random(in: -10...10),
                            y: animate ? CGFloat.random(in: -50...50) : CGFloat.random(in: -20...20)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 8...12)) // مدة طويلة تعني حركة أبطأ وأفخم
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...5)),
                            value: animate
                        )
                }
            }
            .onAppear {
                // تفعيل الحركة فور ظهور الشاشة
                animate = true
            }
        }
    }
}

// MARK: - Helpers
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
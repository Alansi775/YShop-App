import SwiftUI

// MARK: - Hero Product Model
struct HeroProduct: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let imagePath: String
    let gradient: [Color]
    let category: String
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentHeroIndex = 0
    @State private var searchText = ""
    @State private var heroTimer: Timer?
    @State private var isAIExpanded = false
    @State private var showProfileSheet = false
    @State private var showCartSheet = false
    @State private var cartItemCount = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedCategory: String = ""
    @State private var navigateToCategoryStores = false
    
    let heroProducts = [
        HeroProduct(
            name: "PREMIUM FOOD",
            subtitle: "Gourmet Excellence",
            imagePath: "9",
            gradient: [Color(red: 0.16, green: 0.09, blue: 0.06), Color(red: 0.05, green: 0.03, blue: 0.02)],
            category: "Food"
        ),
        HeroProduct(
            name: "HEALTHCARE",
            subtitle: "Wellness Essentials",
            imagePath: "Hero",
            gradient: [Color(red: 0.10, green: 0.15, blue: 0.19), Color(red: 0, green: 0, blue: 0)],
            category: "Pharmacy"
        ),
        HeroProduct(
            name: "FASHION",
            subtitle: "Curated Style",
            imagePath: "0",
            gradient: [Color(red: 0.15, green: 0.15, blue: 0.23), Color(red: 0.04, green: 0.04, blue: 0.07)],
            category: "Clothes"
        ),
        HeroProduct(
            name: "FRESH MARKET",
            subtitle: "Farm to Table",
            imagePath: "1",
            gradient: [Color(red: 0.18, green: 0.14, blue: 0.09), Color(red: 0.06, green: 0.04, blue: 0.02)],
            category: "Market"
        ),
    ]
    
    var body: some View {
        ZStack {
            // Hidden Navigation Link for Category Stores
            NavigationLink(
                destination: CategoryStoresView(categoryName: selectedCategory),
                isActive: $navigateToCategoryStores
            ) {
                EmptyView()
            }
            .hidden()
            // Hero Section - Full Screen (No AppBar!)
            VStack(spacing: 0) {
                // Hero Carousel (Full Height)
                ZStack {
                    // Background Gradient
                    LinearGradient(
                        gradient: Gradient(colors: heroProducts[currentHeroIndex].gradient),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    // Hero Content - Full screen with bottom category carousel
                    VStack(spacing: 0) {
                        // Hero Image & Content (Center)
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // YSHOP Brand Logo - Centered Early
                            VStack {
                                Text("YSHOP")
                                    .font(.system(size: 42, weight: .semibold))
                                    .tracking(4)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            
                            Spacer()
                            
                            // Product Image (with fallback)
                            if let uiImage = UIImage(named: heroProducts[currentHeroIndex].imagePath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIScreen.main.bounds.height * 0.25)
                                    .opacity(isAIExpanded ? 0.1 : 1.0)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(.tertiaryLabel))
                                    
                                    Text(heroProducts[currentHeroIndex].imagePath)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                .frame(height: UIScreen.main.bounds.height * 0.25)
                                .opacity(isAIExpanded ? 0.1 : 1.0)
                            }
                            
                            Spacer()
                            
                            // AI Search Box (Inside Hero)
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white)
                                    
                                    TextField("Ask me anything...", text: $searchText)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(.white)
                                    
                                    if !searchText.isEmpty {
                                        Button(action: { searchText = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.15))
                                .backdrop()
                                .cornerRadius(14)
                                .frame(maxWidth: 280)
                            }
                            .padding(.horizontal, 40)
                            
                            Spacer()
                            
                            // Bottom Hero Text
                            VStack(spacing: 16) {
                                Text(heroProducts[currentHeroIndex].name)
                                    .font(.system(size: 42, weight: .light))
                                    .tracking(3)
                                    .foregroundColor(.white)
                                
                                Text(heroProducts[currentHeroIndex].subtitle)
                                    .font(.system(size: 14, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Button(action: {
                                    selectedCategory = heroProducts[currentHeroIndex].category
                                    navigateToCategoryStores = true
                                }) {
                                    HStack(spacing: 8) {
                                        Text("EXPLORE")
                                            .font(.system(size: 12, weight: .semibold))
                                            .tracking(2)
                                            .foregroundColor(.white)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding(.bottom, 45)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Bottom Horizontal Category Carousel (Swipe Animation)
                        VStack(spacing: 12) {
                            // Horizontal swipe carousel - shows 3 items
                            ZStack {
                                // Background blur for depth
                                HStack(spacing: 16) {
                                    ForEach(-1...1, id: \.self) { offset in
                                        let index = (currentHeroIndex + offset + heroProducts.count) % heroProducts.count
                                        let isCenter = offset == 0
                                        
                                        VStack(spacing: 4) {
                                            Text(heroProducts[index].name)
                                                .font(.system(size: isCenter ? 13 : 10, weight: .semibold))
                                                .tracking(isCenter ? 0.8 : 0.5)
                                                .foregroundColor(.white)
                                                .opacity(isCenter ? 1.0 : 0.4)
                                                .lineLimit(isCenter ? 2 : 1)
                                                .truncationMode(.tail)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(height: isCenter ? 65 : 45)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            isCenter ?
                                            Color.white.opacity(0.12) : Color.white.opacity(0.06)
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            isCenter ?
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5) : nil
                                        )
                                        .scaleEffect(isCenter ? 1.0 : 0.9)
                                        .onTapGesture {
                                            if isCenter {
                                                // Tap center to navigate to store
                                                selectedCategory = heroProducts[index].category
                                                navigateToCategoryStores = true
                                            } else {
                                                // Tap sides to change product
                                                withAnimation(.easeInOut(duration: 0.4)) {
                                                    changeProduct(index)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            // Swipe hint with arrow
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .offset(x: scrollOffset > 0 ? -2 : 0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scrollOffset)
                                
                                Text("SWIPE")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1.0)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .offset(x: scrollOffset > 0 ? 2 : 0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scrollOffset)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Floating Header (Top Right) - Profile & Cart Only
                    VStack(spacing: 0) {
                        HStack(spacing: 16) {
                            Spacer()
                            
                            // Profile Button
                            Button(action: { showProfileSheet = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Cart Button
                            Button(action: { showCartSheet = true }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bag.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                    
                                    // Only show badge if items exist
                                    if cartItemCount > 0 {
                                        Text("\(cartItemCount)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color(red: 0.2, green: 0.6, blue: 0.9))
                                            .cornerRadius(9)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        
                        Spacer()
                    }
                    .zIndex(100)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onChanged { value in
                    scrollOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    
                    if value.translation.width > threshold {
                        // Swiped right - show previous
                        let prevIndex = (currentHeroIndex - 1 + heroProducts.count) % heroProducts.count
                        withAnimation(.easeInOut(duration: 0.4)) {
                            changeProduct(prevIndex)
                        }
                    } else if value.translation.width < -threshold {
                        // Swiped left - show next
                        let nextIndex = (currentHeroIndex + 1) % heroProducts.count
                        withAnimation(.easeInOut(duration: 0.4)) {
                            changeProduct(nextIndex)
                        }
                    }
                    
                    scrollOffset = 0
                }
        )
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(isPresented: $showProfileSheet)
        }
        .sheet(isPresented: $showCartSheet) {
            CartSheetView(isPresented: $showCartSheet)
        }
        .onAppear {
            startAutoRotate()
        }
        .onDisappear {
            heroTimer?.invalidate()
        }
    }
    
    // MARK: - Methods
    private func changeProduct(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.6)) {
            currentHeroIndex = index
        }
        heroTimer?.invalidate()
        startAutoRotate()
    }
    
    private func startAutoRotate() {
        heroTimer?.invalidate()
        heroTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            let nextIndex = (currentHeroIndex + 1) % heroProducts.count
            changeProduct(nextIndex)
        }
    }
}

// MARK: - Backdrop Effect
struct BackdropView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            let blurEffect = UIBlurEffect(style: .light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(blurView, at: 0)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func backdrop() -> some View {
        self.background(BackdropView())
    }
}

// MARK: - Profile Sheet
struct ProfileSheetView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Sheet Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Profile Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text(authManager.currentUser?.name ?? "User")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(authManager.currentUser?.email ?? "user@example.com")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Profile Options
            VStack(spacing: 12) {
                ProfileOptionRow(icon: "person", title: "My Profile")
                ProfileOptionRow(icon: "heart", title: "Saved Items")
                ProfileOptionRow(icon: "mappin", title: "Addresses")
                ProfileOptionRow(icon: "creditcard", title: "Payment Methods")
                ProfileOptionRow(icon: "questionmark.circle", title: "Help & Support")
            }
            
            Spacer()
            
            // Logout Button
            Button(action: {
                authManager.logout()
                isPresented = false
            }) {
                Text("SIGN OUT")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .presentationDetents([.medium, .large])
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1.0))
        .cornerRadius(10)
    }
}

// MARK: - Cart Sheet
struct CartSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Sheet Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Cart Header
            HStack {
                Text("SHOPPING CART")
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(1.5)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            Divider()
            
            // Empty Cart State
            VStack(spacing: 16) {
                Image(systemName: "bag")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                
                Text("Your Cart is Empty")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Add items to your cart to get started")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                
                Button(action: { isPresented = false }) {
                    Text("CONTINUE SHOPPING")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1.2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.top, 16)
            }
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(20)
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
}

import SwiftUI

struct HeroProduct: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let imagePath: String
    let gradient: [Color]
    let category: String
    let icon: String
}

struct NativeBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var cartManager: CartManager

    @State private var currentHeroIndex = 0
    @State private var heroTimer: Timer?
    @State private var showAISheet = false
    @State private var showProfileSheet = false
    @State private var showMyOrdersSheet = false
    @State private var shouldPresentMyOrdersAfterProfileDismiss = false
    @State private var showCartSheet = false
    @State private var selectedCategory: String = ""
    @State private var navigateToCategoryStores = false

    let heroProducts = [
        HeroProduct(name: "PREMIUM FOOD",  subtitle: "Gourmet Excellence",  imagePath: "9",    gradient: [Color(red: 0.16, green: 0.09, blue: 0.06), Color(red: 0.05, green: 0.03, blue: 0.02)], category: "Food",     icon: "fork.knife"),
        HeroProduct(name: "HEALTHCARE",    subtitle: "Wellness Essentials", imagePath: "Hero", gradient: [Color(red: 0.10, green: 0.15, blue: 0.19), Color(red: 0, green: 0, blue: 0)],           category: "Pharmacy", icon: "cross.case.fill"),
        HeroProduct(name: "FASHION",       subtitle: "Curated Style",       imagePath: "0",    gradient: [Color(red: 0.15, green: 0.15, blue: 0.23), Color(red: 0.04, green: 0.04, blue: 0.07)], category: "Clothes",  icon: "tshirt.fill"),
        HeroProduct(name: "FRESH MARKET",  subtitle: "Farm to Table",       imagePath: "1",    gradient: [Color(red: 0.18, green: 0.14, blue: 0.09), Color(red: 0.06, green: 0.04, blue: 0.02)], category: "Market",   icon: "basket.fill"),
    ]

    var body: some View {
        ZStack {
            // Single NavigationLink — prevents duplicate firings from each tab
            NavigationLink(
                destination: CategoryStoresView(categoryName: selectedCategory),
                isActive: $navigateToCategoryStores
            ) { EmptyView() }.hidden()

            if #available(iOS 18.0, *) {
                nativeTabView
            } else {
                legacyView
            }
        }
        .sheet(isPresented: $showAISheet) {
            AIShoppingView()
                .environmentObject(authManager)
                .environmentObject(cartManager)
        }
        .sheet(isPresented: $showProfileSheet, onDismiss: {
            if shouldPresentMyOrdersAfterProfileDismiss {
                shouldPresentMyOrdersAfterProfileDismiss = false
                showMyOrdersSheet = true
            }
        }) {
            ProfileSheetView(isPresented: $showProfileSheet, onMyOrders: {
                shouldPresentMyOrdersAfterProfileDismiss = true
                showProfileSheet = false
            })
        }
        .sheet(isPresented: $showMyOrdersSheet) {
            NavigationStack {
                MyOrdersView(isPresented: $showMyOrdersSheet)
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
        }
        .sheet(isPresented: $showCartSheet) {
            CartView(showsCloseButton: true)
        }
        .onAppear { startAutoRotate() }
        .onDisappear { heroTimer?.invalidate() }
    }

    // MARK: - iOS 18 Native TabView

    @available(iOS 18.0, *)
    private var nativeTabView: some View {
        TabView(selection: $currentHeroIndex) {
            ForEach(Array(heroProducts.enumerated()), id: \.offset) { i, hero in
                Tab(hero.category, systemImage: hero.icon, value: i) {
                    heroPage(hero, index: i)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NativeCircleIconButton(systemName: "person.fill", action: { showProfileSheet = true })
                HStack(spacing: 6) {
                    CartBadgeButton(itemCount: cartManager.itemCount, action: { showCartSheet = true }, iconColor: .white)
                    if cartManager.itemCount > 0 { CartCountBadge(count: cartManager.itemCount) }
                }
            }
        }
    }

    // MARK: - iOS 17 Fallback (AppleStretchyTabBar)

    private var legacyView: some View {
        ZStack {
            heroPageContent(heroProducts[currentHeroIndex])
        }
        .overlay(alignment: .bottom) {
            AppleStretchyTabBar(
                selectedIndex: $currentHeroIndex,
                icons: heroProducts.map { $0.icon }
            ) { index in
                changeProduct(index)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NativeCircleIconButton(systemName: "person.fill", action: { showProfileSheet = true })
                HStack(spacing: 6) {
                    CartBadgeButton(itemCount: cartManager.itemCount, action: { showCartSheet = true }, iconColor: .white)
                    if cartManager.itemCount > 0 { CartCountBadge(count: cartManager.itemCount) }
                }
            }
        }
        .toolbar(.hidden, for: .bottomBar)
        .gesture(DragGesture().onEnded { value in
            if value.translation.width > 50 {
                changeProduct((currentHeroIndex - 1 + heroProducts.count) % heroProducts.count)
            } else if value.translation.width < -50 {
                changeProduct((currentHeroIndex + 1) % heroProducts.count)
            }
        })
    }

    // MARK: - Hero Page (iOS 18 Tab content)

    @available(iOS 18.0, *)
    private func heroPage(_ hero: HeroProduct, index: Int) -> some View {
        heroPageContent(hero)
        .gesture(DragGesture().onEnded { value in
            if value.translation.width > 50 {
                changeProduct((index - 1 + heroProducts.count) % heroProducts.count)
            } else if value.translation.width < -50 {
                changeProduct((index + 1) % heroProducts.count)
            }
        })
    }

    // MARK: - Hero Content (shared)

    @ViewBuilder
    private func heroPageContent(_ hero: HeroProduct) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: hero.gradient),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("YSHOP")
                    .font(.system(size: 42, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)

                Spacer()

                if let uiImage = UIImage(named: hero.imagePath) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFit()
                        .frame(height: UIScreen.main.bounds.height * 0.25)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text(hero.imagePath)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.25)
                }

                Spacer()

                // AI Ask Bar
                AIAskBar { showAISheet = true }
                    .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 16) {
                    Text(hero.name)
                        .font(.system(size: 42, weight: .light))
                        .tracking(3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(hero.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.7))

                    ExploreButton {
                        selectedCategory = hero.category
                        navigateToCategoryStores = true
                    }
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Helpers

    private func changeProduct(_ index: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            currentHeroIndex = index
        }
        startAutoRotate()
    }

    private func startAutoRotate() {
        heroTimer?.invalidate()
        heroTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            changeProduct((currentHeroIndex + 1) % heroProducts.count)
        }
    }
}

// MARK: - AI Ask Bar

private struct AIAskBar: View {
    let action: () -> Void
    private static let borderCycle: Double = 7.0
    // Total flash cycle: 5.5s — beam sweeps for first 2s then rests 3.5s
    private static let flashCycle:  Double = 5.5
    private static let flashActive: Double = 2.0   // sweep portion of the cycle

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let borderAngle = (t.truncatingRemainder(dividingBy: Self.borderCycle) / Self.borderCycle) * 360
            // Raw position in current flash cycle (0…1)
            let cyclePos = t.truncatingRemainder(dividingBy: Self.flashCycle) / Self.flashCycle
            // Beam only active during first flashActive/flashCycle fraction
            let activeRatio = Self.flashActive / Self.flashCycle
            let beamT: Double = cyclePos < activeRatio ? cyclePos / activeRatio : 1.0
            // Ease-in-out so the beam feels like light glancing across a surface
            let eased = beamT < 0.5
                ? 2 * beamT * beamT
                : 1 - pow(-2 * beamT + 2, 2) / 2
            barFace(borderAngle: borderAngle, beamEased: eased, beamVisible: cyclePos < activeRatio)
        }
        .transaction { $0.animation = nil }
    }

    private func barFace(borderAngle: Double, beamEased: Double, beamVisible: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Y")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.12)))
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask me anything")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("YShop AI")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.42))
                }

                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.28))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            // Flash beam — only rendered during active sweep window
            .overlay(
                GeometryReader { geo in
                    if beamVisible {
                        let beamW: CGFloat = 120
                        let x = beamEased * (geo.size.width + beamW * 2) - beamW
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.09), .white.opacity(0.17), .white.opacity(0.09), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: beamW)
                        .frame(maxHeight: .infinity)
                        .offset(x: x)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
            // Rotating border
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .clear, .clear, .clear,
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.78),
                                Color.white.opacity(0.14),
                                .clear, .clear,
                            ],
                            center: .center,
                            angle: .degrees(borderAngle)
                        ),
                        lineWidth: 1.0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Explore Button

private struct ExploreButton: View {
    let action: () -> Void
    private static let cycleDuration: Double = 10.0

    var body: some View {
        // TimelineView drives angle from real clock time — never resets on tab swap.
        // .transaction strips any withAnimation() calls from parent views so the
        // gradient update is always instant and never gets caught in a spring/ease.
        TimelineView(.animation) { ctx in
            let phase = ctx.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: Self.cycleDuration) / Self.cycleDuration
            buttonFace(angle: phase * 360.0)
        }
        .transaction { $0.animation = nil }
    }

    private func buttonFace(angle: Double) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("EXPLORE")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            // Fixed color background — no material, so no flash when gradient changes
            .background(Capsule().fill(Color.white.opacity(0.12)))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    AngularGradient(
                        colors: [
                            .clear, .clear, .clear,
                            Color.white.opacity(0.18),
                            Color(red: 0.55, green: 0.80, blue: 0.98).opacity(0.55),
                            Color.white.opacity(0.92),
                            Color(red: 0.55, green: 0.80, blue: 0.98).opacity(0.45),
                            Color.white.opacity(0.15),
                            .clear, .clear,
                        ],
                        center: .center,
                        angle: .degrees(angle)
                    ),
                    lineWidth: 1.1
                )
            )
            .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Backdrop

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
    func backdrop() -> some View { self.background(BackdropView()) }
}

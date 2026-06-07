//  HomeView.swift
//  YShop
//
//  Created by Mohammed on 21.01.2026.
//

import SwiftUI

// MARK: - Hero Product Model
struct HeroProduct: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let imagePath: String
    let gradient: [Color]
    let category: String
    let icon: String
}

// MARK: - Native Apple Blur (Liquid Glass)
struct NativeBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var cartManager: CartManager

    @State private var currentHeroIndex = 0
    @State private var searchText = ""
    @State private var heroTimer: Timer?
    @State private var isAIExpanded = false
    @State private var showProfileSheet = false
    @State private var showMyOrdersSheet = false
    @State private var shouldPresentMyOrdersAfterProfileDismiss = false
    @State private var showCartSheet = false
    @State private var selectedCategory: String = ""
    @State private var navigateToCategoryStores = false

    let heroProducts = [
        HeroProduct(name: "PREMIUM FOOD", subtitle: "Gourmet Excellence", imagePath: "9", gradient: [Color(red: 0.16, green: 0.09, blue: 0.06), Color(red: 0.05, green: 0.03, blue: 0.02)], category: "Food", icon: "fork.knife"),
        HeroProduct(name: "HEALTHCARE", subtitle: "Wellness Essentials", imagePath: "Hero", gradient: [Color(red: 0.10, green: 0.15, blue: 0.19), Color(red: 0, green: 0, blue: 0)], category: "Pharmacy", icon: "cross.case.fill"),
        HeroProduct(name: "FASHION", subtitle: "Curated Style", imagePath: "0", gradient: [Color(red: 0.15, green: 0.15, blue: 0.23), Color(red: 0.04, green: 0.04, blue: 0.07)], category: "Clothes", icon: "tshirt.fill"),
        HeroProduct(name: "FRESH MARKET", subtitle: "Farm to Table", imagePath: "1", gradient: [Color(red: 0.18, green: 0.14, blue: 0.09), Color(red: 0.06, green: 0.04, blue: 0.02)], category: "Market", icon: "basket.fill"),
    ]

    var body: some View {
        ZStack {
            NavigationLink(destination: CategoryStoresView(categoryName: selectedCategory), isActive: $navigateToCategoryStores) { EmptyView() }.hidden()

            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: heroProducts[currentHeroIndex].gradient), startPoint: .top, endPoint: .bottom).ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer()

                        VStack {
                            Text("YSHOP").font(.system(size: 42, weight: .semibold)).tracking(4).foregroundColor(.white)
                        }.frame(maxWidth: .infinity).frame(height: 80)

                        Spacer()

                        if let uiImage = UIImage(named: heroProducts[currentHeroIndex].imagePath) {
                            Image(uiImage: uiImage).resizable().scaledToFit().frame(height: UIScreen.main.bounds.height * 0.25)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.fill").font(.system(size: 48)).foregroundColor(Color(.tertiaryLabel))
                                Text(heroProducts[currentHeroIndex].imagePath).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(.secondaryLabel))
                            }.frame(height: UIScreen.main.bounds.height * 0.25)
                        }

                        Spacer()

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles").foregroundColor(.white)
                                TextField("Ask me anything...", text: $searchText).textFieldStyle(.plain).foregroundColor(.white)
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) { Image(systemName: "xmark").foregroundColor(.white.opacity(0.6)) }
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.15))
                            .backdrop()
                            .cornerRadius(14)
                            .frame(maxWidth: 280)
                        }.padding(.horizontal, 40)

                        Spacer()

                        VStack(spacing: 16) {
                            Text(heroProducts[currentHeroIndex].name).font(.system(size: 42, weight: .light)).tracking(3).foregroundColor(.white).multilineTextAlignment(.center)
                            Text(heroProducts[currentHeroIndex].subtitle).font(.system(size: 14, weight: .regular)).tracking(1.5).foregroundColor(.white.opacity(0.7))
                            Button(action: { selectedCategory = heroProducts[currentHeroIndex].category; navigateToCategoryStores = true }) {
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
                                .background {
                                    if #available(iOS 26, *) {
                                        Color.clear.glassEffect(in: Capsule())
                                    } else {
                                        Capsule().fill(.ultraThinMaterial.opacity(0.8))
                                    }
                                }
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.38, green: 0.72, blue: 1.0).opacity(0.75),
                                                Color.white.opacity(0.5),
                                                Color(red: 1.0, green: 0.48, blue: 0.78).opacity(0.65),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.2
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 14, y: 5)
                            }.padding(.top, 12)
                        }

                        Spacer().frame(height: 120)
                    }
                }
            }
            .frame(maxHeight: .infinity)
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
            let threshold: CGFloat = 50
            if value.translation.width > threshold {
                changeProduct((currentHeroIndex - 1 + heroProducts.count) % heroProducts.count)
            } else if value.translation.width < -threshold {
                changeProduct((currentHeroIndex + 1) % heroProducts.count)
            }
        })
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
            NavigationStack { MyOrdersView().environmentObject(authManager).environmentObject(cartManager) }
        }
        .sheet(isPresented: $showCartSheet) { CartView(showsCloseButton: true) }
        .onAppear { startAutoRotate() }
        .onDisappear { heroTimer?.invalidate() }
    }

    // MARK: - Methods
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
    func backdrop() -> some View { self.background(BackdropView()) }
}

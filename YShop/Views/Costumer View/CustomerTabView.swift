import SwiftUI

// MARK: - Tab Enum

enum AppTab: String, Hashable, CaseIterable {
    case home    = "home"
    case search  = "search"
    case cart    = "cart"
    case orders  = "orders"
    case profile = "profile"
}

// MARK: - CustomerTabView

struct CustomerTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var cartManager: CartManager
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                nativeTabView
            } else {
                legacyTabView
            }
        }
        .onChange(of: cartManager.pendingTrackingOrderId) { id in
            guard id != nil else { return }
            selectedTab = .home
        }
    }

    // MARK: iOS 18+ — Native floating tab bar (sidebarAdaptable)

    @available(iOS 18.0, *)
    private var nativeTabView: some View {
        TabView(selection: $selectedTab) {

            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView()
                        .environmentObject(authManager)
                        .environmentObject(cartManager)
                }
            }

            Tab(value: AppTab.search, role: .search) {
                NavigationStack {
                    SearchView()
                        .environmentObject(authManager)
                        .environmentObject(cartManager)
                }
            }

            Tab("Cart", systemImage: "bag", value: AppTab.cart) {
                NavigationStack {
                    CartView()
                        .environmentObject(authManager)
                        .environmentObject(cartManager)
                }
            }
            .badge(cartManager.itemCount > 0 ? cartManager.itemCount : 0)

            Tab("Orders", systemImage: "list.bullet.rectangle", value: AppTab.orders) {
                NavigationStack {
                    OrdersView()
                        .environmentObject(authManager)
                        .environmentObject(cartManager)
                }
            }

            Tab("Profile", systemImage: "person", value: AppTab.profile) {
                NavigationStack {
                    ProfileView()
                        .environmentObject(authManager)
                        .environmentObject(cartManager)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .overlay(alignment: .bottomTrailing) {
            if selectedTab != .cart {
                TrackingOrderFloatingButton()
                    .padding(.trailing, 18)
                    .padding(.bottom, 88)
            }
        }
    }

    // MARK: iOS 17 — Standard TabView (fallback)

    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack {
                SearchView()
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            NavigationStack {
                CartView()
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
            .tabItem { Label("Cart", systemImage: "bag") }
            .tag(AppTab.cart)
            .badge(cartManager.itemCount > 0 ? cartManager.itemCount : 0)

            NavigationStack {
                OrdersView()
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
            .tabItem { Label("Orders", systemImage: "list.bullet.rectangle") }
            .tag(AppTab.orders)

            NavigationStack {
                ProfileView()
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(AppTab.profile)
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedTab != .cart {
                TrackingOrderFloatingButton()
                    .padding(.trailing, 18)
                    .padding(.bottom, 76)
            }
        }
    }
}

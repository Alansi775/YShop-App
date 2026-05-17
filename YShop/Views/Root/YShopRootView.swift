//
//  YShopRootView.swift
//  YSHOP
//
//  Top-level coordinator. Presents the splash sequence, then crossfades
//  to the LoginView. Use this as your @main App's root view.
//
//  In your @main App struct:
//    WindowGroup { YShopRootView() }
//

import SwiftUI

struct YShopRootView: View {
    
    @State private var stage: Stage = .splash
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var cartManager: CartManager

    enum Stage {
        case splash
        case deciding
        case login
    }

    var body: some View {
        ZStack {
            switch stage {
            case .splash:
                YShopSplashView {
                    // After splash finishes, move to deciding stage where we wait
                    // for AuthManager to confirm login state, then route accordingly.
                    withAnimation(.easeInOut(duration: 0.5)) {
                        stage = .deciding
                    }
                    // Trigger a fresh auth verification (harmless if already running)
                    Task { await MainActor.run { authManager.checkAuthStatus() } }
                }
                .transition(.opacity)

            case .deciding:
                // Show a lightweight loading view while AuthManager resolves state
                Group {
                    if authManager.isLoggedIn, let role = authManager.userRole {
                        // Navigate to appropriate main area
                        if role == .customer {
                            ZStack(alignment: .bottomTrailing) {
                                // Show HomeView inside a NavigationView initially (no bottom tab bar)
                                NavigationView {
                                    HomeView()
                                }

                                TrackingOrderFloatingButton()
                                    .padding(.trailing, 18)
                                    .padding(.bottom, 22)
                            }
                        } else {
                            DeliveryHomeView()
                        }
                    } else if !authManager.isLoggedIn {
                        // Not logged in -> show LoginView
                        LoginView()
                            .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    } else {
                        // Fallback loading indicator
                        VStack { ProgressView().scaleEffect(1.2) }
                    }
                }

            case .login:
                LoginView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: stage)
    }
}

#Preview {
    YShopRootView()
}

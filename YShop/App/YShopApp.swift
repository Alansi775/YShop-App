//
//  YShopApp.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import SwiftUI

@main
struct YShopApp: App {
    // Use the singleton instance to match what LoginViewModel updates
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var locationManager = LocationManager()

    init() {
        UIFont.registerCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Main Content
                Group {
                    // Only show TabViews if logged in AND have a valid role
                    if authManager.isLoggedIn && authManager.userRole != nil {
                        if authManager.userRole == .customer {
                            NavigationView {
                                HomeView()
                            }
                        } else if authManager.userRole == .driver {
                            DeliveryTabView()
                        } else {
                            LoginView()
                        }
                    } else {
                        LoginView()
                    }
                }
                
                // Offline Banner
                if !networkMonitor.isConnected {
                    VStack {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.white)
                            Text("No Internet")
                                .foregroundColor(.white)
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.9))
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .environmentObject(authManager)
            .onAppear {
                // Check auth status when app starts
                authManager.checkAuthStatus()
            }
        }
    }
}

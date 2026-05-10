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
    @StateObject private var cartManager = CartManager.shared
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
                
                // Main Content: always show the root coordinator (handles splash -> routing)
                YShopRootView()
                
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
            .environmentObject(cartManager)
        }
    }
}

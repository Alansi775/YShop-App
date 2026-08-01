//
//  YShopApp.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import SwiftUI
import AppIntents
import UserNotifications

@main
struct YShopApp: App {
    // Use the singleton instance to match what LoginViewModel updates
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var cartManager = CartManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var locationManager = LocationManager()

    init() {
        UIFont.registerCustomFonts()
        YShopShortcutsProvider.updateAppShortcutParameters()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Main Content: always show the root coordinator (handles splash -> routing)
                YShopRootView()
                
                // Offline banner — a floating capsule below the notch, matching
                // the native iOS "system alert" style (AirDrop/Live Activity
                // bubbles), not an old full-width colored bar.
                VStack {
                    if !networkMonitor.isConnected {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 13, weight: .semibold))
                            Text("No Connection")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial.opacity(0.001), in: Capsule())
                        .background(Color.black.opacity(0.82), in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: networkMonitor.isConnected)
            }
            .environmentObject(authManager)
            .environmentObject(cartManager)
            .environmentObject(locationManager)
            .onOpenURL { url in
                guard url.scheme == "yshop" else { return }
                let orderId = url.lastPathComponent
                switch url.host {
                case "track":
                    // Active order → open tracking sheet via the floating button mechanism
                    CartManager.shared.presentTrackingOrder(id: orderId)
                case "history":
                    // Delivered order → open My Orders sheet
                    NotificationCenter.default.post(name: .yshopOpenMyOrders, object: nil)
                default:
                    break
                }
            }
        }
    }
}

extension Notification.Name {
    static let yshopOpenMyOrders = Notification.Name("yshop.openMyOrders")
}

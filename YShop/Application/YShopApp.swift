//
//  YShopApp.swift
//  YShop
//
//  Created by Mohammed on 26.12.2024.
//

import SwiftUI
import FirebaseCore
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
                     = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct YShopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            SignInView() // Replace with your app's starting view
        }
    }
}

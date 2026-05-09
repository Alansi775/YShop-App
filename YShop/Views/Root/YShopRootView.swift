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
    
    enum Stage {
        case splash
        case login
    }
    
    var body: some View {
        ZStack {
            switch stage {
            case .splash:
                YShopSplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        stage = .login
                    }
                }
                .transition(.opacity)
                
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

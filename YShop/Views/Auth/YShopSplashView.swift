//
//  YShopSplashView.swift
//  YSHOP
//
//  Elegant splash with letter-by-letter reveal animation
//

import SwiftUI

struct YShopSplashView: View {
    
    var onFinish: () -> Void
    
    @State private var displayedLetterCount = 0
    @State private var taglineOpacity: Double = 0
    @State private var compositionOffset: CGFloat = 20
    @State private var compositionOpacity: Double = 1
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let logo = "YSHOP"
    let tagline = "EVERYTHING DELIVERED"
    
    var body: some View {
        ZStack {
            // White background
            Color.yshopCanvasDynamic
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Animated Wordmark — Letter by Letter
                HStack(spacing: 0) {
                    Spacer()
                    ForEach(0..<logo.count, id: \.self) { index in
                        let char = String(logo[logo.index(logo.startIndex, offsetBy: index)])
                        Text(char)
                            .font(.system(size: 72, weight: .black, design: .default))
                            .tracking(-1)
                            .foregroundStyle(Color.yshopInkDynamic)
                            .opacity(index < displayedLetterCount ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.12)
                                    .delay(Double(index) * 0.1),
                                value: displayedLetterCount
                            )
                    }
                    Spacer()
                }
                
                // Tagline — Subtle fade in
                Text(tagline)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .tracking(3)
                    .foregroundStyle(Color.yshopGoldDynamic)
                    .opacity(taglineOpacity)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .offset(y: compositionOffset)
            .opacity(compositionOpacity)
        }
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .task {
            await runSequence()
        }
    }
    
    @MainActor
    private func runSequence() async {
        if reduceMotion {
            displayedLetterCount = logo.count
            taglineOpacity = 1
            try? await Task.sleep(nanoseconds: 800_000_000)
            onFinish()
            return
        }
        
        // Letter-by-letter reveal
        for i in 0...logo.count {
            withAnimation {
                displayedLetterCount = i
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Fade in tagline
        withAnimation(.easeInOut(duration: 0.5)) {
            taglineOpacity = 1
        }
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        // Fade out
        withAnimation(.easeInOut(duration: 0.4)) {
            compositionOpacity = 0
            compositionOffset = 10
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        onFinish()
    }
    
    private func skip() {
        guard compositionOpacity > 0 else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            compositionOpacity = 0
        }
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            onFinish()
        }
    }
}

#Preview("Splash — Light") {
    YShopSplashView(onFinish: {})
        .preferredColorScheme(.light)
}

#Preview("Splash — Dark") {
    YShopSplashView(onFinish: {})
        .preferredColorScheme(.dark)
}

#Preview("Splash — Light") {
    YShopSplashView(onFinish: {})
        .preferredColorScheme(.light)
}

#Preview("Splash — Dark") {
    YShopSplashView(onFinish: {})
        .preferredColorScheme(.dark)
}

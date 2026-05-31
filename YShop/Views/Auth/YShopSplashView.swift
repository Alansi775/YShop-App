//
//  YShopSplashView.swift
//  YSHOP
//
//  Premium Startup-Style Splash with Cinematic Reveal & Fluid Shimmer
//

import SwiftUI

// MARK: - Splash Letter (Cinematic Reveal + Shimmer)

private struct SplashLetter: View {
    let char: String
    let isVisible: Bool
    let isShimmering: Bool
    let shimmerColor: Color
    
    @State private var shimmerProgress: CGFloat = -1.0
    
    var body: some View {
        Text(char)
            .font(.system(size: 64, weight: .bold, design: .default))
            .tracking(4) // تباعد أنيق ومودرن
            .foregroundStyle(Color.primary)
            // تأثير الدخول السينمائي (Blur + Scale)
            .scaleEffect(isVisible ? 1.0 : 0.85)
            .blur(radius: isVisible ? 0 : 10)
            .opacity(isVisible ? 1 : 0)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: shimmerColor.opacity(0.9), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2.5)
                    .offset(x: geo.size.width * shimmerProgress)
                }
                .mask(
                    Text(char)
                        .font(.system(size: 64, weight: .bold, design: .default))
                        .tracking(4)
                )
            )
            .animation(.easeOut(duration: 0.6), value: isVisible)
            .onChange(of: isShimmering) { _, newValue in
                if newValue {
                    shimmerProgress = -1.0
                    withAnimation(.easeInOut(duration: 0.8)) {
                        shimmerProgress = 1.5
                    }
                }
            }
    }
}

// MARK: - Splash View

struct YShopSplashView: View {
    
    var onFinish: () -> Void
    
    @State private var displayedLetterCount = 0
    @State private var shimmerStates: [Bool] = []
    @State private var taglineOpacity: Double = 0
    @State private var compositionOffset: CGFloat = 15
    @State private var compositionOpacity: Double = 1
    @State private var backgroundGlowScale: CGFloat = 0.8
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    let logo = "YSHOP"
    let tagline = "E V E R Y T H I N G   D E L I V E R E D" // مسافات واسعة لمظهر فاخر
    
    // لون الشيمر الأزرق النظيف
    private var shimmerBlue: Color {
        Color(red: 0.2, green: 0.6, blue: 1.0)
    }
    
    var body: some View {
        ZStack {
            // خلفية النظام الأساسية
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // هالة ضوئية محيطية خلف الشعار (Ambient Glow)
            Circle()
                .fill(shimmerBlue.opacity(colorScheme == .dark ? 0.07 : 0.04))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .scaleEffect(backgroundGlowScale)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: backgroundGlowScale)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Animated Wordmark
                HStack(spacing: 0) {
                    Spacer()
                    ForEach(0..<logo.count, id: \.self) { index in
                        let char = String(logo[logo.index(logo.startIndex, offsetBy: index)])
                        
                        SplashLetter(
                            char: char,
                            isVisible: index < displayedLetterCount,
                            isShimmering: index < shimmerStates.count && shimmerStates[index],
                            shimmerColor: shimmerBlue
                        )
                    }
                    Spacer()
                }
                
                // Tagline — Minimalist Fade in
                Text(tagline)
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .tracking(2)
                    .foregroundStyle(Color.secondary)
                    .opacity(taglineOpacity)
                    .offset(y: taglineOpacity == 1 ? 0 : 5)
                    .animation(.easeOut(duration: 0.8), value: taglineOpacity)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .offset(y: compositionOffset)
            .opacity(compositionOpacity)
        }
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .task {
            // تشغيل نبض الخلفية فوراً
            backgroundGlowScale = 1.2
            await runSequence()
        }
    }
    
    @MainActor
    private func runSequence() async {
        shimmerStates = Array(repeating: false, count: logo.count)
        
        if reduceMotion {
            displayedLetterCount = logo.count
            taglineOpacity = 1
            try? await Task.sleep(nanoseconds: 800_000_000)
            onFinish()
            return
        }
        
        // Letter-by-letter cinematic reveal
        for i in 0..<logo.count {
            displayedLetterCount = i + 1
            
            // سرعة ظهور الأحرف متتالية
            try? await Task.sleep(nanoseconds: 120_000_000) // 0.12s
            
            shimmerStates[i] = true
            
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
        }
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // ظهور الشعار اللفظي بسلاسة
        taglineOpacity = 1
        
        // وقت كافي للمستخدم للاستمتاع بالمظهر
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // خروج أنيق (Fade out & Slight move up)
        withAnimation(.easeInOut(duration: 0.5)) {
            compositionOpacity = 0
            compositionOffset = -10
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        onFinish()
    }
    
    private func skip() {
        guard compositionOpacity > 0 else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            compositionOpacity = 0
            compositionOffset = -10
        }
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
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

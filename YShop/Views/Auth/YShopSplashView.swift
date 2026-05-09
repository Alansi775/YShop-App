//
//  YShopSplashView.swift
//  YSHOP
//
//  Elegant splash with letter-by-letter reveal + traveling shimmer wave
//

import SwiftUI

// MARK: - Splash Letter (one-shot shimmer)

private struct SplashLetter: View {
    let char: String
    let isVisible: Bool
    let isShimmering: Bool
    let shimmerColor: Color
    
    @State private var shimmerProgress: CGFloat = -1.0
    
    var body: some View {
        Text(char)
            .font(.system(size: 72, weight: .black, design: .default))
            .tracking(-1)
            .foregroundStyle(Color.yshopInkDynamic)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: shimmerColor.opacity(0.85), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * shimmerProgress)
                }
            )
            .mask(
                Text(char)
                    .font(.system(size: 72, weight: .black, design: .default))
                    .tracking(-1)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.12), value: isVisible)
            .onChange(of: isShimmering) { _, newValue in
                if newValue {
                    // ابدأ من اليسار خارج الحرف
                    shimmerProgress = -1.0
                    // وحرّك الـ shimmer ليعبر الحرف ويخرج من اليمين
                    withAnimation(.linear(duration: 0.5)) {
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
    @State private var compositionOffset: CGFloat = 20
    @State private var compositionOpacity: Double = 1
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let logo = "YSHOP"
    let tagline = "EVERYTHING DELIVERED"
    
    // نفس الأزرق الفاتح اللي اخترناه في LoginView
    private var shimmerBlue: Color {
        Color(red: 0.4, green: 0.7, blue: 1.0)
    }
    
    var body: some View {
        ZStack {
            //  نفس خلفية LoginView بالضبط - يطابق Light & Dark Mode
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Animated Wordmark — Letter by Letter with Traveling Shimmer
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
        // تهيئة مصفوفة الـ shimmer states
        shimmerStates = Array(repeating: false, count: logo.count)
        
        if reduceMotion {
            displayedLetterCount = logo.count
            taglineOpacity = 1
            try? await Task.sleep(nanoseconds: 800_000_000)
            onFinish()
            return
        }
        
        //  Letter-by-letter reveal مع موجة shimmer متتابعة
        for i in 0..<logo.count {
            // 1. ظهور الحرف الحالي
            displayedLetterCount = i + 1
            
            // 2. تأخير بسيط جداً عشان الحرف يبين قبل ما يبدأ الـ shimmer
            try? await Task.sleep(nanoseconds: 80_000_000) // 0.08s
            
            // 3. تشغيل shimmer على الحرف (يمر مرة وحدة على شكل موجة)
            shimmerStates[i] = true
            
            // 4. انتظار قبل الانتقال للحرف التالي (الموجة "تخرج" والحرف اللي بعده يبدأ)
            try? await Task.sleep(nanoseconds: 320_000_000) // 0.32s
        }
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        // Fade in tagline
        withAnimation(.easeInOut(duration: 0.5)) {
            taglineOpacity = 1
        }
        try? await Task.sleep(nanoseconds: 900_000_000)
        
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

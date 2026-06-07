//  AppleStretchyTabBar.swift
//  YShop
//
//  Created by Mohammed on 8.06.2026.
//

import SwiftUI

struct AppleStretchyTabBar: View {
    @Binding var selectedIndex: Int
    let icons: [String]
    var onSelect: (Int) -> Void

    @State private var isDragging = false
    @State private var isActive = false      // true عند اللمس (press أو drag)
    @State private var dragLocation: CGFloat = 0

    private let barHeight: CGFloat = 58
    // حالة عادية — صغير داخل الـ bar
    private let lensIdleSize: CGFloat = 48
    // حالة ضغط/سحب — كبير يبرز من فوق وتحت
    private let lensActiveH: CGFloat = 80
    private let lensActiveW: CGFloat = 62

    var body: some View {
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(icons.count)

            let lensX = isDragging
                ? min(max(dragLocation, lensIdleSize / 2), geo.size.width - lensIdleSize / 2)
                : tabWidth * (CGFloat(selectedIndex) + 0.5)

            // الحجم يتغير بين الحالة العادية والمضغوطة
            let lensH: CGFloat = (isActive || isDragging) ? lensActiveH : lensIdleSize
            let lensW: CGFloat = isDragging
                ? min(tabWidth * 1.52, tabWidth + 28)
                : (isActive ? lensActiveW : lensIdleSize)

            ZStack {
                // Bar background
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.28), radius: 16, y: 6)
                    .frame(height: barHeight)

                // أيقونات خلفية خافتة
                HStack(spacing: 0) {
                    ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white.opacity(0.38))
                            .frame(width: tabWidth, height: barHeight)
                    }
                }

                // الـ lens — صغير عادي، كبير عند الضغط
                lensView(width: lensW, height: lensH)
                    .position(x: lensX, y: geo.size.height / 2)
                    .animation(
                        isDragging
                            ? .interactiveSpring(response: 0.22, dampingFraction: 0.78)
                            : .spring(response: 0.42, dampingFraction: 0.72),
                        value: lensX
                    )
                    .animation(.spring(response: 0.30, dampingFraction: 0.62), value: lensW)
                    .animation(.spring(response: 0.30, dampingFraction: 0.62), value: lensH)

                // أيقونات داخل الـ lens — أكبر، مكبّرة، مخفية بالـ mask
                HStack(spacing: 0) {
                    ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                        Image(systemName: icon)
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: tabWidth, height: lensActiveH)
                    }
                }
                .mask {
                    Capsule()
                        .frame(width: lensW, height: lensH)
                        .position(x: lensX, y: geo.size.height / 2)
                        .animation(
                            isDragging
                                ? .interactiveSpring(response: 0.22, dampingFraction: 0.78)
                                : .spring(response: 0.42, dampingFraction: 0.72),
                            value: lensX
                        )
                        .animation(.spring(response: 0.30, dampingFraction: 0.62), value: lensW)
                        .animation(.spring(response: 0.30, dampingFraction: 0.62), value: lensH)
                }

                // مناطق اللمس للـ tap
                HStack(spacing: 0) {
                    ForEach(0..<icons.count, id: \.self) { index in
                        Color.clear
                            .frame(width: tabWidth, height: barHeight)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                                    onSelect(index)
                                }
                            }
                    }
                }
            }
            .frame(height: lensActiveH)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        // الـ lens يكبر عند أول لمس
                        if !isActive {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.60)) {
                                isActive = true
                            }
                        }
                        // تفعيل السحب فقط إذا تحرك الإصبع أكثر من 4px
                        if abs(value.translation.width) > 4 {
                            if !isDragging { isDragging = true }
                            dragLocation = min(
                                max(value.location.x, lensIdleSize / 2),
                                geo.size.width - lensIdleSize / 2
                            )
                            let newIndex = min(max(Int(dragLocation / tabWidth), 0), icons.count - 1)
                            if newIndex != selectedIndex {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedIndex = newIndex
                                    onSelect(newIndex)
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        if isDragging {
                            let finalIndex = min(max(Int(dragLocation / tabWidth), 0), icons.count - 1)
                            onSelect(finalIndex)
                        }
                        // الـ lens يرجع صغير عند رفع الإصبع
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                            isActive = false
                            isDragging = false
                        }
                    }
            )
        }
        .frame(height: lensActiveH)
    }

    @ViewBuilder
    private func lensView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if #available(iOS 26, *) {
                Color.clear.glassEffect(in: Capsule())
            } else {
                Capsule().fill(.regularMaterial)
            }
            // إطار ملوّن يحاكي انكسار الضوء في العدسة الزجاجية
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.38, green: 0.72, blue: 1.0).opacity(0.75),
                            Color.white.opacity(0.5),
                            Color(red: 1.0, green: 0.48, blue: 0.78).opacity(0.65),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.3), radius: 14, y: 5)
    }
}

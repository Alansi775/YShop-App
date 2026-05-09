import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var isShimmering = false
    
    // اللون المخصص للـ shimmer (اختياري) - إذا nil يستخدم اللون الافتراضي
    var shimmerColor: Color? = nil
    var intensity: Double = 0.2
    var duration: Double = 2.0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(.systemBackground).opacity(0), location: 0),
                        .init(
                            color: (shimmerColor ?? Color(.label)).opacity(intensity),
                            location: 0.5
                        ),
                        .init(color: Color(.systemBackground).opacity(0), location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isShimmering ? 500 : -500)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    isShimmering = true
                }
            }
    }
}

extension View {
    /// Shimmer افتراضي (أبيض/أسود حسب الـ Mode) - زي ما كان من قبل
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    /// Shimmer بلون مخصص - مفيد للـ branding (مثلاً اللوقو)
    /// - Parameters:
    ///   - color: لون الـ shimmer
    ///   - intensity: شدة اللون (0.0 - 1.0)، الافتراضي 0.6 للألوان المخصصة عشان تبين
    ///   - duration: مدة الحركة بالثواني، الافتراضي 2.5 ثانية
    func shimmer(
        color: Color,
        intensity: Double = 0.6,
        duration: Double = 2.5
    ) -> some View {
        modifier(ShimmerEffect(
            shimmerColor: color,
            intensity: intensity,
            duration: duration
        ))
    }
}
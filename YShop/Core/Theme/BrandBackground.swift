import SwiftUI

/// The app's single background: clean white / true black, with a slow
/// "aurora" of YShop blue only at the top that fades before the content
struct BrandBackground: View {
    /// 1 = sign-in and splash screens, ~0.6 = content screens
    var intensity: Double = 1
    /// Content screens use the grouped background so cards read as cards
    var grouped = false
    
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var onScreen = false
    
    var body: some View {
        ZStack(alignment: .top) {
            (grouped ? Color(.systemGroupedBackground) : Color(.systemBackground))
            
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion || !onScreen)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    let w = geo.size.width
                    // One quiet blue glow — Apple-white / true black stays the star.
                    blob(.yshopGoldDynamic, size: w * 1.2,
                         x: w * (0.5 + 0.06 * sin(t / 10)), y: 20 + 24 * cos(t / 12),
                         opacity: dark ? 0.16 : 0.08)
                    .opacity(intensity)
                }
            }
            .frame(height: 560)
            .mask(LinearGradient(stops: [.init(color: .black, location: 0),
                                         .init(color: .black, location: 0.35),
                                         .init(color: .clear, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear{ onScreen = true }
        .onDisappear { onScreen = false }
    }
    private var dark: Bool { scheme == .dark }
    /// A soft circle drawn as a radial gradient: looks blurred but costs
    /// almost nothing per frame (a live blur would make scrolling stutter)
    private func blob(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        let extent = size + 140
        return Circle()
            .fill(RadialGradient(stops: [.init(color: color.opacity(opacity), location: 0),
                                         .init(color: color.opacity(opacity * 0.85), location: 0.38),
                                         .init(color: color.opacity(0), location: 1)],
                                 center: .center, startRadius: 0, endRadius: extent / 2))
            .frame(width: extent, height: extent)
            .position(x: x, y: y)
    }
}

#Preview("Light") { BrandBackground().preferredColorScheme(.light) }
#Preview("Dark") { BrandBackground().preferredColorScheme(.dark) }

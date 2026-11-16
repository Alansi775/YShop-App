import SwiftUI

/// The opening shot — about 2.4 s, tap to skip.
///
/// 1. A soft living mesh of light wakes up behind an empty screen.
/// 2. The camera glides in on a tilted plane; the glyphs of YSHOP resolve
///    one by one out of depth and blur (per-glyph `TextRenderer`), the wide
///    tracking collapsing into a tight wordmark.
/// 3. A drop of Liquid Glass slides across the word like a lens.
/// 4. The tagline resolves, then the camera pushes through into the app.
struct LaunchSplash: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    @State private var reveal: Double = 0       // 0…1 glyph resolve
    @State private var tilt: Double = 28        // camera plane, degrees
    @State private var tracking: CGFloat = 26
    @State private var lens: CGFloat = -1       // glass lens x, −1…1
    @State private var lensOn = false
    @State private var tagline: Double = 0
    @State private var pushThrough = false
    @State private var finished = false
    @State private var start = Date.now

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            light.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("YSHOP")
                    .font(.system(size: 68, weight: .heavy, design: .default))
                    .tracking(tracking)
                    .foregroundStyle(.primary)
                    .textRenderer(GlyphReveal(progress: reveal))
                    .overlay {
                        GeometryReader { geo in
                            Capsule()
                                .fill(.clear)
                                .frame(width: 74, height: 96)
                                .glassEffect(.clear, in: .capsule)
                                .position(x: geo.size.width * (0.5 + lens * 0.55), y: geo.size.height / 2)
                                .opacity(lensOn ? 1 : 0)
                        }
                        .allowsHitTesting(false)
                    }

                Text("Everything, delivered.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textRenderer(GlyphReveal(progress: tagline, spread: 0.5))
            }
            .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: -0.35, z: 0), perspective: 0.55)
            .scaleEffect(pushThrough ? 7 : 1)
            .blur(radius: pushThrough ? 16 : 0)
            .opacity(pushThrough ? 0 : 1)
        }
        .contentShape(.rect)
        .onTapGesture { finish() }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: reveal == 1)
        .task { await play() }
    }

    /// A slow monochrome mesh with one breath of brand blue.
    private var light: some View {
        TimelineView(.animation(paused: reduceMotion || finished)) { ctx in
            let t = Float(ctx.date.timeIntervalSince(start))
            let base = Color(.systemBackground)
            let blue = Color.yshopGoldDynamic.opacity(scheme == .dark ? 0.35 : 0.22)
            let grey = Color(.systemGray5)
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5 + 0.12 * sin(t * 0.9), 0.45 + 0.1 * cos(t * 0.7)], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [
                base, grey, base,
                base, blue, base,
                base, base, base,
            ])
            .opacity(min(1, Double(t) * 1.5) * (pushThrough ? 0 : 1))
        }
    }

    @MainActor
    private func play() async {
        start = .now
        if reduceMotion {
            reveal = 1; tagline = 1; tilt = 0; tracking = -1
            try? await Task.sleep(for: .milliseconds(900))
            return finish()
        }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.spring(duration: 1.3, bounce: 0.12)) { tilt = 0 }
        withAnimation(.smooth(duration: 1.1)) { reveal = 1; tracking = -1 }
        try? await Task.sleep(for: .milliseconds(950))

        withAnimation(.smooth(duration: 0.2)) { lensOn = true }
        withAnimation(.easeInOut(duration: 0.8)) { lens = 1 }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(.smooth(duration: 0.7)) { tagline = 1 }
        try? await Task.sleep(for: .milliseconds(500))
        withAnimation(.smooth(duration: 0.2)) { lensOn = false }
        try? await Task.sleep(for: .milliseconds(350))
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.42)) { pushThrough = true }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            onFinish()
        }
    }
}

/// Resolves each glyph in turn out of depth: blurred, enlarged, lifted and
/// transparent → sharp and in place. `progress` animates 0 → 1.
struct GlyphReveal: TextRenderer, Animatable {
    var progress: Double
    /// How much the glyphs overlap in time (0 = one after another, 1 = all at once).
    var spread: Double = 0.35

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        let glyphs = layout.flatMap { $0 }.flatMap { $0 }
        let count = max(glyphs.count, 1)
        let window = spread + (1 - spread) / Double(count)
        for (i, glyph) in glyphs.enumerated() {
            let begin = (1 - window) * Double(i) / Double(max(count - 1, 1))
            let p = min(max((progress - begin) / window, 0), 1)
            let e = 1 - pow(1 - p, 3) // ease-out cubic
            var c = ctx
            let b = glyph.typographicBounds.rect
            c.opacity = e
            c.addFilter(.blur(radius: (1 - e) * 14))
            c.translateBy(x: b.midX, y: b.midY + (1 - e) * 22)
            c.scaleBy(x: 1 + (1 - e) * 0.9, y: 1 + (1 - e) * 0.9)
            c.translateBy(x: -b.midX, y: -b.midY)
            c.draw(glyph)
        }
    }
}

#Preview("Light") { LaunchSplash(onFinish: {}).preferredColorScheme(.light) }
#Preview("Dark") { LaunchSplash(onFinish: {}).preferredColorScheme(.dark) }

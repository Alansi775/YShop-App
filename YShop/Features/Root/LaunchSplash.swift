import SwiftUI

/// The opening shot — about 2.6 s, tap to skip.
///
/// Shot 1 — the four things YShop brings (food, groceries, medicine,
///          clothes) rush past the camera out of the dark.
/// Shot 2 — the camera pulls back: the letters of YSHOP fly in from depth,
///          huge and blurred, and lock into place.
/// Shot 3 — a light sweeps across the word, the tagline lands word by word.
/// Cut   — the camera pushes through the word into the app.
struct LaunchSplash: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var iconsGo = false
    @State private var lettersIn = 0
    @State private var sweep: CGFloat = -1.2
    @State private var taglineWords = 0
    @State private var camera: CGFloat = 1.25   // > 1 = close, settles to 1
    @State private var pushThrough = false
    @State private var finished = false

    private let word = Array("YSHOP")
    private let tagline = ["Everything,", "delivered."]
    private let icons = ["fork.knife", "cart.fill", "cross.case.fill", "tshirt.fill"]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // Shot 1 — icons fly from the vanishing point past the lens.
            ForEach(icons.indices, id: \.self) { i in
                let angle = Double(i) / Double(icons.count) * 2 * .pi + .pi / 4
                Image(systemName: icons[i])
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(i == 0 ? Color.yshopGoldDynamic : .primary)
                    .scaleEffect(iconsGo ? 5 : 0.2)
                    .offset(x: iconsGo ? cos(angle) * 420 : 0, y: iconsGo ? sin(angle) * 520 : 0)
                    .blur(radius: iconsGo ? 14 : 0)
                    .opacity(iconsGo ? 0 : 1)
                    .animation(.easeIn(duration: 0.75).delay(Double(i) * 0.07), value: iconsGo)
            }

            // Shots 2–3 — the word.
            VStack(spacing: 18) {
                HStack(spacing: 2) {
                    ForEach(word.indices, id: \.self) { i in
                        let shown = i < lettersIn
                        Text(String(word[i]))
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(i == 0 ? Color.yshopGoldDynamic : .primary)
                            .scaleEffect(shown ? 1 : 3.2)
                            .offset(x: shown ? 0 : CGFloat(i - 2) * 90, y: shown ? 0 : 30)
                            .blur(radius: shown ? 0 : 18)
                            .opacity(shown ? 1 : 0)
                            .animation(.spring(duration: 0.55, bounce: 0.18), value: shown)
                    }
                }
                .overlay {
                    // Light sweep, masked to the letters.
                    GeometryReader { geo in
                        LinearGradient(colors: [.clear, .white.opacity(0.85), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: geo.size.width * 0.45)
                            .rotationEffect(.degrees(18))
                            .offset(x: geo.size.width * sweep)
                    }
                    .mask {
                        HStack(spacing: 2) {
                            ForEach(word.indices, id: \.self) { i in
                                Text(String(word[i])).font(.system(size: 64, weight: .bold))
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }

                HStack(spacing: 6) {
                    ForEach(tagline.indices, id: \.self) { i in
                        Text(tagline[i])
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                            .opacity(i < taglineWords ? 1 : 0)
                            .offset(y: i < taglineWords ? 0 : 14)
                            .blur(radius: i < taglineWords ? 0 : 6)
                            .animation(.spring(duration: 0.5, bounce: 0.2), value: taglineWords)
                    }
                }
            }
            .scaleEffect(pushThrough ? 9 : camera)
            .blur(radius: pushThrough ? 12 : 0)
            .opacity(pushThrough ? 0 : 1)
        }
        .contentShape(.rect)
        .onTapGesture { finish() }
        .sensoryFeedback(.impact(weight: .light), trigger: lettersIn == word.count)
        .task { await play() }
    }

    @MainActor
    private func play() async {
        if reduceMotion {
            lettersIn = word.count; taglineWords = tagline.count; camera = 1
            try? await Task.sleep(for: .milliseconds(900))
            return finish()
        }
        iconsGo = true
        try? await Task.sleep(for: .milliseconds(450))

        // Camera slowly pulls back over the whole word shot.
        withAnimation(.easeOut(duration: 1.6)) { camera = 1 }
        for i in 1...word.count {
            lettersIn = i
            try? await Task.sleep(for: .milliseconds(80))
        }
        try? await Task.sleep(for: .milliseconds(250))
        withAnimation(.easeInOut(duration: 0.7)) { sweep = 1.4 }

        for i in 1...tagline.count {
            taglineWords = i
            try? await Task.sleep(for: .milliseconds(180))
        }
        try? await Task.sleep(for: .milliseconds(650))
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.45)) { pushThrough = true }
        Task {
            try? await Task.sleep(for: .milliseconds(420))
            onFinish()
        }
    }
}

#Preview("Light") { LaunchSplash(onFinish: {}).preferredColorScheme(.light) }
#Preview("Dark") { LaunchSplash(onFinish: {}).preferredColorScheme(.dark) }

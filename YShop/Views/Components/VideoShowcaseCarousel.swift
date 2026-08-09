// VideoShowcaseCarousel.swift
//
// Cover-flow style video carousel — matches the design ported into the
// Flutter/web app: wide 16:9 cards, adjacent cards peeking in on both
// sides (scaled down + dimmed), swipe-only navigation (no arrow buttons —
// keeps the card area uncluttered), bottom-center text overlay (small
// uppercase kicker, bold title, "Learn More" / "Shop Now" links) over a
// gradient scrim, and pill-style pagination dots below the carousel. Only
// the centered card actually plays; the rest sit paused. Placeholder
// footage (Resources/Videos/) — swap for real product videos whenever
// they're ready, same view either way.
import SwiftUI
import AVFoundation

struct VideoShowcaseItem: Identifiable {
    let id = UUID()
    let filename: String
    let ext: String
    let title: String
    let subtitle: String

    init(filename: String, ext: String = "mp4", title: String, subtitle: String) {
        self.filename = filename
        self.ext = ext
        self.title = title
        self.subtitle = subtitle
    }
}

struct VideoShowcaseCarousel: View {
    // Exposed so the caller can size this view's own frame to match —
    // bumped up from an earlier 0.78 because at that size the carousel
    // read as small/cramped on an iPhone screen; this is still a proper
    // cover-flow (side cards do peek in), just a much bigger, more
    // showcase-like centerpiece.
    static let widthFraction: CGFloat = 0.90

    private let items: [VideoShowcaseItem] = [
        VideoShowcaseItem(filename: "hero1", title: "Featured Selection", subtitle: "Handpicked for You"),
        VideoShowcaseItem(filename: "hero2", title: "New Arrivals", subtitle: "Fresh on YShop"),
        VideoShowcaseItem(filename: "hero3", title: "Best Sellers", subtitle: "Loved by Customers"),
    ]

    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * Self.widthFraction
            let cardHeight = cardWidth * 9 / 16
            let spacing: CGFloat = 12
            // The HStack lays out all cards and is naturally centered on
            // its OWN middle item (index (count-1)/2), not on `currentIndex`.
            // Shifting by just `-currentIndex * step` only cancels that out
            // when currentIndex happens to equal the middle — otherwise the
            // "active" card ends up sitting off to one side instead of
            // centered. This offset re-centers whichever card is actually
            // current, for any index.
            let middleIndex = Double(items.count - 1) / 2.0

            VStack(spacing: 14) {
                HStack(spacing: spacing) {
                    ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                        let delta = abs(Double(i - currentIndex))
                        VideoShowcaseCard(item: item, isActive: i == currentIndex)
                            .frame(width: cardWidth, height: cardHeight)
                            .scaleEffect(1 - min(delta, 1) * 0.14)
                            .opacity(1 - min(delta, 1) * 0.65)
                    }
                }
                .frame(width: geo.size.width, alignment: .center)
                .offset(x: CGFloat(middleIndex - Double(currentIndex)) * (cardWidth + spacing))
                .animation(.easeOut(duration: 0.45), value: currentIndex)
                .frame(width: geo.size.width, height: cardHeight)
                .clipped()
                .contentShape(Rectangle())
                // Own swipe, scoped to just this card area — the caller
                // (HomeView) attaches its own category-swipe gesture only
                // to the hero block above, never to this view, so the two
                // never fight over the same drag. simultaneousGesture keeps
                // this from blocking the page's vertical ScrollView too.
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            let h = value.translation.width
                            let v = value.translation.height
                            guard abs(h) > abs(v), abs(h) > 40 else { return }
                            go(h < 0 ? 1 : -1)
                        }
                )

                HStack(spacing: 6) {
                    ForEach(items.indices, id: \.self) { i in
                        Capsule()
                            .fill(Color.primary.opacity(i == currentIndex ? 0.85 : 0.22))
                            .frame(width: i == currentIndex ? 20 : 6, height: 6)
                            .animation(.easeOut(duration: 0.25), value: currentIndex)
                    }
                }
            }
            .frame(width: geo.size.width, height: cardHeight + 24)
        }
    }

    private func go(_ delta: Int) {
        let count = items.count
        currentIndex = ((currentIndex + delta) % count + count) % count
    }
}

private struct VideoShowcaseCard: View {
    let item: VideoShowcaseItem
    let isActive: Bool

    var body: some View {
        ZStack {
            Color.black
            if let url = Bundle.main.url(forResource: item.filename, withExtension: item.ext) {
                LoopingVideoPlayerView(url: url, isActive: isActive)
            }
            if !isActive {
                Color.black.opacity(0.5)
            }
            LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .bottom, endPoint: .top)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: 130)
                .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(spacing: 6) {
                Text(item.subtitle.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.75))
                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    videoLink("Learn More")
                    videoLink("Shop Now")
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: isActive)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func videoLink(_ text: String) -> some View {
        HStack(spacing: 3) {
            Text(text).font(.system(size: 13, weight: .semibold))
            Image(systemName: "arrow.right").font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
    }
}

// MARK: - Silent, looping video playback

private final class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    func configure(url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: item)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        queuePlayer = player
    }

    func play() { queuePlayer?.play() }
    func pause() { queuePlayer?.pause() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

private struct LoopingVideoPlayerView: UIViewRepresentable {
    let url: URL
    let isActive: Bool

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView()
        view.configure(url: url)
        if isActive { view.play() }
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        isActive ? uiView.play() : uiView.pause()
    }
}

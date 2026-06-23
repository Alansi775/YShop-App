import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Per-step theme (changes with every order status)

struct StepTheme {
    let accent: Color
    let deep: Color   // darker shade for gradient start

    static func resolve(_ s: OrderLiveActivityAttributes.ContentState) -> StepTheme {
        if s.isDelivered {
            return .init(accent: Color(red: 0.18, green: 0.84, blue: 0.46),
                         deep:   Color(red: 0.05, green: 0.52, blue: 0.24))
        }
        if s.isCancelled {
            return .init(accent: Color(red: 1.00, green: 0.27, blue: 0.22),
                         deep:   Color(red: 0.72, green: 0.06, blue: 0.06))
        }
        switch s.statusStep {
        case 1:   // Placed — amber
            return .init(accent: Color(red: 1.00, green: 0.62, blue: 0.04),
                         deep:   Color(red: 0.82, green: 0.38, blue: 0.00))
        case 2 where s.isConfirmed:   // Confirmed — blue (matches tracking icon)
            return .init(accent: Color(red: 0.20, green: 0.47, blue: 0.96),
                         deep:   Color(red: 0.08, green: 0.26, blue: 0.76))
        case 2:   // Preparing — violet
            return .init(accent: Color(red: 0.68, green: 0.34, blue: 0.97),
                         deep:   Color(red: 0.42, green: 0.16, blue: 0.78))
        case 3:   // On the way — electric green
            return .init(accent: Color(red: 0.12, green: 0.86, blue: 0.46),
                         deep:   Color(red: 0.04, green: 0.58, blue: 0.26))
        default:
            return .init(accent: Color(red: 0.20, green: 0.47, blue: 0.96),
                         deep:   Color(red: 0.08, green: 0.26, blue: 0.76))
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [deep, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Icon

private func statusIcon(_ type: String, step: Int) -> String {
    if step == 4 { return "checkmark.seal.fill" }
    if step == 3 { return type.lowercased() == "food" ? "bag.fill" : "shippingbox.fill" }
    switch type.lowercased() {
    case "food":     return "fork.knife"
    case "pharmacy": return "cross.case.fill"
    case "clothes":  return "tshirt.fill"
    case "market":   return "basket.fill"
    default:         return "bag.fill"
    }
}

// MARK: - Widget entry

struct OrderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderLiveActivityAttributes.self) { context in
            let rawId = context.attributes.orderNumber.replacingOccurrences(of: "#", with: "")
            let dest  = context.state.isDelivered ? "history" : "track"
            LockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
                .widgetURL(URL(string: "yshop://\(dest)/\(rawId)"))
        } dynamicIsland: { context in
            let rawId = context.attributes.orderNumber.replacingOccurrences(of: "#", with: "")
            let dest  = context.state.isDelivered ? "history" : "track"
            return DynamicIsland {
                islandExpanded(context)
            } compactLeading: {
                let t = StepTheme.resolve(context.state)
                HStack(spacing: 3) {
                    Text("Y")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(t.accent)
                    Text(context.attributes.orderNumber)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            } compactTrailing: {
                let t = StepTheme.resolve(context.state)
                HStack(spacing: 3) {
                    ForEach(1...4, id: \.self) { s in
                        Capsule()
                            .fill(s <= context.state.statusStep ? t.accent : Color.secondary.opacity(0.22))
                            .frame(width: s == context.state.statusStep ? 13 : 5, height: 5)
                            .animation(.spring(duration: 0.4), value: context.state.statusStep)
                    }
                }
            } minimal: {
                let t = StepTheme.resolve(context.state)
                Image(systemName: statusIcon(
                    context.state.storeType,
                    step: context.state.isDelivered ? 4 : context.state.statusStep
                ))
                .font(.system(size: 12))
                .foregroundStyle(t.accent)
            }
            .widgetURL(URL(string: "yshop://\(dest)/\(rawId)"))
            .keylineTint(StepTheme.resolve(context.state).accent)
        }
    }

    // MARK: Dynamic Island expanded

    @DynamicIslandExpandedContentBuilder
    private func islandExpanded(
        _ ctx: ActivityViewContext<OrderLiveActivityAttributes>
    ) -> DynamicIslandExpandedContent<some View> {

        let theme = StepTheme.resolve(ctx.state)
        let icon  = statusIcon(ctx.state.storeType,
                               step: ctx.state.isDelivered ? 4 : ctx.state.statusStep)

        DynamicIslandExpandedRegion(.leading) {
            HStack(spacing: 10) {
                ZStack {
                    theme.gradient
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: ctx.state.statusStep == 3 && !ctx.state.isDelivered)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(ctx.state.statusTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.accent)
                    Text(ctx.state.storeName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
        }

        DynamicIslandExpandedRegion(.trailing) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(ctx.attributes.totalPrice)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(ctx.attributes.orderNumber)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }

        DynamicIslandExpandedRegion(.bottom) {
            VStack(alignment: .leading, spacing: 7) {
                if let driver = ctx.state.driverName, !driver.isEmpty {
                    Label(driver, systemImage: "person.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                StepTrack(
                    step: ctx.state.statusStep,
                    theme: theme,
                    isCancelled: ctx.state.isCancelled,
                    proximityFraction: ctx.state.proximityFraction,
                    distanceText: ctx.state.distanceText,
                    isDelivered: ctx.state.isDelivered
                )
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Lock Screen card

struct LockScreenView: View {
    let context: ActivityViewContext<OrderLiveActivityAttributes>

    private var theme: StepTheme { StepTheme.resolve(context.state) }
    private var icon: String {
        statusIcon(context.state.storeType,
                   step: context.state.isDelivered ? 4 : context.state.statusStep)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // Gradient icon bubble
            ZStack {
                theme.gradient
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(width: 62, height: 62)
                Image(systemName: icon)
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse,
                                  isActive: context.state.statusStep == 3 && !context.state.isDelivered)
            }

            // Info column
            VStack(alignment: .leading, spacing: 6) {

                // Status — hero element
                Text(context.state.statusTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(theme.accent)

                // Store row + price
                HStack(alignment: .center) {
                    HStack(spacing: 3) {
                        Text("YShop")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.primary)
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(context.state.storeName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Text(context.attributes.totalPrice)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }

                // Progress — Y badge slides along the track; glides live during delivery
                StepTrack(
                    step: context.state.statusStep,
                    theme: theme,
                    isCancelled: context.state.isCancelled,
                    proximityFraction: context.state.proximityFraction,
                    distanceText: context.state.distanceText,
                    isDelivered: context.state.isDelivered
                )

                // Driver name (when on the way or delivered)
                if let driver = context.state.driverName, !driver.isEmpty,
                   context.state.statusStep >= 3 || context.state.isDelivered {
                    Label(driver, systemImage: "person.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Step progress track with sliding Y badge

struct StepTrack: View {
    let step: Int
    let theme: StepTheme
    let isCancelled: Bool
    var proximityFraction: Double = 0.0  // 0–0.95 while driving; 1.0 when delivered
    var distanceText: String? = nil       // "800 m away" shown under "On Way" label
    var isDelivered: Bool = false

    private let labels = ["Placed", "Prep", "On Way", "Done"]

    // Normalised position (0–1) of the Y badge along the usable track.
    // Steps 1-2 snap to fixed positions; step 3 glides with driver proximity.
    private var badgeFraction: Double {
        if isCancelled { return 0 }
        if isDelivered || step >= 4 { return 1 }
        switch step {
        case 1:  return 0
        case 2:  return 1.0 / 3.0
        case 3:
            // Glide from the 2/3 mark toward the end as the driver approaches.
            // proximityFraction tops out at 0.95 so the badge never reaches
            // the "Done" dot until the status actually becomes delivered.
            let base = 2.0 / 3.0
            return base + (1.0 - base) * min(1, proximityFraction / 0.95)
        default: return 0
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Track — Y badge glides over 4 checkpoint dots on a gradient rail
            GeometryReader { geo in
                let badge: CGFloat = 20      // Y badge diameter
                let rail:  CGFloat = 4       // rail height
                let dot:   CGFloat = 7       // checkpoint dot diameter
                // Usable track spans from badge/2 to width-badge/2 so the badge
                // never clips outside the frame at either end.
                let usable: CGFloat  = geo.size.width - badge
                let f: CGFloat       = CGFloat(badgeFraction)
                let badgeX: CGFloat  = usable * f   // leading edge of the badge

                // Background rail (spans the usable portion, vertically centred)
                Capsule()
                    .fill(Color.secondary.opacity(0.14))
                    .frame(width: geo.size.width - badge, height: rail)
                    .offset(x: badge / 2, y: (badge - rail) / 2)

                // Filled gradient trail up to the badge's current position
                if !isCancelled && f > 0 {
                    Capsule()
                        .fill(theme.gradient)
                        .frame(width: max(0, usable * f), height: rail)
                        .offset(x: badge / 2, y: (badge - rail) / 2)
                        .animation(.spring(duration: 0.7), value: f)
                }

                // Checkpoint dots at each of the 4 step positions
                ForEach(0..<4, id: \.self) { i in
                    let cx: CGFloat = badge / 2 + usable * CGFloat(i) / 3.0
                    let reached = !isCancelled && (i + 1) <= step
                    Circle()
                        .fill(reached ? theme.accent.opacity(0.55) : Color.clear)
                        .frame(width: dot, height: dot)
                        .overlay(
                            Circle().stroke(
                                Color.secondary.opacity(reached ? 0 : 0.32),
                                lineWidth: 1.1
                            )
                        )
                        .offset(x: cx - dot / 2, y: (badge - dot) / 2)
                }

                // Moving Y badge — the primary visual indicator
                if !isCancelled {
                    Text("Y")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: badge, height: badge)
                        .background(Circle().fill(theme.gradient))
                        .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1.2))
                        .shadow(color: theme.accent.opacity(0.55), radius: 6)
                        .offset(x: badgeX)
                        .animation(.spring(duration: 0.65, bounce: 0.18), value: badgeX)
                }
            }
            .frame(height: 20)

            // Labels row — "On Way" gains a distance subtitle while driving
            HStack(spacing: 0) {
                ForEach(labels.indices, id: \.self) { i in
                    let isCurrent = (i + 1) == step || (isDelivered && i == 3)
                    let isPast    = !isCancelled && (i + 1) < step
                    VStack(spacing: 1) {
                        Text(labels[i])
                            .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                            .foregroundStyle(
                                (isCurrent || isPast) && !isCancelled
                                    ? theme.accent
                                    : Color.secondary.opacity(0.48)
                            )
                        if i == 2, step == 3, let dist = distanceText {
                            Text(dist)
                                .font(.system(size: 7, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    if i < labels.count - 1 { Spacer(minLength: 0) }
                }
            }
        }
    }
}

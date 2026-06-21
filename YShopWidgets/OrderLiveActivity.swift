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
            LockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
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
            .widgetURL(URL(string: "yshop://order/\(context.attributes.orderNumber)"))
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
                StepTrack(step: ctx.state.statusStep,
                          theme: theme,
                          isCancelled: ctx.state.isCancelled)
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

            // Gradient icon bubble with Y brand badge
            ZStack(alignment: .bottomTrailing) {
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
                // Y monogram badge — accent fill so it's always visible
                Text("Y")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(theme.deep))
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .offset(x: 3, y: 3)
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

                // Progress
                StepTrack(step: context.state.statusStep,
                          theme: theme,
                          isCancelled: context.state.isCancelled)

                // Driver (optional)
                if let driver = context.state.driverName, !driver.isEmpty {
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

// MARK: - Step progress track

struct StepTrack: View {
    let step: Int
    let theme: StepTheme
    let isCancelled: Bool

    private let labels = ["Placed", "Prep", "On Way", "Done"]

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background rail
                    Capsule()
                        .fill(Color.secondary.opacity(0.14))
                        .frame(height: 5)

                    // Filled rail with gradient
                    if !isCancelled && step > 1 {
                        Capsule()
                            .fill(theme.gradient)
                            .frame(width: geo.size.width * CGFloat(step - 1) / 3.0, height: 5)
                            .animation(.spring(duration: 0.6), value: step)
                    }

                    // Step dots
                    HStack(spacing: 0) {
                        ForEach(0...3, id: \.self) { i in
                            let active = (i + 1) <= step && !isCancelled
                            Circle()
                                .fill(active ? theme.accent : Color.clear)
                                .frame(width: 11, height: 11)
                                .overlay(
                                    Circle().stroke(
                                        active ? theme.accent : Color.secondary.opacity(0.35),
                                        lineWidth: 1.5
                                    )
                                )
                                .shadow(color: active ? theme.accent.opacity(0.45) : .clear, radius: 4)
                            if i < 3 { Spacer() }
                        }
                    }
                }
            }
            .frame(height: 11)

            // Labels
            HStack(spacing: 0) {
                ForEach(labels.indices, id: \.self) { i in
                    Text(labels[i])
                        .font(.system(size: 9, weight: (i + 1) == step ? .bold : .regular))
                        .foregroundStyle(
                            (i + 1) <= step && !isCancelled
                                ? theme.accent
                                : Color.secondary.opacity(0.48)
                        )
                    if i < labels.count - 1 { Spacer() }
                }
            }
        }
    }
}

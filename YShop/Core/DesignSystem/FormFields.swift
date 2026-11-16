import SwiftUI

// Grouped form in the style of Settings / Apple Account: one rounded card,
// rows separated by inset hairlines, an icon leading each row.

struct FormCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(.secondarySystemGroupedBackground).opacity(0.92),
                        in: .rect(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5))
    }
}

struct FieldRow: View {
    let icon: String
    let title: String
    @Binding var text: String
    var secure = false
    var keyboard: UIKeyboardType = .default
    var content: UITextContentType?
    var isInvalid = false

    @State private var revealed = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(isInvalid ? Color.red : Color.secondary)
                .frame(width: 22)
                .contentTransition(.symbolEffect(.replace))
            Group {
                if secure && !revealed {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .keyboardType(keyboard)
            .textContentType(content)
            .textInputAutocapitalization(keyboard == .emailAddress || secure ? .never : .words)
            .autocorrectionDisabled(keyboard == .emailAddress || secure)
            .font(.body)
            if secure && !text.isEmpty {
                Button { revealed.toggle() } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(revealed ? "Hide password" : "Show password")
            }
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 56)
        .animation(.smooth(duration: 0.2), value: isInvalid)
    }
}

struct FormDivider: View {
    var body: some View {
        Divider().padding(.leading, 54)
    }
}

/// "────  or  ────"
struct OrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(.quaternary).frame(height: 0.5)
            Text("or").font(.footnote.weight(.medium)).foregroundStyle(.secondary)
            Rectangle().fill(.quaternary).frame(height: 0.5)
        }
    }
}

/// Staggered entrance: each block rises out of a soft blur, one after another.
private struct Appear: ViewModifier {
    let index: Int
    let shown: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .blur(radius: shown || reduceMotion ? 0 : 6)
            .animation(.smooth(duration: 0.7).delay(Double(index) * 0.07), value: shown)
    }
}

extension View {
    func appear(_ index: Int, _ shown: Bool) -> some View { modifier(Appear(index: index, shown: shown)) }
}

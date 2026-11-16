import SwiftUI

// MARK: - Primary button

/// The screen's main button (Sign in, Continue, Place order).
/// Real Liquid Glass with three states: text, spinner while waiting,
/// then a checkmark on success - no screen jumps or new buttons.
struct PrimaryActionButton: View {
    enum Phase: Equatable { case idle, loading, success }
    
    let title: String
    var phase: Phase = .idle
    var isEnabled = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                switch phase {
                case .idle:
                    Text(title)
                        .transition(.blurReplace)
                case .loading:
                    ProgressView()
                        .tint(.white)
                        .transition(.blurReplace)
                case .success:
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .transition(.blurReplace.combined(with: .scale(0.5)))
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .disabled(!isEnabled || phase != .idle)
        .animation(.spring(duration: 0.4, bounce: 0.3), value: phase)
    }
}

// MARK: - Secondary button

/// A clear glass button for secondary actions (Create account, Continue with Google).
struct SecondaryActionButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(.glass)
        .controlSize(.extraLarge)
    }
}

// MARK: - Inline error

/// A red message that slides in under the form; the icon bounces whenever the message changes.
struct InlineError: View {
    let message: String
    
    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .symbolEffect(.bounce, value: message)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Shake on error

/// Shakes a field left and right when the password is wrong — like the iPhone lock screen.
/// Usage: `.shake(attempts)` and increase `attempts` by 1 on every error.

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = 10 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

extension View {
    func shake(_ attempts: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(attempts)))
            .animation(.linear(duration: 0.4), value: attempts)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var phase: PrimaryActionButton.Phase = .idle
    @Previewable @State var attempts = 0
    
    VStack(spacing: 16) {
        InlineError(message: "E-mail or password is incorrect.")
            .shake(attempts)
        PrimaryActionButton(title: "Sign in", phase: phase) {
            phase = .loading
            Task{
                try? await Task.sleep(for: .seconds(1.2))
                phase = .success
                try? await Task.sleep(for: .seconds(1))
                phase = .idle
            }
        }
        SecondaryActionButton(title: "Create account", systemImage: "person.badge.plus") {
            attempts += 1
        }
    }
    .padding(24)
    .background { BrandBackground() }
}

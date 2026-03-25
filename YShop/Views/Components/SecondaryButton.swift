import SwiftUI

struct SecondaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            action()
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color(.secondaryLabel))
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.tertiaryLabel), lineWidth: 1.5)
            )
        }
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isLoading ? 0.7 : 1.0)
        .onLongPressGesture(minimumDuration: 0.01, perform: {}, onPressingChanged: { isPressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = isPressing
                if isPressing {
                    HapticManager.shared.impact(style: .light)
                }
            }
        })
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Login as Driver", isLoading: false) {
            print("Tapped")
        }
        
        SecondaryButton(title: "Loading...", isLoading: true) {
            print("Tapped")
        }
    }
    .padding()
}

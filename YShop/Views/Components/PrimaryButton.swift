import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            action()
        }) {
            ZStack {
                // Black background - elegant and professional
                Color(.label)
                
                if isLoading {
                    ProgressView()
                        .tint(Color(.systemBackground))
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(.systemBackground))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .cornerRadius(14)
            .shadow(color: Color(.label).opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isLoading ? 0.8 : 1.0)
        .onLongPressGesture(minimumDuration: 0.01, perform: {}, onPressingChanged: { isPressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = isPressing
                if isPressing {
                    HapticManager.shared.impact(style: .medium)
                }
            }
        })
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Enter Boutique", isLoading: false) {
            print("Tapped")
        }
        
        PrimaryButton(title: "Loading...", isLoading: true) {
            print("Tapped")
        }
    }
    .padding()
}

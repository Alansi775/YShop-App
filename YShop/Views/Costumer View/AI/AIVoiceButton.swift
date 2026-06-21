import SwiftUI

struct AIVoiceButton: View {
    let isListening: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isListening {
                    Circle()
                        .stroke(Color(red: 0.38, green: 0.72, blue: 1.0).opacity(0.35), lineWidth: 2)
                        .scaleEffect(pulse ? 1.6 : 1.0)
                        .opacity(pulse ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)

                    Circle()
                        .stroke(Color(red: 0.38, green: 0.72, blue: 1.0).opacity(0.2), lineWidth: 2)
                        .scaleEffect(pulse ? 1.9 : 1.0)
                        .opacity(pulse ? 0 : 0.5)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false).delay(0.3), value: pulse)
                }

                Circle()
                    .fill(
                        isListening
                        ? LinearGradient(colors: [Color(red: 0.9, green: 0.25, blue: 0.35), Color(red: 0.7, green: 0.15, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: isListening ? "waveform" : "mic")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .symbolEffect(.variableColor.iterative, isActive: isListening)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .onAppear { if isListening { pulse = true } }
        .onChange(of: isListening) { _, listening in pulse = listening }
    }
}

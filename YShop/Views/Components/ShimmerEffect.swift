import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var isShimmering = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(.systemBackground).opacity(0), location: 0),
                        .init(color: Color(.label).opacity(0.2), location: 0.5),
                        .init(color: Color(.systemBackground).opacity(0), location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isShimmering ? 500 : -500)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    isShimmering = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

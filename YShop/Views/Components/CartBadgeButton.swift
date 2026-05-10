import SwiftUI

struct CartBadgeButton: View {
    let itemCount: Int
    let action: () -> Void
    var iconColor: Color = .white
    var size: CGFloat = 40
    var iconSize: CGFloat = 18

    var body: some View {
        NativeCircleIconButton(
            systemName: "bag.fill",
            action: action,
            iconColor: iconColor,
            size: size,
            iconSize: iconSize
        )
    }
}

struct CartCountBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 17, height: 17)
            .background(Color(red: 0.12, green: 0.58, blue: 0.95))
            .clipShape(Circle())
    }
}
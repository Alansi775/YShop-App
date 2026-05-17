import SwiftUI

struct NativeCircleIconButton: View {
    let systemName: String
    let action: () -> Void
    var iconColor: Color = .white
    var size: CGFloat = 40
    var iconSize: CGFloat = 18
    var showBackground: Bool = false
    var backgroundColor: Color? = nil

    var body: some View {
        Button(action: action) {
            if showBackground {
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: size, height: size)
                    .background(backgroundColor != nil ? AnyShapeStyle(backgroundColor!) : AnyShapeStyle(.bar))
                    .clipShape(Circle())
            } else {
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(iconColor)
            }
        }
    }
}
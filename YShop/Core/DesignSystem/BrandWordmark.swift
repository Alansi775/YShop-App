import SwiftUI

/// The YSHOP wordmark drawn in code — sharp at any size, right in light and
/// dark (the PNG had a white box behind it). Black / white like Apple, only the
/// "Y" carries the quiet brand blue.
struct BrandWordmark: View {
    var size: CGFloat = 44

    var body: some View {
        HStack(spacing: size * 0.04) {
            Text("Y").foregroundStyle(Color.yshopGoldDynamic)
            Text("SHOP").foregroundStyle(.primary)
        }
        .font(.system(size: size, weight: .semibold, design: .default))
        .tracking(size * 0.02)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("YShop")
    }
}

#Preview {
    VStack(spacing: 30) {
        BrandWordmark()
        BrandWordmark(size: 28).preferredColorScheme(.dark)
    }
    .padding()
}

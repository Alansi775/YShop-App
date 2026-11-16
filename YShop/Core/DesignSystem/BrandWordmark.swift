import SwiftUI

/// The YSHOP wordmark drawn in code — sharp at any size, right in light and
/// dark (the PNG had a white box behind it). "YS" in brand blue, "HOP" fading
/// from silver into blue, like the original logo.
struct BrandWordmark: View {
    var size: CGFloat = 44

    var body: some View {
        HStack(spacing: size * 0.04) {
            Text("YS")
                .foregroundStyle(Color.yshopGoldDynamic)
            Text("HOP")
                .foregroundStyle(LinearGradient(colors: [Color(.systemGray), Color.yshopGoldDynamic],
                                                startPoint: .leading, endPoint: .trailing))
        }
        .font(.system(size: size, weight: .regular, design: .default))
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

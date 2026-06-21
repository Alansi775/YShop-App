import SwiftUI

struct AIProductCard: View {
    let product: [String: Any]
    let onAddToCart: () -> Void
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var name: String { product["name"] as? String ?? "Product" }
    private var price: String {
        let d = product["price"] as? Double ?? Double(product["price"] as? String ?? "0") ?? 0
        return String(format: "%.2f", d)
    }
    private var currency: String { product["currency"] as? String ?? "SAR" }

    private var imageURL: URL? {
        let raw = ["image_url", "imageUrl", "image", "thumbnail"]
            .compactMap { product[$0] as? String }
            .first { !$0.isEmpty }
        guard let raw, !raw.isEmpty else { return nil }

        // Extract the path component — works whether backend sent a full URL (with its own IP)
        // or a relative path like /uploads/products/abc.jpg
        let path: String
        if raw.hasPrefix("http"), let parsedURL = URL(string: raw) {
            path = parsedURL.path
        } else {
            path = raw.hasPrefix("/") ? raw : "/\(raw)"
        }
        guard !path.isEmpty else { return nil }

        // Rebuild using URLComponents to avoid string-concat edge cases
        var comps = URLComponents(string: AppConstants.mediaBaseURL)
        comps?.path = path
        comps?.query = nil
        return comps?.url
    }

    private var surface: Color   { Color(UIColor.secondarySystemBackground) }
    private var label: Color     { Color(UIColor.label) }
    private var secondary: Color { Color(UIColor.secondaryLabel) }
    private var accent: Color    { Color(red: 0.24, green: 0.56, blue: 0.96) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                infoSection
                addButton
            }
        }
        .buttonStyle(.plain)
        .frame(width: 160)
        .background(surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var imageSection: some View {
        ZStack {
            surface
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        placeholderIcon
                    case .empty:
                        ProgressView().tint(secondary)
                    @unknown default:
                        placeholderIcon
                    }
                }
                // id forces a fresh load if the URL changes between AI responses
                .id(url.absoluteString)
                .frame(width: 160, height: 130)
                .clipped()
            } else {
                placeholderIcon
            }
        }
        .frame(width: 160, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholderIcon: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: 22))
                .foregroundColor(secondary.opacity(0.5))
        }
        .frame(width: 160, height: 130)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(label)
                .lineLimit(2)
            Text("\(price) \(currency)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
    }

    private var addButton: some View {
        Button(action: onAddToCart) {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                Text("Add to Cart").font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}

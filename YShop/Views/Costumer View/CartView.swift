import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    let showsCloseButton: Bool

    init(showsCloseButton: Bool = false) {
        self.showsCloseButton = showsCloseButton
    }

    private var subtotal: Double {
        cartManager.totalPrice
    }

    private var tax: Double {
        subtotal * 0.1
    }

    private var total: Double {
        subtotal + tax
    }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()

                if cartManager.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if cartManager.cartItems.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(cartManager.cartItems) { item in
                                CartItemRow(item: item)
                            }
                        }
                        .padding(16)
                    }

                    summaryFooter
                }
            }
        }
        .task {
            await cartManager.refreshCart()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Shopping Cart")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(.label))

                Text("\(cartManager.itemCount) items")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            if showsCloseButton {
                NativeCircleIconButton(
                    systemName: "xmark",
                    action: { dismiss() },
                    iconColor: colorScheme == .dark ? .white : .black,
                    size: 35.5,
                    iconSize: 15,
                    showBackground: true
                )
            }
        }
        .padding(16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color(.secondaryLabel))

            Text("Your Cart is Empty")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.label))

            Text("Add items to continue shopping")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private var summaryFooter: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                Text("Subtotal")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))

                Spacer()

                Text(String(format: "%.2f", subtotal))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.label))
            }

            HStack {
                Text("Tax (10%)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))

                Spacer()

                Text(String(format: "%.2f", tax))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.label))
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.label))

                Spacer()

                Text(String(format: "%.2f", total))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.label))
            }

            Button(action: {}) {
                Text("Proceed to Checkout")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
    }
}

struct CartItemRow: View {
    @EnvironmentObject var cartManager: CartManager
    let item: CartItem

    private var imageUrl: String? {
        item.fullImageUrl ?? item.product?.fullImageUrl
    }

    private var displayName: String {
        item.displayName
    }

    private var displayPrice: String {
        item.formattedPrice
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(2)

                Text(displayPrice)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        try? await cartManager.updateQuantity(
                            cartItemId: item.id,
                            quantity: max(1, item.quantity - 1)
                        )
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(width: 24, height: 24)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                }

                Text("\(item.quantity)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.label))

                Button(action: {
                    Task {
                        try? await cartManager.updateQuantity(
                            cartItemId: item.id,
                            quantity: item.quantity + 1
                        )
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black)
                        .cornerRadius(6)
                }

                Button(action: {
                    Task {
                        try? await cartManager.removeItem(item.id)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var placeholder: some View {
        Color(.secondarySystemBackground)
            .overlay(Image(systemName: "photo").foregroundColor(Color(.tertiaryLabel)))
    }
}

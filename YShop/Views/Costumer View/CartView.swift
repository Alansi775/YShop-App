import SwiftUI
import Kingfisher

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    let showsCloseButton: Bool
    @State private var showCheckout = false

    init(showsCloseButton: Bool = false) {
        self.showsCloseButton = showsCloseButton
    }

    private var subtotal: Double {
        cartManager.totalPrice
    }
    
    private var total: Double {
        subtotal
    }

    private var cartCurrencySymbol: String {
        cartManager.cartItems.first?.currencySymbol
            ?? cartManager.cartItems.first?.product?.currencySymbol
            ?? "₺"
    }

    private func formattedTotal(_ amount: Double) -> String {
        "\(cartCurrencySymbol)\(String(format: "%.2f", amount))"
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.04, green: 0.04, blue: 0.05) : Color(.systemGroupedBackground)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // خلفية نظيفة فاخرة
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    if cartManager.isLoading {
                        Spacer()
                        ProgressView().scaleEffect(1.2)
                        Spacer()
                    } else if cartManager.cartItems.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // إظهار عدد العناصر بأسلوب هادئ ونظيف يتماشى مع الـ Inline Title
                                HStack {
                                    Text("\(cartManager.itemCount) items added")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(.secondaryLabel))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 10)

                                ForEach(cartManager.cartItems) { item in
                                    CartItemRow(item: item)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 150) // مساحة مريحة للفوتر العائم
                        }
                    }
                }

                // الفوتر العائم الزجاجي يظهر فقط عند وجود عناصر
                if !cartManager.cartItems.isEmpty && !cartManager.isLoading {
                    floatingSummaryFooter
                        .transition(.move(edge: .bottom))
                }
            }
            // إعدادات الـ Navigation Bar والـ Toolbar المحدثة منك (لم يتم لمس زر x)
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        NativeCircleIconButton(
                            systemName: "xmark",
                            action: { dismiss() },
                            iconColor: .primary,
                            size: 35.5,
                            iconSize: 15,
                            showBackground: false
                        )
                    }
                }
            }
            .animation(.easeInOut, value: cartManager.cartItems.isEmpty)
            .task {
                await cartManager.refreshCart()
            }
            .fullScreenCover(isPresented: $showCheckout) {
                NavigationStack {
                    CheckoutView(onOrderPlaced: { _ in
                        showCheckout = false
                        dismiss()
                    })
                }
            }
        }
    }
    
    // MARK: - Empty State (مع تأثير نبض خفيف)
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cart")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 10)

            Text("Your Cart is Empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Looks like you haven't added\nanything to your cart yet.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .offset(y: -40)
    }

    // MARK: - Floating Footer
    private var floatingSummaryFooter: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Payment")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Text(formattedTotal(total))
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                Button(action: {
                    if !cartManager.cartItems.isEmpty {
                        showCheckout = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Checkout")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.blue, Color(red: 0.1, green: 0.4, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 34) // الـ Safe Area للآيفون
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: -5)
        )
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    @EnvironmentObject var cartManager: CartManager
    let item: CartItem

    private var imageUrl: String? {
        item.fullImageUrl ?? item.product?.fullImageUrl
    }

    var body: some View {
        HStack(spacing: 16) {
            // صورة المنتج
            Group {
                if let imageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .placeholder { placeholder }
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

            // التفاصيل
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.label))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // زر الحذف
                    Button(action: {
                        Task { try? await cartManager.removeItem(item.id) }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }

                HStack(alignment: .bottom) {
                    Text(item.formattedPrice)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // أزرار التحكم بالكمية (Pill Shape)
                    HStack(spacing: 12) {
                        Button(action: {
                            Task { try? await cartManager.updateQuantity(cartItemId: item.id, quantity: max(1, item.quantity - 1)) }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(item.quantity > 1 ? Color(.label) : Color(.tertiaryLabel))
                                .frame(width: 28, height: 28)
                        }
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(.label))
                            .frame(minWidth: 16)
                        
                        Button(action: {
                            Task { try? await cartManager.updateQuantity(cartItemId: item.id, quantity: item.quantity + 1) }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator).opacity(0.1), lineWidth: 1)
        )
    }

    private var placeholder: some View {
        Color(.secondarySystemBackground)
            .overlay(Image(systemName: "photo").foregroundColor(Color(.tertiaryLabel)))
    }
}
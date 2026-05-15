import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    let onOrderPlaced: ((String) -> Void)?

    @State private var selectedPaymentMethod = "**** 4242"
    @State private var deliveryOption = "Standard"
    @State private var selectedAddress = ""
    @State private var selectedLatitude: Double = 0
    @State private var selectedLongitude: Double = 0
    @State private var buildingInfo = ""
    @State private var apartmentNumber = ""
    @State private var notes = ""
    @State private var showMapPicker = false
    @State private var showPaymentSheet = false
    @State private var isPlacingOrder = false
    @State private var didSubmitOrder = false
    @State private var errorMessage: String?
    @State private var storeNames: [String: String] = [:]

    init(onOrderPlaced: ((String) -> Void)? = nil) {
        self.onOrderPlaced = onOrderPlaced
    }

    private var shippingAddress: String {
        var parts: [String] = []

        if !selectedAddress.isEmpty {
            parts.append(selectedAddress)
        }

        if !buildingInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Building: \(buildingInfo.trimmingCharacters(in: .whitespacesAndNewlines))")
        }

        if !apartmentNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Apt: \(apartmentNumber.trimmingCharacters(in: .whitespacesAndNewlines))")
        }

        return parts.joined(separator: ", ")
    }

    private var groupedItems: [(storeId: String, items: [CartItem])] {
        Dictionary(grouping: cartManager.cartItems) { $0.storeId }
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { (storeId: $0.key, items: $0.value) }
    }

    var body: some View {
        ZStack {
            (Color(.systemBackground)).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header

                    if groupedItems.isEmpty {
                        emptyState
                    } else {
                        orderSummarySection
                        deliverySection
                        paymentSection
                        totalSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 110)
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NativeCircleIconButton(
                    systemName: "xmark",
                    action: { dismiss() },
                    iconColor: .primary,
                    size: 35.5,
                    iconSize: 15,
                    showBackground: true
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            confirmButton
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .sheet(isPresented: $showMapPicker) {
            MapPickerView(
                isPresented: $showMapPicker,
                initialLatitude: selectedLatitude,
                initialLongitude: selectedLongitude,
                initialAddress: selectedAddress,
                onConfirm: { lat, lng, address in
                    selectedLatitude = lat
                    selectedLongitude = lng
                    selectedAddress = address
                }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showPaymentSheet) {
            paymentSheet
                .presentationDetents([.medium])
        }
        .alert("Order Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            prefillAddressFromProfile()
        }
        .task(id: cartManager.cartItems.map { "\($0.storeId)-\($0.productId)" }.joined(separator: ",")) {
            await loadStoreNames()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Review your order")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Confirm delivery details, payment, and finish your checkout.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var orderSummarySection: some View {
        sectionCard(title: "Order Summary", systemIcon: "bag.fill") {
            VStack(spacing: 12) {
                ForEach(groupedItems, id: \.storeId) { storeGroup in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(storeNames[storeGroup.storeId] ?? "Store")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(storeGroup.items.count) items")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }

                        ForEach(storeGroup.items) { item in
                            checkoutItemRow(item)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground).opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var deliverySection: some View {
        sectionCard(title: "Delivery Details", systemIcon: "location.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    showMapPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                            .frame(width: 24)

                        Text(selectedAddress.isEmpty ? "Select delivery location" : selectedAddress)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(selectedAddress.isEmpty ? Color(.secondaryLabel) : Color(.label))
                            .lineLimit(2)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                YShopTextField(
                    placeholder: "Building / House",
                    icon: "building.2",
                    text: $buildingInfo
                )

                YShopTextField(
                    placeholder: "Apartment / Unit",
                    icon: "door.left.hand.open",
                    text: $apartmentNumber
                )

                YShopTextField(
                    placeholder: "Delivery notes",
                    icon: "note.text",
                    text: $notes
                )
            }
        }
    }

    private var paymentSection: some View {
        sectionCard(title: "Payment Method", systemIcon: "creditcard.fill") {
            Button {
                showPaymentSheet = true
            } label: {
                HStack(spacing: 12) {
                        Image(systemName: selectedPaymentMethod == "Pay at Door" ? "banknote.fill" : "creditcard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedPaymentMethod)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                        Text("Tap to change payment method")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var totalSection: some View {
        sectionCard(title: "Total", systemIcon: "creditcard") {
            VStack(spacing: 10) {
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(cartManager.itemCount)")
                }

                Divider()

                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(String(format: "%.2f", cartManager.totalPrice))
                }

                HStack {
                    Text("Delivery")
                    Spacer()
                    Text("Free")
                }

                Divider()

                HStack {
                    Text("Grand Total")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text(String(format: "%.2f", cartManager.totalPrice))
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(Color(.label))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bag")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color(.secondaryLabel))

            Text("Your cart is empty")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.label))

            Text("Add products before checking out.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private var confirmButton: some View {
        Button {
            guard !isPlacingOrder, !didSubmitOrder else { return }
            didSubmitOrder = true
            isPlacingOrder = true

            Task {
                await placeOrder()
            }
        } label: {
            HStack(spacing: 10) {
                if isPlacingOrder {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "bag.fill")
                }

                Text(isPlacingOrder ? "Placing Order..." : "Confirm Order")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(0.4)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isPlacingOrder || cartManager.cartItems.isEmpty || shippingAddress.isEmpty)
        .opacity((isPlacingOrder || cartManager.cartItems.isEmpty || shippingAddress.isEmpty) ? 0.65 : 1)
    }

    private var paymentSheet: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            Text("Choose Payment Method")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(.label))

            paymentOption(title: "**** 4242", icon: "creditcard")
            paymentOption(title: "Pay at Door", icon: "banknote.fill")

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private func paymentOption(title: String, icon: String) -> some View {
        Button {
            selectedPaymentMethod = title
            showPaymentSheet = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                Text(title)
                    .foregroundColor(Color(.label))
                Spacer()
                if selectedPaymentMethod == title {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func checkoutItemRow(_ item: CartItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.fullImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color(.secondarySystemBackground)
                        .overlay(Image(systemName: "photo").foregroundColor(Color(.tertiaryLabel)))
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(2)

                Text("Qty: \(item.quantity)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            Text(item.formattedPrice)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.blue)
        }
    }

    private func sectionCard<Content: View>(title: String, systemIcon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.label))
                Spacer()
            }

            content()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func placeOrder() async {
        guard !cartManager.cartItems.isEmpty else {
            errorMessage = "Your cart is empty."
            isPlacingOrder = false
            didSubmitOrder = false
            return
        }

        guard !shippingAddress.isEmpty else {
            errorMessage = "Please select a delivery location."
            isPlacingOrder = false
            didSubmitOrder = false
            return
        }

        defer {
            isPlacingOrder = false
        }

        do {
            let createdOrderIds = try await CheckoutService.placeOrders(
                cartItems: cartManager.cartItems,
                shippingAddress: shippingAddress,
                paymentMethod: selectedPaymentMethod,
                deliveryOption: deliveryOption
            )

            if let lastOrderId = createdOrderIds.last {
                cartManager.setLastOrderId(lastOrderId)
                cartManager.presentTrackingOrder(id: lastOrderId)
                if let createdOrder = try? await OrderService.getOrderDetail(id: lastOrderId) {
                    cartManager.setActiveTrackingOrder(createdOrder)

                    // Generate and send receipt PDF to customer and store owner in background
                    Task {
                        do {
                            // Fetch store details if available
                            var store: Store? = nil
                            if !createdOrder.storeId.isEmpty {
                                store = try? await StoreService.getStoreDetail(id: createdOrder.storeId)
                            }

                            let customer = authManager.currentUser
                            let pdf = ReceiptService.generateReceiptPDF(order: createdOrder, store: store, customer: customer)

                            if let customerEmail = authManager.currentUser?.email {
                                try await ReceiptService.sendReceipt(orderId: createdOrder.id, pdfData: pdf, recipientEmail: customerEmail, recipientType: "customer")
                            }

                            if let storeEmail = store?.email {
                                try await ReceiptService.sendReceipt(orderId: createdOrder.id, pdfData: pdf, recipientEmail: storeEmail, recipientType: "store_owner")
                            }
                        } catch {
                            print("⚠️ [Receipt] Failed to send receipt: \(error)")
                        }
                    }
                }
                await cartManager.clearCart()
                onOrderPlaced?(lastOrderId)
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            if error.localizedDescription.contains("Duplicate order submission blocked") {
                dismiss()
            }
            didSubmitOrder = false
        }
    }

    private func prefillAddressFromProfile() {
        guard let user = authManager.currentUser else { return }

        if selectedAddress.isEmpty {
            selectedAddress = user.address ?? ""
        }

        if selectedLatitude == 0, let latitude = user.latitude {
            selectedLatitude = latitude
        }

        if selectedLongitude == 0, let longitude = user.longitude {
            selectedLongitude = longitude
        }

        if buildingInfo.isEmpty {
            buildingInfo = user.buildingInfo ?? ""
        }

        if apartmentNumber.isEmpty {
            apartmentNumber = user.apartmentNumber ?? ""
        }

        if notes.isEmpty {
            notes = user.deliveryInstructions ?? ""
        }
    }

    private func loadStoreNames() async {
        let uniqueStoreIds = Set(cartManager.cartItems.map { $0.storeId }.filter { !$0.isEmpty })
        guard !uniqueStoreIds.isEmpty else { return }

        var resolvedNames: [String: String] = [:]

        for storeId in uniqueStoreIds {
            do {
                let store = try await StoreService.getStoreDetail(id: storeId)
                resolvedNames[storeId] = store.name
            } catch {
                resolvedNames[storeId] = "Store"
            }
        }

        storeNames = resolvedNames
    }
}

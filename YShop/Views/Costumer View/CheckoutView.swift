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
    @State private var showSuccessFeedback = false
    @State private var errorMessage: String?
    @State private var storeNames: [String: String] = [:]

    init(onOrderPlaced: ((String) -> Void)? = nil) {
        self.onOrderPlaced = onOrderPlaced
    }

    private var shippingAddress: String {
        var parts: [String] = []
        if !selectedAddress.isEmpty { parts.append(selectedAddress) }
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
            // خلفية رمادية فاتحة فاخرة لإبراز الكروت البيضاء
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                        .padding(.top, 10)

                    if groupedItems.isEmpty {
                        emptyState
                    } else {
                        deliveryMethodSection
                        deliverySection
                        orderSummarySection
                        paymentSection
                        totalSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110) // مساحة مريحة لكي لا يغطي الزر الطائر آخر عناصر القائمة
            }

            // الزر العائم السفلي المنفصل تماماً (خلفية شفافة)
            VStack {
                Spacer()
                floatingConfirmButton
            }
            .ignoresSafeArea(.keyboard)

            // إشعار النجاح العلوي (Toast Notification)
            if showSuccessFeedback {
                successBanner
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    .padding(.top, 20)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .zIndex(2)
            }
        }
        // إعدادات الـ Navigation Bar والـ Toolbar الأصلية
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
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
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
        }
        .alert("Order Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear { prefillAddressFromProfile() }
        .onChange(of: authManager.currentUser?.id) { _, _ in prefillAddressFromProfile() }
        .task(id: cartManager.cartItems.map { "\($0.storeId)-\($0.productId)" }.joined(separator: ",")) {
            await loadStoreNames()
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Review your order")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Confirm delivery details, payment, and finish your checkout.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: - Delivery Method Section
    private var deliveryMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery Method")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(.label))
            
            HStack(spacing: 16) {
                deliveryOptionCard(title: "Standard", icon: "truck.box.fill", time: "2-3 Days")
                deliveryOptionCard(title: "Drone", icon: "airplane.path.dotted", time: "30 Mins")
            }
        }
    }

    private func deliveryOptionCard(title: String, icon: String, time: String) -> some View {
        let isSelected = deliveryOption == title
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                deliveryOption = title
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .blue)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color(.label))
                    Text(time)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(.secondaryLabel))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color(.separator).opacity(0.1), lineWidth: 1)
            )
            .shadow(color: isSelected ? .blue.opacity(0.25) : .black.opacity(0.02), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Delivery Details Section
    private var deliverySection: some View {
        let currentIcon = deliveryOption == "Drone" ? "airplane.path.dotted" : "truck.box.fill"
        
        return sectionCard(title: "Delivery Details", icon: currentIcon) {
            VStack(alignment: .leading, spacing: 16) {
                Button { showMapPicker = true } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "location.fill").foregroundColor(.blue))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedAddress.isEmpty ? "Select Location" : "Location")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(.secondaryLabel))
                            
                            Text(selectedAddress.isEmpty ? "Tap to choose on map" : selectedAddress)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }

                Divider().padding(.leading, 54)

                VStack(spacing: 12) {
                    YShopTextField(placeholder: "Building / House", icon: "building.2", text: $buildingInfo)
                    YShopTextField(placeholder: "Apartment / Unit", icon: "door.left.hand.open", text: $apartmentNumber)
                    YShopTextField(placeholder: "Delivery notes", icon: "note.text", text: $notes)
                }
            }
        }
    }

    // MARK: - Order Summary Section
    private var orderSummarySection: some View {
        sectionCard(title: "Order Summary", icon: "bag.fill") {
            VStack(spacing: 16) {
                ForEach(groupedItems, id: \.storeId) { storeGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(storeNames[storeGroup.storeId] ?? "Store")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text("\(storeGroup.items.count) items")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(storeGroup.items) { item in
                            checkoutItemRow(item)
                        }
                    }
                    if storeGroup.storeId != groupedItems.last?.storeId {
                        Divider().padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func checkoutItemRow(_ item: CartItem) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: item.fullImageUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color(.secondarySystemBackground)
                        .overlay(Image(systemName: "photo").foregroundColor(Color(.tertiaryLabel)))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)

                Text("Qty: \(item.quantity)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            Text(item.formattedPrice)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.blue)
        }
    }

    // MARK: - Payment Section
    private var paymentSection: some View {
        sectionCard(title: "Payment Method", icon: "creditcard.fill") {
            Button { showPaymentSheet = true } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 32)
                        .overlay(
                            Image(systemName: selectedPaymentMethod == "Pay at Door" ? "banknote.fill" : "creditcard")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        )

                    Text(selectedPaymentMethod)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.label))

                    Spacer()

                    Text("Change")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Total Section
    private var totalSection: some View {
        sectionCard(title: "Total", icon: "creditcard") {
            VStack(spacing: 14) {
                summaryRow(title: "Items", value: "\(cartManager.itemCount)")
                Divider()
                summaryRow(title: "Subtotal", value: String(format: "%.2f", cartManager.totalPrice))
                summaryRow(title: "Delivery", value: "Free")
                
                Divider().padding(.vertical, 4)
                
                HStack {
                    Text("Grand Total")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text(String(format: "%.2f", cartManager.totalPrice))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.label))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.label))
        }
    }

    // MARK: - Custom Section Card View
    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            content()
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.025), radius: 10, x: 0, y: 5)
    }

    // MARK: - Floating Bottom Button (Isolated & Transparent Background)
    private var floatingConfirmButton: some View {
        Button {
            guard !isPlacingOrder, !didSubmitOrder else { return }
            didSubmitOrder = true
            isPlacingOrder = true
            Task { await placeOrder() }
        } label: {
            HStack(spacing: 12) {
                if isPlacingOrder {
                    ProgressView().tint(.white)
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
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
        }
        .disabled(isPlacingOrder || cartManager.cartItems.isEmpty || shippingAddress.isEmpty)
        .opacity((isPlacingOrder || cartManager.cartItems.isEmpty || shippingAddress.isEmpty) ? 0.65 : 1)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background(Color.clear) // خلفية شفافة تماماً ليطفو الزر منفصلاً ونظيفاً
    }

    // MARK: - Toast Feedback Success Banner
    private var successBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Order placed successfully")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("We’ve saved your delivery details and sent the receipt.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground).opacity(0.98))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Sheets & Functions
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bag")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color(.secondaryLabel))
            Text("Your cart is empty")
                .font(.system(size: 16, weight: .semibold))
            Text("Add products before checking out.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var paymentSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Payment Method")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(.label))

            paymentOption(title: "**** 4242", icon: "creditcard")
            paymentOption(title: "Pay at Door", icon: "banknote.fill")
            Spacer()
        }
        .padding(24)
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

    private func placeOrder() async {
        guard !cartManager.cartItems.isEmpty else {
            errorMessage = "Your cart is empty."
            isPlacingOrder = false; didSubmitOrder = false
            return
        }
        guard !shippingAddress.isEmpty else {
            errorMessage = "Please select a delivery location."
            isPlacingOrder = false; didSubmitOrder = false
            return
        }

        defer { isPlacingOrder = false }

        do {
            let createdOrderIds = try await CheckoutService.placeOrders(
                cartItems: cartManager.cartItems, shippingAddress: shippingAddress,
                paymentMethod: selectedPaymentMethod, deliveryOption: deliveryOption
            )

            if let lastOrderId = createdOrderIds.last {
                cartManager.setLastOrderId(lastOrderId)
                cartManager.presentTrackingOrder(id: lastOrderId)
                if let createdOrder = try? await OrderService.getOrderDetail(id: lastOrderId) {
                    cartManager.setActiveTrackingOrder(createdOrder)
                    Task {
                        do {
                            var store: Store? = nil
                            if !createdOrder.storeId.isEmpty { store = try? await StoreService.getStoreDetail(id: createdOrder.storeId) }
                            let customer = authManager.currentUser
                            let pdf = ReceiptService.generateReceiptPDF(order: createdOrder, store: store, customer: customer)

                            if let customerEmail = authManager.currentUser?.email {
                                try await ReceiptService.sendReceipt(orderId: createdOrder.id, pdfData: pdf, recipientEmail: customerEmail, recipientType: "customer")
                            }
                            if let storeEmail = store?.email {
                                try await ReceiptService.sendReceipt(orderId: createdOrder.id, pdfData: pdf, recipientEmail: storeEmail, recipientType: "store_owner")
                            }
                        } catch { print("⚠️ [Receipt] Failed to send receipt: \(error)") }
                    }
                }
                await cartManager.clearCart()
                withAnimation(.easeOut(duration: 0.2)) { showSuccessFeedback = true }
                try? await Task.sleep(nanoseconds: 900_000_000)
                onOrderPlaced?(lastOrderId)
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            if error.localizedDescription.contains("Duplicate order submission blocked") { dismiss() }
            didSubmitOrder = false
        }
    }

    private func prefillAddressFromProfile() {
        guard let user = authManager.currentUser else { return }
        if selectedAddress.isEmpty { selectedAddress = user.address ?? "" }
        if selectedLatitude == 0, let lat = user.latitude { selectedLatitude = lat }
        if selectedLongitude == 0, let lng = user.longitude { selectedLongitude = lng }
        if buildingInfo.isEmpty { buildingInfo = user.buildingInfo ?? "" }
        if apartmentNumber.isEmpty { apartmentNumber = user.apartmentNumber ?? "" }
        if notes.isEmpty { notes = user.deliveryInstructions ?? "" }
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

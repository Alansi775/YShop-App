import SwiftUI

struct OrdersView: View {
    @State private var selectedTab = "Active"
    @State private var orders: [Order] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedOrderId: String?
    @State private var showTrackingSheet = false

    private let tabs = ["Active", "Completed", "Cancelled"]

    private var filteredOrders: [Order] {
        switch selectedTab {
        case "Active":
            return orders.filter { $0.status.isTrackable }
        case "Completed":
            return orders.filter { $0.status == .delivered }
        case "Cancelled":
            return orders.filter { $0.status == .cancelled || $0.status == .failed }
        default:
            return orders
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider()
                tabBar
                Divider()

                content
            }
        }
        .task {
            await loadOrders()
        }
        .sheet(isPresented: $showTrackingSheet) {
            NavigationStack {
                if let selectedOrderId {
                    OrderTrackingView(orderId: selectedOrderId)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Orders")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Track active orders and review your history.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                VStack(spacing: 8) {
                    Text(tab)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? Color(.label) : Color(.secondaryLabel))

                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(Color(.label))
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else if let errorMessage {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.orange)
                Text("Could not load orders")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.label))
                Text(errorMessage)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            Spacer()
        } else if filteredOrders.isEmpty {
            Spacer()
            emptyState
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(filteredOrders) { order in
                        OrderCard(order: order) {
                            selectedOrderId = order.id
                            showTrackingSheet = true
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 110, height: 110)
                .overlay(
                    Image(systemName: "receipt.long")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                )

            Text("No Orders Yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Your orders will appear here once you place your first checkout.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private func loadOrders() async {
        isLoading = true
        errorMessage = nil

        do {
            orders = try await OrderService.getUserOrders()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct OrderCard: View {
    let order: Order
    let trackAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.id)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(.label))

                    Text(order.createdAt ?? "Recently")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                Text(order.status.displayTitle)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(order.status.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(order.status.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Items")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                    Text("\(order.items.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(.label))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                    Text(String(format: "%.2f", order.totalPrice))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                }
            }

            Button(action: trackAction) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text("Track Order")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    OrdersView()
        .environmentObject(AuthManager())
        .environmentObject(CartManager.shared)
}

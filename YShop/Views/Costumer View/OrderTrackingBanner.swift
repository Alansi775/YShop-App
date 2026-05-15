import SwiftUI

struct OrderTrackingBanner: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var trackedOrder: Order?
    @State private var isLoading = false
    @State private var showTrackingSheet = false

    var body: some View {
        Group {
            if let trackedOrder, trackedOrder.status.isTrackable {
                Button {
                    showTrackingSheet = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 36, height: 36)

                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Order #\(trackedOrder.id)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(.label))
                            Text(trackedOrder.status.displayTitle)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                        }

                        Spacer()

                        Text("Track")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showTrackingSheet) {
                    NavigationStack {
                        OrderTrackingView(orderId: trackedOrder.id)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: cartManager.lastOrderId) {
            await loadTrackedOrder()
        }
    }

    private func loadTrackedOrder() async {
        guard let orderId = cartManager.lastOrderId, !orderId.isEmpty else {
            trackedOrder = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let order = try await OrderService.getOrderDetail(id: orderId)
            if order.status.isTrackable {
                trackedOrder = order
            } else {
                trackedOrder = nil
                cartManager.setLastOrderId(nil)
            }
        } catch {
            trackedOrder = nil
        }
    }
}

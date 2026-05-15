import SwiftUI

struct TrackingOrderFloatingButton: View {
    @EnvironmentObject private var cartManager: CartManager
    @State private var showTrackingSheet = false
    @State private var presentedOrderId: String?
    @State private var pulse = false
    @State private var observedOrderId: String?
    @State private var observerId: UUID?

    var body: some View {
        Group {
            if let trackedOrder = cartManager.activeTrackingOrder, trackedOrder.status.isTrackable {
                ZStack {
                    Circle()
                        .fill(trackedOrder.status.accentColor.opacity(pulse ? 0.22 : 0.12))
                        .frame(width: 66, height: 66)
                        .scaleEffect(pulse ? 1.18 : 0.92)

                    Circle()
                        .fill(trackedOrder.status.accentColor.opacity(0.18))
                        .frame(width: 58, height: 58)

                    NativeCircleIconButton(
                        systemName: "location.fill",
                        action: {
                            presentedOrderId = trackedOrder.id
                            showTrackingSheet = true
                            cartManager.clearPendingTrackingOrder()
                        },
                        iconColor: .white,
                        size: 48,
                        iconSize: 18,
                        showBackground: true,
                        backgroundColor: trackedOrder.status.accentColor
                    )
                    .shadow(color: trackedOrder.status.accentColor.opacity(0.35), radius: 14, x: 0, y: 6)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                    Task {
                        await cartManager.refreshActiveTrackingOrder()
                    }
                    bindSocketObserver(for: trackedOrder.id)
                    attemptAutoPresentTrackingSheet()
                }
                .onChange(of: cartManager.activeTrackingOrder?.id) { newOrderId in
                    bindSocketObserver(for: newOrderId)
                    attemptAutoPresentTrackingSheet()
                }
                .onChange(of: cartManager.pendingTrackingOrderId) { _ in
                    attemptAutoPresentTrackingSheet()
                }
                .onDisappear {
                    unbindSocketObserver()
                }
            }
        }
        .sheet(isPresented: $showTrackingSheet, onDismiss: {
            presentedOrderId = nil
        }) {
            NavigationStack {
                OrderTrackingView(orderId: presentedOrderId ?? cartManager.activeTrackingOrder?.id ?? "")
            }
            .environmentObject(cartManager)
        }
    }

    private func attemptAutoPresentTrackingSheet() {
        guard !showTrackingSheet else { return }
        guard let pendingOrderId = cartManager.pendingTrackingOrderId, !pendingOrderId.isEmpty else { return }

        if let activeOrderId = cartManager.activeTrackingOrder?.id, activeOrderId == pendingOrderId {
            presentedOrderId = pendingOrderId
            showTrackingSheet = true
            cartManager.clearPendingTrackingOrder()
            return
        }

        Task {
            await cartManager.refreshActiveTrackingOrder()
            await MainActor.run {
                guard !showTrackingSheet else { return }
                guard let refreshedOrderId = cartManager.activeTrackingOrder?.id, refreshedOrderId == pendingOrderId else { return }

                presentedOrderId = pendingOrderId
                showTrackingSheet = true
                cartManager.clearPendingTrackingOrder()
            }
        }
    }

    private func bindSocketObserver(for orderId: String?) {
        guard observedOrderId != orderId else { return }
        unbindSocketObserver()

        guard let orderId, !orderId.isEmpty else { return }

        observedOrderId = orderId
        observerId = SocketService.shared.observeOrder(orderId: orderId) { [orderId] in
            Task {
                guard !Task.isCancelled else { return }
                if let currentOrderId = cartManager.activeTrackingOrder?.id, currentOrderId == orderId {
                    await cartManager.refreshActiveTrackingOrder()
                }
            }
        }
    }

    private func unbindSocketObserver() {
        if let observerId, let orderId = observedOrderId {
            SocketService.shared.removeObserver(orderId: orderId, observerId: observerId)
        }
        observerId = nil
        observedOrderId = nil
    }
}

// DeliveryDashboardView.swift
// ضع هذا الملف في: Views/DeliveryDriverViews/DeliveryDashboardView.swift
//
// Fix: payment_method الآن موجود في الـ API response بعد تعديل Order.js

import SwiftUI

struct DeliveryDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var history:   [Order] = []
    @State private var stats:     DriverStats?
    @State private var isLoading  = true

    var body: some View {
        NavigationStack {
            ZStack {
                DeliveryTheme.darkBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        summaryCard
                        historySection
                    }.padding(16)
                }
            }
            .navigationTitle("My Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(DeliveryTheme.accentBlue)
                }
            }
            .task { await loadData() }
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Summary Card
    // ────────────────────────────────────────────────────────────────────
    private var summaryCard: some View {
        let s = computedSummary
        return VStack(alignment: .leading, spacing: 14) {
            Text("Today's Summary")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(money(s.gross))
                    .font(.system(size: 34, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                Text("collected").font(.system(size: 13)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Divider().background(DeliveryTheme.separator)
            HStack(spacing: 12) {
                statItem(label: "Orders",  value: "\(history.count)",    icon: "bag.fill")
                statItem(label: "Cash",    value: "\(s.cashCount)",      icon: "banknote.fill")
                statItem(label: "Online",  value: "\(s.onlineCount)",    icon: "creditcard.fill")
            }
            HStack(spacing: 12) {
                statItem(label: "Your 10%",       value: money(s.earnings),    icon: "hand.raised.fill")
                statItem(label: "To Transfer",    value: money(s.toTransfer),  icon: "arrow.up.right")
                statItem(label: "Online Settled", value: money(s.onlineTotal), icon: "checkmark.seal.fill")
            }
            Text("Cash orders require transfer to the platform. Online orders are already settled.")
                .font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
        }
        .padding(20)
        .background(DeliveryTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(DeliveryTheme.accentBlue)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
            Text(label).font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
        }.frame(maxWidth: .infinity)
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: History Section
    // ────────────────────────────────────────────────────────────────────
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Deliveries")
                    .font(.system(size: 17, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                Spacer()
                if !history.isEmpty {
                    Text("\(history.count)")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(DeliveryTheme.secondaryText)
                }
            }.padding(.horizontal, 4)

            if isLoading {
                ProgressView().tint(DeliveryTheme.accentBlue).frame(maxWidth: .infinity).padding(.vertical, 40)
            } else if history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bag").font(.system(size: 36))
                        .foregroundColor(DeliveryTheme.secondaryText.opacity(0.5))
                    Text("No deliveries yet")
                        .font(.system(size: 15, weight: .medium)).foregroundColor(DeliveryTheme.secondaryText)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                ForEach(history, id: \.id) { order in historyRow(order) }
            }
        }
    }

    private func historyRow(_ order: Order) -> some View {
        let cash    = isCash(order.paymentMethod)
        let driverE = money(order.totalPrice * 0.10)
        let transfer = money(order.totalPrice * 0.90)
        let accentColor = cash ? DeliveryTheme.accentOrange : DeliveryTheme.accentGreen
        let accentBackground = accentColor.opacity(0.12)

        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(accentBackground).frame(width: 40, height: 40)
                Image(systemName: "checkmark")
                    .foregroundColor(accentColor).font(.system(size: 14, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(order.storeName ?? "Order #\(order.id)")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(DeliveryTheme.primaryText)
                Text("Order #\(order.id) • \(cash ? "Pay at Door" : "Paid online")")
                    .font(.system(size: 11)).foregroundColor(DeliveryTheme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(order.totalPrice))
                    .font(.system(size: 14, weight: .bold)).foregroundColor(DeliveryTheme.primaryText)
                Text(cash ? "Transfer \(transfer) • You \(driverE)" : "Settled online • You \(driverE)")
                    .font(.system(size: 10)).foregroundColor(DeliveryTheme.secondaryText)
                Text(cash ? "Transfer required" : "Already settled")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentBackground, in: Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DeliveryTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accentColor.opacity(cash ? 0.35 : 0.12), lineWidth: 1.25)
                )
        )
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Load Data
    // ────────────────────────────────────────────────────────────────────
    private func loadData() async {
        async let statsTask  = DeliveryService.getDriverStats()
        async let histTask   = DeliveryService.getDeliveryHistory()

        let (s, h) = await (try? statsTask, try? histTask)
        var loaded = h ?? []

        // فلترة: delivered فقط وللموصل الحالي
        if let profile = try? await DeliveryService.getDriverProfile(), !profile.uid.isEmpty {
            loaded = loaded.filter { order in
                let ownedByDriver = order.driverId?.isEmpty ?? true ? true : order.driverId == profile.uid
                return ownedByDriver && order.status == .delivered
            }
        } else {
            loaded = loaded.filter { $0.status == .delivered }
        }

        await MainActor.run {
            stats     = s
            history   = loaded
            isLoading = false
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Helpers
    // ────────────────────────────────────────────────────────────────────
    private func isCash(_ method: String?) -> Bool {
        let m = (method ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return m.contains("pay at door") || m.contains("cash") || m.contains("cod")
    }

    private func money(_ amount: Double) -> String { String(format: "₺%.2f", amount) }

    private var computedSummary: Summary {
        let cash   = history.filter { isCash($0.paymentMethod) }
        let online = history.filter { !isCash($0.paymentMethod) }
        let gross  = history.reduce(0) { $0 + $1.totalPrice }
        let cashAmt = cash.reduce(0) { $0 + $1.totalPrice }
        return Summary(
            gross:       gross,
            earnings:    gross * 0.10,
            toTransfer:  cashAmt * 0.90,
            onlineTotal: online.reduce(0) { $0 + $1.totalPrice },
            cashCount:   cash.count,
            onlineCount: online.count
        )
    }

    private struct Summary {
        let gross, earnings, toTransfer, onlineTotal: Double
        let cashCount, onlineCount: Int
    }
}
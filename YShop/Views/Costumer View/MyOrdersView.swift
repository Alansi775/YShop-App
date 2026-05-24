import SwiftUI

struct MyOrdersView: View {
	@EnvironmentObject private var authManager: AuthManager
	@Environment(\.dismiss) private var dismiss

	@State private var selectedTab = "All"
	@State private var orders: [Order] = []
	@State private var storesById: [String: Store] = [:]
	@State private var isLoading = true
	@State private var errorMessage: String?
	@State private var selectedOrderId: String?
	@State private var selectedReturnOrder: Order?
	@State private var showTrackingSheet = false

	private let tabs = ["All", "Active", "Delivered"]

	private var filteredOrders: [Order] {
		switch selectedTab {
		case "Active":
			return orders.filter { $0.status.isTrackable }
		case "Delivered":
			return orders.filter { $0.status == .delivered }
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
		.navigationTitle("My Orders")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				NativeCircleIconButton(
					systemName: "chevron.left",
					action: { dismiss() },
					iconColor: .primary,
					size: 35.5,
					iconSize: 14,
					showBackground: false
				)
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
		.sheet(item: $selectedReturnOrder) { order in
			NavigationStack {
				ReturnRequestSheet(order: order, store: storesById[order.storeId])
					.environmentObject(authManager)
			}
		}
	}

	private var header: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("My Orders")
				.font(.system(size: 20, weight: .bold))
				.foregroundColor(Color(.label))

			Text("Here you can view every order tied to your account. Active orders can still be tracked, and delivered orders stay visible in history.")
				.font(.system(size: 13, weight: .regular))
				.foregroundColor(Color(.secondaryLabel))
				.fixedSize(horizontal: false, vertical: true)

			Text("Delivered food, market, and pharmacy orders can be reported within 30 minutes. Clothing orders can be returned within 3 days.")
				.font(.system(size: 12, weight: .regular))
				.foregroundColor(Color(.secondaryLabel))
				.fixedSize(horizontal: false, vertical: true)
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
					ForEach(filteredOrders.sorted(by: newestFirst)) { order in
						let store = storesById[order.storeId]
						let policy = returnPolicy(for: order, store: store)
						let title = primaryActionTitle(for: order, policy: policy)
						MyOrderCard(
							order: order,
							store: store,
							primaryActionTitle: title,
							primaryAction: {
								if order.status.isTrackable {
									selectedOrderId = order.id
									showTrackingSheet = true
								} else if order.status == .delivered && policy.isWithinWindow {
									selectedReturnOrder = order
								}
							}
						)
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
					Image(systemName: "bag.fill")
						.font(.system(size: 40, weight: .semibold))
						.foregroundColor(Color(.secondaryLabel))
				)

			Text("No Orders Yet")
				.font(.system(size: 18, weight: .bold))
				.foregroundColor(Color(.label))

			Text("When you place or receive orders, they will appear here. Delivered orders stay in your history, and active ones can still be tracked.")
				.font(.system(size: 13, weight: .regular))
				.foregroundColor(Color(.secondaryLabel))
				.multilineTextAlignment(.center)
				.padding(.horizontal, 24)

			Text("Delivered orders stay visible after receipt. Returns are time-limited based on the store type, matching the Flutter flow.")
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
			let userOrders = try await OrderService.getUserOrders()
			orders = userOrders
			await loadStoreMetadata(for: userOrders)
		} catch {
			errorMessage = error.localizedDescription
		}

		isLoading = false
	}

	private func loadStoreMetadata(for orders: [Order]) async {
		let uniqueStoreIds = Array(Set(orders.map { $0.storeId }))
		guard !uniqueStoreIds.isEmpty else { return }

		await withTaskGroup(of: (String, Store?).self) { group in
			for storeId in uniqueStoreIds {
				group.addTask {
					let store = try? await StoreService.getStoreDetail(id: storeId)
					return (storeId, store)
				}
			}

			var resolved: [String: Store] = [:]
			for await result in group {
				if let store = result.1 {
					resolved[result.0] = store
				}
			}

			await MainActor.run {
				storesById = resolved
			}
		}
	}

	private func newestFirst(_ lhs: Order, _ rhs: Order) -> Bool {
		lhsDate(for: lhs) > lhsDate(for: rhs)
	}

	private func lhsDate(for order: Order) -> Date {
		let delivered = parseDate(order.deliveredAt)
		if delivered != .distantPast { return delivered }

		let updated = parseDate(order.updatedAt)
		if updated != .distantPast { return updated }

		let created = parseDate(order.createdAt)
		if created != .distantPast { return created }

		return .distantPast
	}

	private func parseDate(_ rawValue: String?) -> Date {
		guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
			return .distantPast
		}

		let formatters: [DateFormatter] = [
			DateFormatter.isoDateTime,
			DateFormatter.sqlDateTime,
			DateFormatter.sqlDateOnly
		]

		for formatter in formatters {
			if let date = formatter.date(from: rawValue) {
				return date
			}
		}

		return .distantPast
	}

	private func returnPolicy(for order: Order, store: Store?) -> ReturnPolicy {
		let storeType = store?.storeType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
		// The return/support window starts from the delivered timestamp, which is set
		// when the courier taps "Mark as delivered", not from the original order time.
		let deliveredDate = parseDate(order.deliveredAt)
		let window: TimeInterval = storeType == "clothes" ? 3 * 24 * 60 * 60 : 30 * 60
		let expiresAt = deliveredDate == .distantPast ? nil : deliveredDate.addingTimeInterval(window)
		let isWithinWindow = expiresAt.map { Date() < $0 } ?? false

		return ReturnPolicy(storeType: storeType, windowSeconds: window, isWithinWindow: isWithinWindow, expiresAt: expiresAt)
	}

	private func primaryActionTitle(for order: Order, policy: ReturnPolicy) -> String {
		if order.status.isTrackable {
			return "Track Order"
		}

		guard order.status == .delivered else { return "View Order" }

		if policy.isWithinWindow {
			return policy.storeType == "clothes" ? "Request Return" : "Return / Report"
		}

		return "Contact Support"
	}
}

private struct ReturnPolicy {
	let storeType: String
	let windowSeconds: TimeInterval
	let isWithinWindow: Bool
	let expiresAt: Date?
}

struct MyOrderCard: View {
	let order: Order
	let store: Store?
	let primaryActionTitle: String
	let primaryAction: () -> Void

	@Environment(\.colorScheme) private var colorScheme

	private var storeType: String {
		store?.storeType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
	}

	private var isCashOrder: Bool {
		let normalized = (order.paymentMethod ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		return normalized.contains("pay at door") || normalized.contains("cash") || normalized.contains("cod")
	}

	private var policyWindow: TimeInterval {
		storeType == "clothes" ? 3 * 24 * 60 * 60 : 30 * 60
	}

	private var deliveredDate: Date? {
		parseDate(order.deliveredAt)
	}

	private var policyExpiresAt: Date? {
		guard let deliveredDate else { return nil }
		return deliveredDate.addingTimeInterval(policyWindow)
	}

	private var isWithinPolicyWindow: Bool {
		guard let policyExpiresAt else { return false }
		return Date() < policyExpiresAt
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 4) {
					Text(order.storeName ?? store?.name ?? "Order #\(order.id)")
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
					Text("Total")
						.font(.system(size: 12, weight: .regular))
						.foregroundColor(Color(.secondaryLabel))
					Text(String(format: "₺%.2f", order.totalPrice))
						.font(.system(size: 13, weight: .bold))
						.foregroundColor(.blue)
				}

				Spacer()

				VStack(alignment: .trailing, spacing: 4) {
					Text("Payment")
						.font(.system(size: 12, weight: .regular))
						.foregroundColor(Color(.secondaryLabel))
					Text(isCashOrder ? "Pay at Door" : (order.paymentMethod ?? "Online"))
						.font(.system(size: 13, weight: .bold))
						.foregroundColor(Color(.label))
						.lineLimit(1)
				}
			}

			if order.status == .delivered {
				VStack(alignment: .leading, spacing: 8) {
					HStack(spacing: 8) {
						Image(systemName: "clock.fill")
							.font(.system(size: 12, weight: .semibold))
							.foregroundColor(isWithinPolicyWindow ? .orange : .secondary)

						Text(policyWindowText)
							.font(.system(size: 12, weight: .semibold))
							.foregroundColor(Color(.secondaryLabel))
					}

					if isWithinPolicyWindow {
						Text(policyHintText)
							.font(.system(size: 11, weight: .regular))
							.foregroundColor(Color(.secondaryLabel))
							.fixedSize(horizontal: false, vertical: true)

						Button(action: primaryAction) {
							HStack(spacing: 8) {
								Image(systemName: "arrow.uturn.backward.circle.fill")
								Text(primaryActionTitle)
									.font(.system(size: 13, weight: .bold))
							}
							.foregroundColor(.white)
							.frame(maxWidth: .infinity)
							.frame(height: 44)
							.background(Color.black)
							.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
						}
					} else {
						Text("This order is history only. If you need help, contact YSHOP Support.")
							.font(.system(size: 11, weight: .regular))
							.foregroundColor(Color(.secondaryLabel))
					}
				}
			} else {
				Button(action: primaryAction) {
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
		}
		.padding(14)
		.background(Color(.secondarySystemBackground))
		.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
	}

	private var policyWindowText: String {
		if storeType == "clothes" {
			return isWithinPolicyWindow ? "Return window: 3 days" : "Return window expired after 3 days"
		}

		return isWithinPolicyWindow ? "Return / support window: 30 minutes" : "Support window expired after 30 minutes"
	}

	private var policyHintText: String {
		if storeType == "clothes" {
			return "Clothing orders can be returned within 3 days."
		}
		if isCashOrder {
			return "For cash orders, support is available shortly after delivery."
		}

		return "If there is a missing item or issue, contact YSHOP Support within 30 minutes."
	}

	private func parseDate(_ rawValue: String?) -> Date? {
		guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
			return nil
		}

		let formatters: [DateFormatter] = [
			DateFormatter.isoDateTime,
			DateFormatter.sqlDateTime,
			DateFormatter.sqlDateOnly
		]

		for formatter in formatters {
			if let date = formatter.date(from: rawValue) {
				return date
			}
		}

		return nil
	}
}

struct ReturnRequestSheet: View {
	let order: Order
	let store: Store?

	@Environment(\.dismiss) private var dismiss
	@State private var reason: String = ""
	@State private var details: String = ""
	@State private var isSubmitting = false
	@State private var errorMessage: String?
	@State private var successMessage: String?

	private var storeType: String {
		store?.storeType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
	}

	private var policyText: String {
		if storeType == "clothes" {
			return "Clothing orders can be returned within 3 days of delivery."
		}

		return "Food, market, and pharmacy orders can be reported within 30 minutes after delivery."
	}

	private var actionTitle: String {
		storeType == "clothes" ? "Request Return" : "Submit Report"
	}

	var body: some View {
		NavigationStack {
			ZStack {
				Color(.systemBackground).ignoresSafeArea()

				ScrollView(showsIndicators: false) {
					VStack(alignment: .leading, spacing: 18) {
						header
						policyCard
						formCard
						submitButton
					}
					.padding(16)
				}
			}
			.navigationTitle("Return / Report")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					NativeCircleIconButton(
						systemName: "chevron.left",
						action: { dismiss() },
						iconColor: .primary,
						size: 35.5,
						iconSize: 14,
						showBackground: false
					)
				}
			}
			.alert("Success", isPresented: Binding(
				get: { successMessage != nil },
				set: { if !$0 { successMessage = nil } }
			)) {
				Button("OK") { dismiss() }
			} message: {
				Text(successMessage ?? "Return request submitted.")
			}
		}
	}

	private var header: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(order.storeName ?? store?.name ?? "Order #\(order.id)")
				.font(.system(size: 22, weight: .bold))
				.foregroundColor(Color(.label))

			Text("Order #\(order.id) • \(order.status.displayTitle)")
				.font(.system(size: 13, weight: .regular))
				.foregroundColor(Color(.secondaryLabel))
		}
	}

	private var policyCard: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Policy Window")
				.font(.system(size: 13, weight: .semibold))
				.foregroundColor(Color(.secondaryLabel))

			Text(policyText)
				.font(.system(size: 14, weight: .regular))
				.foregroundColor(Color(.label))
				.fixedSize(horizontal: false, vertical: true)
		}
		.padding(14)
		.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
	}

	private var formCard: some View {
		VStack(alignment: .leading, spacing: 14) {
			Text("Reason")
				.font(.system(size: 13, weight: .semibold))
				.foregroundColor(Color(.secondaryLabel))

			TextField("Tell us why you want to return/report", text: $reason, axis: .vertical)
				.textFieldStyle(.roundedBorder)

			Text("Details")
				.font(.system(size: 13, weight: .semibold))
				.foregroundColor(Color(.secondaryLabel))

			TextEditor(text: $details)
				.frame(minHeight: 120)
				.padding(8)
				.background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

			Text("Photos support can be added later. This first version follows the Flutter flow: reason first, then submission.")
				.font(.system(size: 11, weight: .regular))
				.foregroundColor(Color(.secondaryLabel))
				.fixedSize(horizontal: false, vertical: true)

			if let errorMessage {
				Text(errorMessage)
					.font(.system(size: 12, weight: .semibold))
					.foregroundColor(.red)
			}
		}
		.padding(14)
		.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
	}

	private var submitButton: some View {
		Button {
			Task { await submitReturn() }
		} label: {
			HStack(spacing: 8) {
				if isSubmitting {
					ProgressView().tint(.white)
				} else {
					Image(systemName: "paperplane.fill")
					Text(actionTitle)
						.font(.system(size: 14, weight: .bold))
				}
			}
			.foregroundColor(.white)
			.frame(maxWidth: .infinity)
			.frame(height: 48)
			.background(Color.black)
			.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
		}
		.disabled(isSubmitting || reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
	}

	private func submitReturn() async {
		let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedReason.isEmpty else {
			errorMessage = "Please enter a reason."
			return
		}

		await MainActor.run {
			isSubmitting = true
			errorMessage = nil
		}

		do {
			_ = try await ReturnService.createReturnRequest(
				orderId: order.id,
				reason: trimmedReason,
				description: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details.trimmingCharacters(in: .whitespacesAndNewlines),
				images: nil
			)

			await MainActor.run {
				successMessage = "Your return request has been submitted."
				isSubmitting = false
			}
		} catch {
			await MainActor.run {
				errorMessage = error.localizedDescription
				isSubmitting = false
			}
		}
	}
}

private extension DateFormatter {
	static let isoDateTime: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		return formatter
	}()

	static let sqlDateTime: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		return formatter
	}()

	static let sqlDateOnly: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter
	}()
}

#Preview {
	MyOrdersView()
		.environmentObject(AuthManager())
}

import SwiftUI
import UIKit

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
	@State private var cancelReturnOrder: Order?
	@State private var showCancelReturnAlert = false
	@State private var isCancellingReturn = false
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
			ReturnRequestSheet(order: order, store: storesById[order.storeId]) {
				Task { await loadOrders() }
			}
			.environmentObject(authManager)
		}
		.alert("Cancel Return?", isPresented: $showCancelReturnAlert) {
			Button("Cancel Return", role: .destructive) {
				Task { await cancelReturn() }
			}
			Button("Keep", role: .cancel) { cancelReturnOrder = nil }
		} message: {
			Text("Are you sure you want to cancel your return request?")
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
							},
							cancelReturnAction: order.status == .returnRequested ? {
								cancelReturnOrder = order
								showCancelReturnAlert = true
							} : nil
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

	private func cancelReturn() async {
		guard let order = cancelReturnOrder else { return }
		do {
			try await ReturnService.cancelReturnRequest(orderId: order.id)
			cancelReturnOrder = nil
			await loadOrders()
		} catch {
			// Silently reload even on error
			cancelReturnOrder = nil
			await loadOrders()
		}
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
	var cancelReturnAction: (() -> Void)? = nil

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

			if order.status == .returnRequested {
				// Return in progress — show cancel option
				VStack(alignment: .leading, spacing: 8) {
					HStack(spacing: 8) {
						Image(systemName: "arrow.uturn.backward.circle.fill")
							.foregroundColor(.orange)
							.font(.system(size: 13))
						Text("Return request submitted. A driver will pick up the item.")
							.font(.system(size: 12))
							.foregroundColor(Color(.secondaryLabel))
							.fixedSize(horizontal: false, vertical: true)
					}
					if let cancelAction = cancelReturnAction {
						Button(action: cancelAction) {
							Text("Cancel Return")
								.font(.system(size: 13, weight: .bold))
								.foregroundColor(.orange)
								.frame(maxWidth: .infinity)
								.frame(height: 44)
								.background(Color.orange.opacity(0.1))
								.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
								.overlay(
									RoundedRectangle(cornerRadius: 14, style: .continuous)
										.stroke(Color.orange.opacity(0.3), lineWidth: 1)
								)
						}
					}
				}
			} else if order.status == .delivered {
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

// MARK: - Return Request Sheet (3-Step Wizard)
struct ReturnRequestSheet: View {
	let order: Order
	let store: Store?
	let onSuccess: (() -> Void)?

	@Environment(\.dismiss) private var dismiss
	@State private var step = 0
	@State private var reason = ""
	@State private var photos: [String: UIImage] = [:]
	@State private var activePhotoLabel: String? = nil
	@State private var showImageSource = false
	@State private var showCameraPicker = false
	@State private var showLibraryPicker = false
	@State private var isSubmitting = false
	@State private var errorMessage: String?

	private let photoLabels = ["top", "bottom", "left", "right", "front", "back"]
	private var isReasonValid: Bool { reason.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 }
	private var allPhotosAdded: Bool { photos.count == 6 }
	private var canProceed: Bool {
		switch step {
		case 0: return isReasonValid
		case 1: return allPhotosAdded
		default: return true
		}
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				progressBar
					.padding(.horizontal, 20)
					.padding(.top, 8)
					.padding(.bottom, 16)

				TabView(selection: $step) {
					reasonStep.tag(0)
					photosStep.tag(1)
					reviewStep.tag(2)
				}
				.tabViewStyle(.page(indexDisplayMode: .never))
				.animation(.easeInOut(duration: 0.3), value: step)

				footer
			}
			.navigationTitle(["Reason", "Photos", "Review"][step])
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					NativeCircleIconButton(
						systemName: "xmark",
						action: { dismiss() },
						iconColor: .primary,
						size: 35.5,
						iconSize: 14,
						showBackground: false
					)
				}
			}
		}
		.sheet(isPresented: $showCameraPicker) {
			if let label = activePhotoLabel {
				ImagePickerView(
					image: Binding(get: { photos[label] }, set: { if let img = $0 { photos[label] = img } }),
					sourceType: .camera
				)
			}
		}
		.sheet(isPresented: $showLibraryPicker) {
			if let label = activePhotoLabel {
				ImagePickerView(
					image: Binding(get: { photos[label] }, set: { if let img = $0 { photos[label] = img } }),
					sourceType: .photoLibrary
				)
			}
		}
		.confirmationDialog("Add Photo", isPresented: $showImageSource, titleVisibility: .visible) {
			if UIImagePickerController.isSourceTypeAvailable(.camera) {
				Button("Take Photo") { showCameraPicker = true }
			}
			Button("Choose from Library") { showLibraryPicker = true }
			Button("Cancel", role: .cancel) { activePhotoLabel = nil }
		}
	}

	// MARK: - Progress Bar
	private var progressBar: some View {
		HStack(spacing: 8) {
			ForEach(0..<3, id: \.self) { i in
				RoundedRectangle(cornerRadius: 2)
					.fill(i <= step ? Color(.label) : Color(.tertiaryLabel))
					.frame(height: 3)
					.animation(.easeInOut, value: step)
			}
		}
	}

	// MARK: - Step 1: Reason
	private var reasonStep: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 20) {
				VStack(alignment: .leading, spacing: 6) {
					Text("Why are you returning this?")
						.font(.system(size: 20, weight: .bold))
					Text("Minimum 10 characters")
						.font(.system(size: 13))
						.foregroundColor(Color(.secondaryLabel))
				}

				ZStack(alignment: .topLeading) {
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(Color(.secondarySystemBackground))
						.frame(minHeight: 140)
					if reason.isEmpty {
						Text("Describe the issue or reason for return...")
							.foregroundColor(Color(.placeholderText))
							.font(.system(size: 15))
							.padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
					}
					TextEditor(text: $reason)
						.frame(minHeight: 140)
						.background(Color.clear)
						.scrollContentBackground(.hidden)
						.padding(8)
				}
				.overlay(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.stroke(isReasonValid ? Color.green.opacity(0.5) : Color(.separator), lineWidth: 1.5)
				)

				HStack {
					Spacer()
					Text("\(reason.count)/10")
						.font(.system(size: 12, weight: .semibold))
						.foregroundColor(isReasonValid ? .green : Color(.secondaryLabel))
				}
			}
			.padding(20)
		}
	}

	// MARK: - Step 2: Photos
	private var photosStep: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 16) {
				VStack(alignment: .leading, spacing: 6) {
					Text("Take 6 Photos")
						.font(.system(size: 20, weight: .bold))
					Text("Capture all angles: top, bottom, left, right, front, back")
						.font(.system(size: 13))
						.foregroundColor(Color(.secondaryLabel))
				}

				LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
					ForEach(photoLabels, id: \.self) { label in
						photoCell(label: label)
					}
				}
			}
			.padding(20)
		}
	}

	private func photoCell(label: String) -> some View {
		let captured = photos[label]
		return Button {
			activePhotoLabel = label
			showImageSource = true
		} label: {
			ZStack(alignment: .bottom) {
				Group {
					if let img = captured {
						Image(uiImage: img)
							.resizable()
							.scaledToFill()
					} else {
						Color(captured != nil ? UIColor.systemGreen : UIColor.secondarySystemBackground)
							.overlay(
								VStack(spacing: 8) {
									Image(systemName: "camera.fill")
										.font(.system(size: 24))
										.foregroundColor(Color(.secondaryLabel))
									Text("Tap to capture")
										.font(.system(size: 11))
										.foregroundColor(Color(.secondaryLabel))
								}
							)
					}
				}
				.frame(height: 130)
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.stroke(captured != nil ? Color.green.opacity(0.5) : Color(.separator), lineWidth: 1.5)
				)

				HStack {
					Text(label.capitalized)
						.font(.system(size: 12, weight: .semibold))
						.foregroundColor(.white)
					Spacer()
					if captured != nil {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
							.font(.system(size: 14))
					}
				}
				.padding(.horizontal, 10)
				.padding(.vertical, 6)
				.background(Color.black.opacity(0.55))
				.clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 14, bottomTrailingRadius: 14, topTrailingRadius: 0))
			}
			.frame(height: 130)
		}
		.buttonStyle(.plain)
	}

	// MARK: - Step 3: Review
	private var reviewStep: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 16) {
				Text("Review & Confirm")
					.font(.system(size: 20, weight: .bold))

				reviewRow(label: "Order", value: "#\(order.id)")
				reviewRow(label: "Reason", value: reason.trimmingCharacters(in: .whitespacesAndNewlines))
				reviewRow(label: "Photos", value: "\(photos.count) / 6")

				VStack(alignment: .leading, spacing: 8) {
					Text("Photos Preview")
						.font(.system(size: 13, weight: .semibold))
						.foregroundColor(Color(.secondaryLabel))

					LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
						ForEach(photoLabels, id: \.self) { label in
							if let img = photos[label] {
								Image(uiImage: img)
									.resizable()
									.scaledToFill()
									.frame(height: 80)
									.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
							} else {
								RoundedRectangle(cornerRadius: 10)
									.fill(Color(.tertiarySystemBackground))
									.frame(height: 80)
									.overlay(Image(systemName: "xmark").foregroundColor(Color(.quaternaryLabel)))
							}
						}
					}
				}
				.padding(14)
				.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

				HStack(alignment: .top, spacing: 10) {
					Image(systemName: "info.circle.fill").foregroundColor(.orange)
					Text("Your return request will be reviewed. A driver will pick up the item from you within 24-48 hours.")
						.font(.system(size: 13))
						.fixedSize(horizontal: false, vertical: true)
				}
				.padding(14)
				.background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

				if let errorMessage {
					Text(errorMessage)
						.font(.system(size: 12, weight: .semibold))
						.foregroundColor(.red)
				}
			}
			.padding(20)
		}
	}

	private func reviewRow(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.system(size: 13))
				.foregroundColor(Color(.secondaryLabel))
				.frame(width: 60, alignment: .leading)
			Text(value)
				.font(.system(size: 13, weight: .semibold))
				.multilineTextAlignment(.leading)
			Spacer()
		}
		.padding(14)
		.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
	}

	// MARK: - Footer Navigation
	private var footer: some View {
		HStack(spacing: 12) {
			if step > 0 {
				Button("Back") { withAnimation { step -= 1 } }
					.foregroundColor(Color(.label))
					.frame(maxWidth: .infinity)
					.frame(height: 48)
					.background(Color(.secondarySystemBackground))
					.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
			}

			Button {
				if step < 2 {
					withAnimation { step += 1 }
				} else {
					Task { await submitReturn() }
				}
			} label: {
				HStack(spacing: 8) {
					if isSubmitting {
						ProgressView().tint(.white)
					} else if step == 2 {
						Image(systemName: "checkmark")
						Text("Submit Request").font(.system(size: 14, weight: .bold))
					} else {
						Text("Next").font(.system(size: 14, weight: .bold))
						Image(systemName: "arrow.right")
					}
				}
				.foregroundColor(canProceed ? .white : Color(.secondaryLabel))
				.frame(maxWidth: .infinity)
				.frame(height: 48)
				.background(canProceed ? Color.black : Color(.systemGray5))
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
			}
			.disabled(!canProceed || isSubmitting)
		}
		.padding(.horizontal, 20)
		.padding(.vertical, 12)
	}

	// MARK: - Submit
	private func submitReturn() async {
		await MainActor.run { isSubmitting = true; errorMessage = nil }

		let photoData: [(label: String, data: Data)] = photoLabels.compactMap { label in
			guard let img = photos[label], let data = img.jpegData(compressionQuality: 0.8) else { return nil }
			return (label: label, data: data)
		}

		do {
			_ = try await ReturnService.submitReturnRequest(
				orderId: order.id,
				reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
				photos: photoData
			)
			await MainActor.run {
				isSubmitting = false
				onSuccess?()
				dismiss()
			}
		} catch {
			await MainActor.run { errorMessage = error.localizedDescription; isSubmitting = false }
		}
	}
}

// MARK: - Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
	@Binding var image: UIImage?
	var sourceType: UIImagePickerController.SourceType = .photoLibrary
	@Environment(\.dismiss) private var dismiss

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
		picker.delegate = context.coordinator
		picker.allowsEditing = false
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
	func makeCoordinator() -> Coordinator { Coordinator(self) }

	class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		let parent: ImagePickerView
		init(_ parent: ImagePickerView) { self.parent = parent }

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
			parent.image = info[.originalImage] as? UIImage
			parent.dismiss()
		}

		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
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

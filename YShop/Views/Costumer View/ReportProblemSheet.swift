import SwiftUI
import UIKit

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Report a Problem Sheet (Food / Market / Pharmacy — 30-min window)

struct ReportProblemSheet: View {
    let order: Order
    let store: Store?
    let onSuccess: ((MyComplaint) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var selectedType: ComplaintType? = nil
    @State private var selectedSubType: String? = nil
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var didSucceed = false

    // Countdown timer — always computed from deliveredAt so it never drifts
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var remainingSeconds: Int {
        guard let raw = order.deliveredAt, let delivered = parseDate(raw) else {
            return 30 * 60
        }
        return max(0, Int(delivered.addingTimeInterval(30 * 60).timeIntervalSince(now)))
    }

    private var timerFired: Bool { remainingSeconds == 0 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                if timerFired {
                    windowExpiredView
                } else if didSucceed {
                    successView
                } else {
                    progressBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    TabView(selection: $step) {
                        typeStep.tag(0)
                        describeStep.tag(1)
                        reviewStep.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: step)

                    footer
                }
            }
            .navigationTitle(didSucceed || timerFired ? "" : ["Problem Type", "Describe", "Review"][step])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                }
            }
        }
        .onReceive(timer) { t in now = t }
    }

    // MARK: - Timer bar
    private var timerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
                .foregroundColor(remainingSeconds < 300 ? .red : .orange)

            Text(timerLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(remainingSeconds < 300 ? .red : .orange)

            Spacer()

            Text("Report window for order #\(order.id)")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var timerLabel: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d remaining", m, s)
    }

    // MARK: - Progress
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 3)
                    .frame(height: 4)
                    .foregroundColor(i <= step ? Color(.label) : Color(.systemFill))
            }
        }
    }

    // MARK: - Step 0: Type
    private var typeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What went wrong?")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top, 8)

                ForEach(ComplaintType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        selectedSubType = nil
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: type.icon)
                                .font(.system(size: 20))
                                .frame(width: 36, height: 36)
                                .foregroundColor(selectedType == type ? .white : type.color)
                                .background(selectedType == type ? type.color : type.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(.label))
                                Text(type.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(.secondaryLabel))
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(type.color)
                            }
                        }
                        .padding(14)
                        .background(selectedType == type ? type.color.opacity(0.08) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedType == type ? type.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                    }
                }

                if let type = selectedType, !type.subTypes.isEmpty {
                    Text("Specify the issue")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.top, 4)

                    FlowLayout(spacing: 8) {
                        ForEach(type.subTypes, id: \.self) { sub in
                            Button(action: { selectedSubType = sub }) {
                                Text(sub)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedSubType == sub ? Color(.label) : Color(.secondarySystemBackground))
                                    .foregroundColor(selectedSubType == sub ? Color(.systemBackground) : Color(.label))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 1: Describe
    private var describeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tell us more")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top, 8)

                if let type = selectedType {
                    HStack(spacing: 10) {
                        Image(systemName: type.icon)
                            .foregroundColor(type.color)
                        Text(type.title + (selectedSubType != nil ? " — \(selectedSubType!)" : ""))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }

                TextEditor(text: $description)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                    )

                Text("\(description.count) / 500 characters")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                // Spacer to allow tapping below keyboard to dismiss it
                Color.clear
                    .frame(height: 1)
                    .contentShape(Rectangle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Step 2: Review
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Review & Submit")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    reviewRow(label: "Order", value: "#\(order.id)")
                    reviewRow(label: "Store", value: order.storeName ?? store?.name ?? "—")
                    if let type = selectedType {
                        reviewRow(label: "Issue", value: type.title)
                    }
                    if let sub = selectedSubType {
                        reviewRow(label: "Detail", value: sub)
                    }
                    if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.secondaryLabel))
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.label))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                Text("After submitting, our team will review your complaint within 24 hours.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(.secondaryLabel))
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.label))
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if step > 0 {
                    Button(action: { step -= 1 }) {
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .foregroundColor(Color(.label))
                }

                Button(action: handleNext) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(step == 2 ? "Submit" : "Next")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(canProceed ? Color(.label) : Color(.systemFill))
                .foregroundColor(canProceed ? Color(.systemBackground) : Color(.secondaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(!canProceed || isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color(.systemBackground))
    }

    private var canProceed: Bool {
        switch step {
        case 0: return selectedType != nil
        case 1: return true
        default: return true
        }
    }

    private func handleNext() {
        hideKeyboard()
        if step < 2 {
            step += 1
        } else {
            Task { await submit() }
        }
    }

    private func submit() async {
        guard let type = selectedType else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            let id = try await ComplaintService.submitComplaint(
                orderId: order.id,
                complaintType: type.rawValue,
                subType: selectedSubType,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description
            )
            let isoNow = ISO8601DateFormatter().string(from: Date())
            let newComplaint = MyComplaint(
                id: id,
                orderId: order.id,
                complaintType: type.rawValue,
                subType: selectedSubType,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description,
                status: "PENDING",
                adminNotes: nil,
                responsibleParty: nil,
                storeName: order.storeName,
                storeIconUrl: nil,
                createdAt: isoNow,
                updatedAt: isoNow
            )
            didSucceed = true
            onSuccess?(newComplaint)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    // MARK: - Success
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.green)
            }
            Text("Complaint Submitted")
                .font(.system(size: 22, weight: .bold))
            Text("Our team will review your report within 24 hours. You'll hear back via email.")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(.label))
                    .foregroundColor(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Window Expired
    private var windowExpiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "clock.badge.xmark.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.red)
            }
            Text("Window Expired")
                .font(.system(size: 22, weight: .bold))
            Text("The 30-minute complaint window for this order has ended. Contact YSHOP support for further assistance.")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { dismiss() }) {
                Text("Close")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(Color(.label))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Helpers
    private func parseDate(_ raw: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            formatter.dateFormat = fmt
            if let d = formatter.date(from: raw) { return d }
        }
        return nil
    }
}

// MARK: - Complaint Types
enum ComplaintType: String, CaseIterable {
    case missingItem = "missing_item"
    case wrongItem = "wrong_item"
    case badQuality = "bad_quality"
    case lateDelivery = "late_delivery"
    case other = "other"

    var title: String {
        switch self {
        case .missingItem: return "Missing Item"
        case .wrongItem: return "Wrong Item"
        case .badQuality: return "Bad Quality / Damaged"
        case .lateDelivery: return "Late Delivery"
        case .other: return "Other Issue"
        }
    }

    var subtitle: String {
        switch self {
        case .missingItem: return "Part of my order was missing"
        case .wrongItem: return "I received the wrong product"
        case .badQuality: return "Product was damaged or not fresh"
        case .lateDelivery: return "Order arrived much later than expected"
        case .other: return "Something else went wrong"
        }
    }

    var icon: String {
        switch self {
        case .missingItem: return "bag.badge.minus"
        case .wrongItem: return "arrow.2.squarepath"
        case .badQuality: return "exclamationmark.triangle.fill"
        case .lateDelivery: return "clock.badge.exclamationmark.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .missingItem: return .orange
        case .wrongItem: return .blue
        case .badQuality: return .red
        case .lateDelivery: return .purple
        case .other: return .gray
        }
    }

    var subTypes: [String] {
        switch self {
        case .missingItem: return ["Full order missing", "1 item missing", "Multiple items missing"]
        case .wrongItem: return ["Wrong product", "Wrong quantity", "Wrong size/variant"]
        case .badQuality: return ["Expired product", "Damaged packaging", "Not fresh", "Spilled"]
        case .lateDelivery: return ["Over 30 min late", "Over 1 hour late"]
        case .other: return []
        }
    }
}

// MARK: - Flow Layout (tag chips)
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var y: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

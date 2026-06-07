import SwiftUI

struct ComplaintTrackingSheet: View {
    let complaint: MyComplaint

    @Environment(\.dismiss) private var dismiss

    private var statusColor: Color {
        switch complaint.status {
        case "APPROVED":     return .green
        case "REJECTED":     return Color(red: 0.94, green: 0.27, blue: 0.27)
        case "UNDER_REVIEW": return Color(red: 0.23, green: 0.51, blue: 0.98)
        default:             return .orange
        }
    }

    private var statusLabel: String {
        switch complaint.status {
        case "APPROVED":     return "Approved"
        case "REJECTED":     return "Rejected"
        case "UNDER_REVIEW": return "Under Review"
        default:             return "Pending"
        }
    }

    private var statusIcon: String {
        switch complaint.status {
        case "APPROVED":     return "checkmark.circle.fill"
        case "REJECTED":     return "xmark.circle.fill"
        case "UNDER_REVIEW": return "magnifyingglass.circle.fill"
        default:             return "clock.fill"
        }
    }

    private var responsibleLabel: String? {
        guard let p = complaint.responsibleParty, !p.isEmpty else { return nil }
        switch p {
        case "platform":        return "YShop Platform"
        case "store":           return "Store Owner"
        case "driver":          return "Driver"
        case "platform_store":  return "YShop + Store"
        case "platform_driver": return "YShop + Driver"
        case "store_driver":    return "Store + Driver"
        default:                return p
        }
    }

    private var complaintTypeLabel: String {
        complaint.complaintType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: statusIcon)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(statusColor)
                        }
                        Text(statusLabel)
                            .font(.title2.bold())
                            .foregroundColor(statusColor)
                        Text("Order #\(complaint.orderId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(statusColor.opacity(0.25), lineWidth: 1))

                    // Progress steps
                    _ProgressSteps(status: complaint.status)

                    // Complaint info
                    _InfoSection(title: "Your Complaint") {
                        _Row(label: "Type", value: complaintTypeLabel)
                        if let sub = complaint.subType, !sub.isEmpty {
                            _Row(label: "Detail", value: sub)
                        }
                        if let desc = complaint.description, !desc.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        _Row(label: "Submitted", value: formatDate(complaint.createdAt))
                    }

                    // Admin response (if any)
                    if let notes = complaint.adminNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("YShop Response", systemImage: "shield.checkered")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)

                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let party = responsibleLabel {
                                HStack(spacing: 6) {
                                    Image(systemName: "gavel")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                    Text("Responsible: \(party)")
                                        .font(.caption.bold())
                                        .foregroundColor(.purple)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.yellow.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.25), lineWidth: 1))
                    } else if complaint.status == "PENDING" || complaint.status == "UNDER_REVIEW" {
                        HStack(spacing: 10) {
                            Image(systemName: "clock.badge.questionmark")
                                .foregroundColor(.secondary)
                            Text("Our team is reviewing your complaint. We'll respond within 24 hours.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Complaint Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatDate(_ raw: String) -> String {
        let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"]
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        for f in formats {
            fmt.dateFormat = f
            if let d = fmt.date(from: raw) {
                let display = DateFormatter()
                display.dateStyle = .medium
                display.timeStyle = .short
                return display.string(from: d)
            }
        }
        return raw
    }
}

// MARK: - Progress Steps

private struct _ProgressSteps: View {
    let status: String

    private let steps: [(String, String, String)] = [
        ("Submitted",    "checkmark.circle",        "Your complaint was received"),
        ("Under Review", "magnifyingglass.circle",  "Our team is investigating"),
        ("Resolved",     "checkmark.seal",          "Resolution has been made"),
    ]

    private var currentStep: Int {
        switch status {
        case "APPROVED", "REJECTED": return 2
        case "UNDER_REVIEW":         return 1
        default:                     return 0
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                let (label, icon, desc) = steps[i]
                let done = i <= currentStep
                let active = i == currentStep

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(done ? Color.accentColor.opacity(0.15) : Color(.systemFill))
                            .frame(width: 40, height: 40)
                        Image(systemName: done ? icon : "\(icon).fill")
                            .font(.system(size: 16, weight: active ? .bold : .regular))
                            .foregroundColor(done ? .accentColor : .secondary)
                    }
                    Text(label)
                        .font(.caption.bold())
                        .foregroundColor(done ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                    if active {
                        Text(desc)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)

                if i < steps.count - 1 {
                    Rectangle()
                        .fill(i < currentStep ? Color.accentColor : Color(.systemFill))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 19)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Helpers

private struct _InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .tracking(0.8)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct _Row: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

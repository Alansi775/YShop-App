import SwiftUI

// MARK: - Driver Complaint Model

struct DriverComplaint: Decodable, Identifiable {
    let id: Int
    let orderId: String      // MySQL returns order_id as Int — decoded flexibly
    let complaintType: String
    let subType: String?
    let description: String?
    let status: String
    let adminNotes: String?
    let responsibleParty: String?
    let customerName: String?
    let storeName: String?
    let totalPrice: Double?
    let currency: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case orderId         = "order_id"
        case complaintType   = "complaint_type"
        case subType         = "sub_type"
        case description
        case status
        case adminNotes      = "admin_notes"
        case responsibleParty = "responsible_party"
        case customerName    = "customer_name"
        case storeName       = "store_name"
        case totalPrice      = "total_price"
        case currency
        case createdAt       = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(Int.self, forKey: .id)
        if let intVal = try? c.decode(Int.self, forKey: .orderId) {
            orderId = String(intVal)
        } else {
            orderId = try c.decode(String.self, forKey: .orderId)
        }
        complaintType    = try c.decode(String.self, forKey: .complaintType)
        subType          = try? c.decode(String.self, forKey: .subType)
        description      = try? c.decode(String.self, forKey: .description)
        status           = try c.decode(String.self, forKey: .status)
        adminNotes       = try? c.decode(String.self, forKey: .adminNotes)
        responsibleParty = try? c.decode(String.self, forKey: .responsibleParty)
        customerName     = try? c.decode(String.self, forKey: .customerName)
        storeName        = try? c.decode(String.self, forKey: .storeName)
        totalPrice       = try? c.decode(Double.self, forKey: .totalPrice)
        currency         = try? c.decode(String.self, forKey: .currency)
        createdAt        = try c.decode(String.self, forKey: .createdAt)
    }
}

private struct DriverComplaintsResponse: Decodable {
    let success: Bool
    let data: [DriverComplaint]?
}

// MARK: - Driver Complaints View

struct DriverComplaintsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var complaints: [DriverComplaint] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                DeliveryTheme.darkBackground.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(DeliveryTheme.accentBlue)
                } else if complaints.isEmpty {
                    _emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(complaints) { c in
                                _ComplaintCard(complaint: c)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Complaints About Me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DeliveryTheme.accentBlue)
                }
            }
            .task { await load() }
        }
    }

    private var _emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(DeliveryTheme.accentBlue.opacity(0.4))
            Text("No Complaints")
                .font(.title2.bold())
                .foregroundColor(DeliveryTheme.primaryText)
            Text("You have no complaints assigned to you.")
                .font(.subheadline)
                .foregroundColor(DeliveryTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private func load() async {
        isLoading = true
        if let response = try? await (APIClient.shared.request(.getDriverComplaints) as DriverComplaintsResponse) {
            complaints = response.data ?? []
        }
        isLoading = false
    }
}

// MARK: - Complaint Card

private struct _ComplaintCard: View {
    let complaint: DriverComplaint

    private var statusColor: Color {
        switch complaint.status {
        case "APPROVED":     return .green
        case "REJECTED":     return Color(red: 0.94, green: 0.27, blue: 0.27)
        case "UNDER_REVIEW": return DeliveryTheme.accentBlue
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

    private var typeLabel: String {
        complaint.complaintType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var isDriverResponsible: Bool {
        guard let p = complaint.responsibleParty else { return false }
        return p.contains("driver")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                Text("Order #\(complaint.orderId)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DeliveryTheme.primaryText)
            }

            // Responsibility warning
            if isDriverResponsible {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 13))
                    Text("You have been identified as responsible for this complaint.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.25), lineWidth: 1))
            }

            // Complaint info
            VStack(spacing: 8) {
                _kv("Issue", typeLabel)
                if let sub = complaint.subType, !sub.isEmpty {
                    _kv("Detail", sub)
                }
                if let customer = complaint.customerName, !customer.isEmpty {
                    _kv("Customer", customer)
                }
                if let store = complaint.storeName, !store.isEmpty {
                    _kv("Store", store)
                }
                if let total = complaint.totalPrice {
                    _kv("Order Total", "\(String(format: "%.2f", total)) \(complaint.currency ?? "SAR")")
                }
                _kv("Filed On", formatDate(complaint.createdAt))
            }

            // Description
            if let desc = complaint.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customer's Statement")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DeliveryTheme.secondaryText)
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(DeliveryTheme.primaryText.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Admin response
            if let notes = complaint.adminNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("YShop Decision", systemImage: "shield.checkered")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.yellow)

                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(Color.yellow.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.yellow.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(16)
        .background(DeliveryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDriverResponsible ? Color.orange.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func _kv(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(DeliveryTheme.secondaryText)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DeliveryTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formatDate(_ raw: String) -> String {
        let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"]
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        for f in formats {
            fmt.dateFormat = f
            if let d = fmt.date(from: raw) {
                let out = DateFormatter()
                out.dateStyle = .medium
                out.timeStyle = .short
                return out.string(from: d)
            }
        }
        return raw
    }
}

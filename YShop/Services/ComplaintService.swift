import Foundation

struct ComplaintSubmitResponse: Decodable {
    let success: Bool
    let data: ComplaintData?

    struct ComplaintData: Decodable {
        let id: Int?
    }
}

private struct GenericResponse: Decodable {
    let success: Bool?
    let message: String?
}

struct MyComplaint: Decodable, Identifiable {
    let id: Int
    let orderId: String      // stored as Int in MySQL, decoded flexibly
    let complaintType: String
    let subType: String?
    let description: String?
    let status: String
    let adminNotes: String?
    let responsibleParty: String?
    let storeName: String?
    let storeIconUrl: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case orderId          = "order_id"
        case complaintType    = "complaint_type"
        case subType          = "sub_type"
        case description
        case status
        case adminNotes       = "admin_notes"
        case responsibleParty = "responsible_party"
        case storeName        = "store_name"
        case storeIconUrl     = "store_icon_url"
        case createdAt        = "created_at"
        case updatedAt        = "updated_at"
    }

    // MySQL returns order_id as integer — handle both Int and String
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
        storeName        = try? c.decode(String.self, forKey: .storeName)
        storeIconUrl     = try? c.decode(String.self, forKey: .storeIconUrl)
        createdAt        = try c.decode(String.self, forKey: .createdAt)
        updatedAt        = try c.decode(String.self, forKey: .updatedAt)
    }

    // Direct initializer for building placeholder complaints after submission
    init(id: Int, orderId: String, complaintType: String, subType: String?,
         description: String?, status: String, adminNotes: String?,
         responsibleParty: String?, storeName: String?, storeIconUrl: String?,
         createdAt: String, updatedAt: String) {
        self.id = id; self.orderId = orderId; self.complaintType = complaintType
        self.subType = subType; self.description = description; self.status = status
        self.adminNotes = adminNotes; self.responsibleParty = responsibleParty
        self.storeName = storeName; self.storeIconUrl = storeIconUrl
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

private struct MyComplaintsResponse: Decodable {
    let success: Bool
    let data: [MyComplaint]?
}

private struct SingleComplaintResponse: Decodable {
    let success: Bool
    let data: MyComplaint?
}

struct ComplaintRequest: Encodable {
    let orderId: String
    let complaintType: String
    let subType: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "orderId"
        case complaintType = "complaintType"
        case subType = "subType"
        case description
    }
}

class ComplaintService {
    static func submitComplaint(
        orderId: String,
        complaintType: String,
        subType: String?,
        description: String?
    ) async throws -> Int {
        let body = ComplaintRequest(
            orderId: orderId,
            complaintType: complaintType,
            subType: subType,
            description: description
        )
        let response: ComplaintSubmitResponse = try await APIClient.shared.request(.submitComplaint, body: body)
        return response.data?.id ?? 0
    }

    static func getComplainedOrderIds() async -> Set<String> {
        guard let response = try? await (APIClient.shared.request(.getMyComplaints) as MyComplaintsResponse) else {
            return []
        }
        return Set((response.data ?? []).map { $0.orderId })
    }

    static func getMyComplaints() async -> [MyComplaint] {
        guard let response = try? await (APIClient.shared.request(.getMyComplaints) as MyComplaintsResponse) else {
            return []
        }
        return response.data ?? []
    }

    static func getComplaintDetail(id: Int) async -> MyComplaint? {
        guard let response = try? await (APIClient.shared.request(.getComplaintDetail(id)) as SingleComplaintResponse) else {
            return nil
        }
        return response.data
    }
}

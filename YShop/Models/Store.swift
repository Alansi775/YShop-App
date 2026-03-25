import Foundation

struct Store: Codable, Identifiable {
    let id: Int
    let name: String
    let storeType: String?
    let iconUrl: String?
    let address: String?
    let phone: String?
    var status: String?
    let email: String?
    let ownerUid: String?
    let uid: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, email, address
        case storeType = "store_type"
        case iconUrl = "icon_url"
        case phone
        case ownerUid = "owner_uid"
        case uid
    }

    // Computed property to get full image URL
    var fullIconUrl: String? {
        guard let iconUrl = iconUrl, !iconUrl.isEmpty else { return nil }
        if iconUrl.starts(with: "http") {
            return iconUrl
        }
        let baseHost = "http://10.155.83.72:3000"
        return baseHost + iconUrl
    }

    static let mock = Store(
        id: 1,
        name: "Premium Foods Market",
        storeType: "Food",
        iconUrl: "/uploads/stores/icon.png",
        address: "123 Main Street",
        phone: "555-1234",
        status: "Active",
        email: "store@email.com",
        ownerUid: "owner123",
        uid: "store456"
    )
}

import Foundation

struct Store: Codable, Identifiable {
    let id: Int
    let name: String
    let storeType: String?
    let iconUrl: String?
    let address: String?
    let phone: String?
    let latitude: Double?
    let longitude: Double?
    var status: String?
    let email: String?
    let ownerUid: String?
    let uid: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, email, address
        case storeType = "store_type"
        case iconUrl = "icon_url"
        case phone
        case latitude
        case longitude
        case ownerUid = "owner_uid"
        case uid
    }

    init(
        id: Int,
        name: String,
        storeType: String?,
        iconUrl: String?,
        address: String?,
        phone: String?,
        latitude: Double? = nil,
        longitude: Double? = nil,
        status: String?,
        email: String?,
        ownerUid: String?,
        uid: String?
    ) {
        self.id = id
        self.name = name
        self.storeType = storeType
        self.iconUrl = iconUrl
        self.address = address
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.email = email
        self.ownerUid = ownerUid
        self.uid = uid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = (try? container.decode(Int.self, forKey: .id)) ?? (Int((try? container.decode(String.self, forKey: .id)) ?? "") ?? 0)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        storeType = try? container.decodeIfPresent(String.self, forKey: .storeType)
        iconUrl = try? container.decodeIfPresent(String.self, forKey: .iconUrl)
        address = try? container.decodeIfPresent(String.self, forKey: .address)
        phone = try? container.decodeIfPresent(String.self, forKey: .phone)
        latitude = Self.decodeFlexibleDouble(container, key: .latitude)
        longitude = Self.decodeFlexibleDouble(container, key: .longitude)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        email = try? container.decodeIfPresent(String.self, forKey: .email)
        ownerUid = try? container.decodeIfPresent(String.self, forKey: .ownerUid)
        uid = try? container.decodeIfPresent(String.self, forKey: .uid)
    }

    // Computed property to get full image URL
    var fullIconUrl: String? {
        guard let iconUrl = iconUrl, !iconUrl.isEmpty else { 
            print("❌ [STORE] No iconUrl")
            return nil 
        }
        
        let baseURL = "http://192.168.1.80:3000"
        
        if iconUrl.starts(with: "http") {
            print("✅ [STORE] Full URL: \(iconUrl)")
            return iconUrl
        }
        
        let fullURL = iconUrl.starts(with: "/") ? baseURL + iconUrl : baseURL + "/" + iconUrl
        print("✅ [STORE] Built URL: \(fullURL)")
        return fullURL
    }

    static let mock = Store(
        id: 1,
        name: "Premium Foods Market",
        storeType: "Food",
        iconUrl: "/uploads/stores/icon.png",
        address: "123 Main Street",
        phone: "555-1234",
        latitude: nil,
        longitude: nil,
        status: "Active",
        email: "store@email.com",
        ownerUid: "owner123",
        uid: "store456"
    )
}

private extension Store {
    static func decodeFlexibleDouble(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }

        if let value = try? container.decodeIfPresent(String.self, forKey: key), let decoded = Double(value) {
            return decoded
        }

        return nil
    }
}

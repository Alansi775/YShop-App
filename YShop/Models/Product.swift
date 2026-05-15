import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let price: String  // Backend returns as string "350.00"
    let currency: String?  // Optional currency field
    let image_url: String?
    let imageURLs: [String]?
    let category_id: Int
    let store_id: Int
    let stock: Int
    let status: String?
    let is_active: Int?  // Backend returns as 0 or 1, NOT boolean
    let created_at: String?
    let updated_at: String?
    
    // Extra fields from backend (optional for compatibility)
    let store_name: String?
    let store_phone: String?
    let owner_email: String?
    let owner_uid: String?
    let category_name: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, stock, status, currency
        case image_url
        case imageURLs = "images"
        case imageUrls = "image_urls"
        case gallery
        case category_id
        case store_id
        case is_active
        case created_at
        case updated_at
        case store_name
        case store_phone
        case owner_email
        case owner_uid
        case category_name
    }

    init(
        id: Int,
        name: String,
        description: String?,
        price: String,
        currency: String?,
        image_url: String?,
        imageURLs: [String]? = nil,
        category_id: Int,
        store_id: Int,
        stock: Int,
        status: String?,
        is_active: Int?,
        created_at: String?,
        updated_at: String?,
        store_name: String?,
        store_phone: String?,
        owner_email: String?,
        owner_uid: String?,
        category_name: String?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.currency = currency
        self.image_url = image_url
        self.imageURLs = imageURLs
        self.category_id = category_id
        self.store_id = store_id
        self.stock = stock
        self.status = status
        self.is_active = is_active
        self.created_at = created_at
        self.updated_at = updated_at
        self.store_name = store_name
        self.store_phone = store_phone
        self.owner_email = owner_email
        self.owner_uid = owner_uid
        self.category_name = category_name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeFlexibleInt(forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        price = (try? container.decode(String.self, forKey: .price)) ?? String((try? container.decode(Double.self, forKey: .price)) ?? 0)
        currency = try? container.decodeIfPresent(String.self, forKey: .currency)
        image_url = try? container.decodeIfPresent(String.self, forKey: .image_url)
        imageURLs = Product.decodeImageURLs(from: container)
        category_id = try container.decodeFlexibleInt(forKey: .category_id)
        store_id = try container.decodeFlexibleInt(forKey: .store_id)
        stock = try container.decodeFlexibleInt(forKey: .stock)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        is_active = try? container.decodeIfPresent(Int.self, forKey: .is_active)
        created_at = try? container.decodeIfPresent(String.self, forKey: .created_at)
        updated_at = try? container.decodeIfPresent(String.self, forKey: .updated_at)
        store_name = try? container.decodeIfPresent(String.self, forKey: .store_name)
        store_phone = try? container.decodeIfPresent(String.self, forKey: .store_phone)
        owner_email = try? container.decodeIfPresent(String.self, forKey: .owner_email)
        owner_uid = try? container.decodeIfPresent(String.self, forKey: .owner_uid)
        category_name = try? container.decodeIfPresent(String.self, forKey: .category_name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encodeIfPresent(image_url, forKey: .image_url)
        try container.encodeIfPresent(imageURLs, forKey: .imageURLs)
        try container.encode(category_id, forKey: .category_id)
        try container.encode(store_id, forKey: .store_id)
        try container.encode(stock, forKey: .stock)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(is_active, forKey: .is_active)
        try container.encodeIfPresent(created_at, forKey: .created_at)
        try container.encodeIfPresent(updated_at, forKey: .updated_at)
        try container.encodeIfPresent(store_name, forKey: .store_name)
        try container.encodeIfPresent(store_phone, forKey: .store_phone)
        try container.encodeIfPresent(owner_email, forKey: .owner_email)
        try container.encodeIfPresent(owner_uid, forKey: .owner_uid)
        try container.encodeIfPresent(category_name, forKey: .category_name)
    }
    
    // Computed property for price as Double
    var priceDouble: Double {
        return Double(price) ?? 0.0
    }

    var imageGalleryUrls: [String] {
        var urls = [String]()

        if let imageURLs {
            urls.append(contentsOf: imageURLs)
        }

        if let image_url, !image_url.isEmpty {
            urls.append(image_url)
        }

        return Array(NSOrderedSet(array: urls.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })) as? [String] ?? urls
    }

    var primaryImageUrl: String? {
        imageGalleryUrls.first
    }
    
    // Computed property for currency symbol
    var currencySymbol: String {
        switch currency?.uppercased() {
        case "TRY": return "₺"           // Turkish Lira
        case "USD": return "$"            // US Dollar
        case "EUR": return "€"            // Euro
        case "GBP": return "£"            // British Pound
        case "JPY": return "¥"            // Japanese Yen
        case "AED": return "د.إ"          // UAE Dirham
        case "YER": return "﷼"            // Yemeni Rial
        case "SAR": return "﷼"            // Saudi Riyal
        default: return "₺"              // Default to Turkish Lira
        }
    }
    
    // Formatted price with currency
    var formattedPrice: String {
        return "\(currencySymbol)\(String(format: "%.2f", priceDouble))"
    }
    
    // Computed property for full image URL
    var fullImageUrl: String? {
        guard let image_url = primaryImageUrl, !image_url.isEmpty else { return nil }
        
        // If already a full URL, try to fix localhost -> actual IP
        if image_url.starts(with: "http") {
            // Replace localhost with actual server IP
            if image_url.contains("localhost:3000") {
                let baseHost = AppConstants.baseURLCandidates.first ?? "http://10.155.83.72:3000"
                let cleanBase = baseHost.replacingOccurrences(of: "/api/v1", with: "")
                return image_url.replacingOccurrences(of: "http://localhost:3000", with: cleanBase)
            }
            return image_url
        }
        
        // If relative path, build full URL
        let baseHost = AppConstants.baseURLCandidates.first ?? "http://10.155.83.72:3000"
        let cleanBase = baseHost.replacingOccurrences(of: "/api/v1", with: "")
        return cleanBase + image_url
    }
    
    static let mock = Product(
        id: 1,
        name: "Fresh Apples",
        description: "Organic Fuji apples",
        price: "5.99",
        currency: "USD",
        image_url: nil,
        imageURLs: nil,
        category_id: 1,
        store_id: 1,
        stock: 50,
        status: "approved",
        is_active: 1,
        created_at: nil,
        updated_at: nil,
        store_name: "Fresh Store",
        store_phone: nil,
        owner_email: nil,
        owner_uid: nil,
        category_name: nil
    )
}

private extension KeyedDecodingContainer where Key == Product.CodingKeys {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }

        if let value = try? decode(String.self, forKey: key), let decoded = Int(value) {
            return decoded
        }

        return 0
    }
}

private extension Product {
    static func decodeImageURLs(from container: KeyedDecodingContainer<CodingKeys>) -> [String]? {
        let keys: [CodingKeys] = [.imageURLs, .imageUrls, .gallery]

        for key in keys {
            if let values = try? container.decode([String].self, forKey: key) {
                let normalized = values
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !normalized.isEmpty {
                    return normalized
                }
            }

            if let rawValue = try? container.decode(String.self, forKey: key) {
                let normalized = rawValue
                    .split(whereSeparator: { $0 == "," || $0 == "\n" })
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !normalized.isEmpty {
                    return normalized
                }
            }
        }

        return nil
    }
}

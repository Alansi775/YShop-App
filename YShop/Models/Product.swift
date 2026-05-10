import Foundation

struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let price: String  // Backend returns as string "350.00"
    let currency: String?  // Optional currency field
    let image_url: String?
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
    
    // Computed property for price as Double
    var priceDouble: Double {
        return Double(price) ?? 0.0
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
        guard let image_url = image_url, !image_url.isEmpty else { return nil }
        
        // If already a full URL, try to fix localhost -> actual IP
        if image_url.starts(with: "http") {
            // Replace localhost with actual server IP
            if image_url.contains("localhost:3000") {
                let baseHost = AppConstants.baseURLCandidates.first ?? "http://192.168.1.54:3000"
                let cleanBase = baseHost.replacingOccurrences(of: "/api/v1", with: "")
                return image_url.replacingOccurrences(of: "http://localhost:3000", with: cleanBase)
            }
            return image_url
        }
        
        // If relative path, build full URL
        let baseHost = AppConstants.baseURLCandidates.first ?? "http://192.168.1.54:3000"
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

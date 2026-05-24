import Foundation

struct CartItem: Codable, Identifiable {
    let id: String
    let userId: String
    let productId: String
    let storeId: String
    let quantity: Int
    let price: Double
    let product: Product?
    let name: String?
    let imageUrl: String?
    let currency: String?
    let stock: Int?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case productId = "product_id"
        case storeId = "store_id"
        case quantity
        case price
        case product
        case name
        case imageUrl = "image_url"
        case currency
        case stock
        case status
    }

    enum AltCodingKeys: String, CodingKey {
        case imageUrl
    }

    init(
        id: String,
        userId: String,
        productId: String,
        storeId: String,
        quantity: Int,
        price: Double,
        product: Product? = nil,
        name: String? = nil,
        imageUrl: String? = nil,
        currency: String? = nil,
        stock: Int? = nil,
        status: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.productId = productId
        self.storeId = storeId
        self.quantity = quantity
        self.price = price
        self.product = product
        self.name = name
        self.imageUrl = imageUrl
        self.currency = currency
        self.stock = stock
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let altContainer = try decoder.container(keyedBy: AltCodingKeys.self)

        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = (try? container.decode(String.self, forKey: .id)) ?? ""
        }

        if let intUserId = try? container.decode(Int.self, forKey: .userId) {
            userId = String(intUserId)
        } else {
            userId = (try? container.decode(String.self, forKey: .userId)) ?? ""
        }

        if let intProductId = try? container.decode(Int.self, forKey: .productId) {
            productId = String(intProductId)
        } else {
            productId = (try? container.decode(String.self, forKey: .productId)) ?? ""
        }

        if let intStoreId = try? container.decode(Int.self, forKey: .storeId) {
            storeId = String(intStoreId)
        } else {
            storeId = (try? container.decode(String.self, forKey: .storeId)) ?? ""
        }

        quantity = (try? container.decode(Int.self, forKey: .quantity)) ?? 1

        if let decodedPrice = try? container.decode(Double.self, forKey: .price) {
            price = decodedPrice
        } else if let priceString = try? container.decode(String.self, forKey: .price), let decoded = Double(priceString) {
            price = decoded
        } else if let intPrice = try? container.decode(Int.self, forKey: .price) {
            price = Double(intPrice)
        } else {
            price = 0
        }

        product = try? container.decodeIfPresent(Product.self, forKey: .product)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        imageUrl = (try? container.decodeIfPresent(String.self, forKey: .imageUrl))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .imageUrl))
        currency = try? container.decodeIfPresent(String.self, forKey: .currency)
        stock = try? container.decodeIfPresent(Int.self, forKey: .stock)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
    }

    var displayName: String {
        name ?? product?.name ?? "Product"
    }

    var displayCurrency: String? {
        currency ?? product?.currency
    }

    var currencySymbol: String {
        switch displayCurrency?.uppercased() {
        case "TRY": return "₺"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "AED": return "د.إ"
        case "YER": return "﷼"
        case "SAR": return "﷼"
        default: return "₺"
        }
    }

    var formattedPrice: String {
        "\(currencySymbol)\(String(format: "%.2f", price))"
    }

    var fullImageUrl: String? {
    // First try direct imageUrl
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            let baseURL = "http://192.168.1.80:3000"
            
            if imageUrl.starts(with: "http") {
                print("✅ [CARTITEM] Full URL: \(imageUrl)")
                return imageUrl
            }
            
            let fullURL = imageUrl.starts(with: "/") ? baseURL + imageUrl : baseURL + "/" + imageUrl
            print("✅ [CARTITEM] Built URL: \(fullURL)")
            return fullURL
        }
        
        // Fallback to product's fullImageUrl
        return product?.fullImageUrl
    }
    
    static let mock = CartItem(
        id: "1",
        userId: "user1",
        productId: "prod1",
        storeId: "store1",
        quantity: 2,
        price: 5.99,
        product: .mock
    )
}

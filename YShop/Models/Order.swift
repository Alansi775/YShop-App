import Foundation

enum OrderStatus: String, Codable {
    case pending, confirmed, processing, shipped, outForDelivery = "out_for_delivery", delivered, cancelled, failed

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        let normalizedValue = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()

        switch normalizedValue {
        case "pending":
            self = .pending
        case "confirmed":
            self = .confirmed
        case "processing":
            self = .processing
        case "shipped", "out_for_delivery", "outfordelivery", "delivering":
            self = .outForDelivery
        case "delivered":
            self = .delivered
        case "cancelled", "canceled":
            self = .cancelled
        case "failed":
            self = .failed
        default:
            self = .pending
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct Order: Codable, Identifiable {
    let id: String
    let userId: String
    let storeId: String
    var items: [CartItem]  // Changed from 'let' to 'var' to allow mutation
    let totalPrice: Double
    let status: OrderStatus
    let deliveryAddress: String?
    let storeName: String?
    let phone: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
    let customerName: String?
    let customerPhone: String?
    let driverName: String?
    let driverId: String?
    let driverLocation: String?
    let paymentMethod: String?
    let pickedUpAt: String?
    let deliveredAt: String?
    let shippingAddress: String?
    let customerLatitude: Double?
    let customerLongitude: Double?
    let storeLatitude: Double?
    let storeLongitude: Double?
    let storeIconUrl: String?

    init(
        id: String,
        userId: String,
        storeId: String,
        items: [CartItem],
        totalPrice: Double,
        status: OrderStatus,
        deliveryAddress: String?,
        storeName: String?,
        phone: String?,
        notes: String?,
        createdAt: String?,
        updatedAt: String?,
        customerName: String?,
        customerPhone: String?,
        driverName: String? = nil,
        driverId: String?,
        driverLocation: String?,
        paymentMethod: String? = nil,
        pickedUpAt: String?,
        deliveredAt: String?,
        shippingAddress: String?,
        customerLatitude: Double? = nil,
        customerLongitude: Double? = nil,
        storeLatitude: Double? = nil,
        storeLongitude: Double? = nil,
        storeIconUrl: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.storeId = storeId
        self.items = items
        self.totalPrice = totalPrice
        self.status = status
        self.deliveryAddress = deliveryAddress
        self.storeName = storeName
        self.phone = phone
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.driverName = driverName
        self.driverId = driverId
        self.driverLocation = driverLocation
        self.paymentMethod = paymentMethod
        self.pickedUpAt = pickedUpAt
        self.deliveredAt = deliveredAt
        self.shippingAddress = shippingAddress
        self.customerLatitude = customerLatitude
        self.customerLongitude = customerLongitude
        self.storeLatitude = storeLatitude
        self.storeLongitude = storeLongitude
        self.storeIconUrl = storeIconUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storeId = "store_id"
        case items, status, notes
        case totalPrice = "total_price"
        case deliveryAddress = "delivery_address"
        case shippingAddress = "shipping_address"
        case storeName = "store_name"
        case phone
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
        case driverName = "driver_name"
        case driverId
        case driverLocation
        case paymentMethod = "payment_method"
        case pickedUpAt = "picked_up_at"
        case deliveredAt = "delivered_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case customerLatitude = "location_Latitude"
        case customerLongitude = "location_Longitude"
        case storeLatitude = "store_latitude"
        case storeLongitude = "store_longitude"
        case storeIconUrl = "store_icon_url"
    }

    enum AltCodingKeys: String, CodingKey {
        case addressFull = "address_Full"
        case total = "total"
        case storeName = "storeName"
        case customer
        case customerName = "customerName"
        case customerPhone = "customerPhone"
        case driverName
        case driverId = "driverId"
        case driverLocation = "driver_location"
        case paymentMethod = "payment_method"
        case pickedUpAt = "picked_up_at"
        case deliveredAt = "delivered_at"
        case customerLatitude = "location_Latitude"
        case customerLongitude = "location_Longitude"
        case storeLatitude = "storeLatitude"
        case storeLongitude = "storeLongitude"
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

        if let intStoreId = try? container.decode(Int.self, forKey: .storeId) {
            storeId = String(intStoreId)
        } else {
            storeId = (try? container.decode(String.self, forKey: .storeId)) ?? ""
        }

        if let decodedItems = try? container.decode([CartItem].self, forKey: .items) {
            items = decodedItems
        } else {
            items = []
        }

        if let decodedTotal = try? container.decode(Double.self, forKey: .totalPrice) {
            totalPrice = decodedTotal
        } else if let totalString = try? container.decode(String.self, forKey: .totalPrice), let decoded = Double(totalString) {
            totalPrice = decoded
        } else if let alternateTotal = try? altContainer.decode(String.self, forKey: .total), let decoded = Double(alternateTotal) {
            totalPrice = decoded
        } else {
            totalPrice = 0
        }

        status = (try? container.decode(OrderStatus.self, forKey: .status)) ?? .pending

        deliveryAddress = (try? container.decodeIfPresent(String.self, forKey: .deliveryAddress))
            ?? (try? container.decodeIfPresent(String.self, forKey: .shippingAddress))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .addressFull))

        shippingAddress = (try? container.decodeIfPresent(String.self, forKey: .shippingAddress))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .addressFull))

        storeName = (try? container.decodeIfPresent(String.self, forKey: .storeName))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .storeName))

        storeIconUrl = (try? container.decodeIfPresent(String.self, forKey: .storeIconUrl))

        phone = (try? container.decodeIfPresent(String.self, forKey: .phone))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .customerPhone))

        notes = try? container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = (try? container.decodeIfPresent(String.self, forKey: .createdAt))
            ?? (try? container.decodeIfPresent(String.self, forKey: .updatedAt))
        updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)

        customerName = (try? container.decodeIfPresent(String.self, forKey: .customerName))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .customerName))
        customerPhone = (try? container.decodeIfPresent(String.self, forKey: .customerPhone))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .customerPhone))
        driverName = (try? container.decodeIfPresent(String.self, forKey: .driverName))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .driverName))
        driverId = (try? altContainer.decodeIfPresent(String.self, forKey: .driverId))
            ?? (try? container.decodeIfPresent(String.self, forKey: .driverId))

        if let rawLocation = (try? altContainer.decodeIfPresent(String.self, forKey: .driverLocation))
            ?? (try? container.decodeIfPresent(String.self, forKey: .driverLocation)) {
            driverLocation = rawLocation
        } else if let payload = (try? altContainer.decodeIfPresent(DriverLocationPayload.self, forKey: .driverLocation))
            ?? (try? container.decodeIfPresent(DriverLocationPayload.self, forKey: .driverLocation)) {
            driverLocation = payload.asCoordinateString
        } else {
            driverLocation = nil
        }

        paymentMethod = (try? container.decodeIfPresent(String.self, forKey: .paymentMethod))
            ?? (try? altContainer.decodeIfPresent(String.self, forKey: .paymentMethod))

        pickedUpAt = (try? altContainer.decodeIfPresent(String.self, forKey: .pickedUpAt))
            ?? (try? container.decodeIfPresent(String.self, forKey: .pickedUpAt))
        deliveredAt = (try? altContainer.decodeIfPresent(String.self, forKey: .deliveredAt))
            ?? (try? container.decodeIfPresent(String.self, forKey: .deliveredAt))

        customerLatitude = Self.decodeFlexibleDouble(container, altContainer: altContainer, primaryKey: .customerLatitude, fallbackKey: .customerLatitude)
        customerLongitude = Self.decodeFlexibleDouble(container, altContainer: altContainer, primaryKey: .customerLongitude, fallbackKey: .customerLongitude)
        storeLatitude = Self.decodeFlexibleDouble(container, altContainer: altContainer, primaryKey: .storeLatitude, fallbackKey: .storeLatitude)
        storeLongitude = Self.decodeFlexibleDouble(container, altContainer: altContainer, primaryKey: .storeLongitude, fallbackKey: .storeLongitude)
    }

    var customerCoordinate: (latitude: Double, longitude: Double)? {
        guard let customerLatitude, let customerLongitude else { return nil }
        return (customerLatitude, customerLongitude)
    }

    var storeCoordinate: (latitude: Double, longitude: Double)? {
        guard let storeLatitude, let storeLongitude else { return nil }
        return (storeLatitude, storeLongitude)
    }

    // Computed property to build a full URL for the store icon
    var storeIconFullUrl: String? {
        guard let iconUrl = storeIconUrl, !iconUrl.isEmpty else { return nil }

        // Use first base candidate and remove API prefix if present
        let baseHost = AppConstants.baseURLCandidates.first ?? "http://192.168.1.80:3000"
        let cleanBase = baseHost.replacingOccurrences(of: "/api/v1", with: "")

        if iconUrl.starts(with: "http") {
            return iconUrl.contains("localhost:3000") ? iconUrl.replacingOccurrences(of: "http://localhost:3000", with: cleanBase) : iconUrl
        }
        return cleanBase + (iconUrl.starts(with: "/") ? iconUrl : "/" + iconUrl)
    }
    
    static let mock = Order(
        id: "1",
        userId: "user1",
        storeId: "store1",
        items: [.mock],
        totalPrice: 11.98,
        status: .pending,
        deliveryAddress: "123 Main St",
        storeName: "Store",
        phone: nil,
        notes: nil,
        createdAt: nil,
        updatedAt: nil,
        customerName: nil,
        customerPhone: nil,
        driverId: nil,
        driverLocation: nil,
        paymentMethod: nil,
        pickedUpAt: nil,
        deliveredAt: nil,
        shippingAddress: nil,
        customerLatitude: nil,
        customerLongitude: nil,
        storeLatitude: nil,
        storeLongitude: nil
    )
}

private struct DriverLocationPayload: Decodable {
    let latitude: Double?
    let longitude: Double?
    let lat: Double?
    let lng: Double?
    let coordinates: [Double]?

    var asCoordinateString: String? {
        if let latitude, let longitude {
            return "\(latitude),\(longitude)"
        }

        if let lat, let lng {
            return "\(lat),\(lng)"
        }

        if let coordinates, coordinates.count >= 2 {
            return "\(coordinates[0]),\(coordinates[1])"
        }

        return nil
    }
}

private extension Order {
    static func decodeFlexibleDouble(
        _ container: KeyedDecodingContainer<CodingKeys>,
        altContainer: KeyedDecodingContainer<AltCodingKeys>,
        primaryKey: CodingKeys,
        fallbackKey: AltCodingKeys
    ) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: primaryKey) {
            return value
        }

        if let value = try? container.decodeIfPresent(String.self, forKey: primaryKey), let decoded = Double(value) {
            return decoded
        }

        if let value = try? altContainer.decodeIfPresent(Double.self, forKey: fallbackKey) {
            return value
        }

        if let value = try? altContainer.decodeIfPresent(String.self, forKey: fallbackKey), let decoded = Double(value) {
            return decoded
        }

        return nil
    }
}

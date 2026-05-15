import Foundation

struct CheckoutOrderItemRequest: Encodable {
    let productId: String
    let price: Double
    let quantity: Int
}

struct CheckoutOrderRequest: Encodable {
    let storeId: String
    let totalPrice: Double
    let shippingAddress: String
    let items: [CheckoutOrderItemRequest]
    let paymentMethod: String
    let deliveryOption: String
}

struct CheckoutCreatedOrderResponse: Decodable {
    let id: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
    }
}

final class CheckoutService {
    private static var lastSubmissionFingerprint: String?
    private static var lastSubmissionTime: Date?

    static func placeOrders(
        cartItems: [CartItem],
        shippingAddress: String,
        paymentMethod: String,
        deliveryOption: String
    ) async throws -> [String] {
        guard !cartItems.isEmpty else {
            throw APIError.validationError("Your cart is empty.")
        }

        let fingerprint = Self.makeFingerprint(
            cartItems: cartItems,
            shippingAddress: shippingAddress,
            paymentMethod: paymentMethod,
            deliveryOption: deliveryOption
        )

        if let lastFingerprint = lastSubmissionFingerprint,
           let lastTime = lastSubmissionTime,
           lastFingerprint == fingerprint,
           Date().timeIntervalSince(lastTime) < 5 {
            throw APIError.validationError("Duplicate order submission blocked.")
        }

        lastSubmissionFingerprint = fingerprint
        lastSubmissionTime = Date()

        let groupedItems = Dictionary(grouping: cartItems) { $0.storeId }
        var createdOrderIds: [String] = []

        for (storeId, items) in groupedItems {
            let normalizedStoreId = storeId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedStoreId.isEmpty else {
                throw APIError.validationError("Cart item is missing store information.")
            }

            let totalPrice = items.reduce(0.0) { partialResult, item in
                partialResult + (item.price * Double(item.quantity))
            }

            let request = CheckoutOrderRequest(
                storeId: normalizedStoreId,
                totalPrice: totalPrice,
                shippingAddress: shippingAddress,
                items: items.map {
                    CheckoutOrderItemRequest(
                        productId: $0.productId,
                        price: $0.price,
                        quantity: $0.quantity
                    )
                },
                paymentMethod: paymentMethod,
                deliveryOption: deliveryOption
            )

            let response: APIResponse<CheckoutCreatedOrderResponse> = try await APIClient.shared.request(.createOrder, body: request)
            guard !response.data.id.isEmpty else {
                throw APIError.decodingError("Created order response did not include an id.")
            }
            createdOrderIds.append(response.data.id)
        }

        guard !createdOrderIds.isEmpty else {
            throw APIError.decodingError("No order ids were returned from checkout.")
        }

        return createdOrderIds
    }

    private static func makeFingerprint(
        cartItems: [CartItem],
        shippingAddress: String,
        paymentMethod: String,
        deliveryOption: String
    ) -> String {
        let itemFingerprint = cartItems
            .sorted { $0.id < $1.id }
            .map { "\($0.productId):\($0.quantity):\($0.price):\($0.storeId)" }
            .joined(separator: "|")

        return [itemFingerprint, shippingAddress, paymentMethod, deliveryOption].joined(separator: "||")
    }
}
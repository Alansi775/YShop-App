import SwiftUI

// UI-specific cart item for display purposes
struct UICartItem: Identifiable {
    let id: Int
    let name: String
    let price: Double
    var quantity: Int
    let image: String
}

struct CartView: View {
    @State private var cartItems: [UICartItem] = [
        UICartItem(id: 1, name: "Blue T-Shirt", price: 29.99, quantity: 1, image: "shirt1"),
        UICartItem(id: 2, name: "Black Jeans", price: 59.99, quantity: 1, image: "pants1"),
    ]
    
    var subtotal: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var tax: Double {
        subtotal * 0.1
    }
    
    var total: Double {
        subtotal + tax
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shopping Cart")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.label))
                    
                    Text("\(cartItems.count) items")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                
                Divider()
                
                if cartItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bag")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Text("Your Cart is Empty")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        Text("Add items to continue shopping")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(cartItems, id: \.id) { item in
                                CartItemRow(item: item)
                            }
                        }
                        .padding(16)
                    }
                    
                    VStack(spacing: 12) {
                        Divider()
                        
                        HStack {
                            Text("Subtotal")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", subtotal))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                        
                        HStack {
                            Text("Tax (10%)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", tax))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(.label))
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", total))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(.label))
                        }
                        
                        Button(action: {}) {
                            Text("Proceed to Checkout")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(.label))
                                .cornerRadius(12)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                }
            }
        }
    }
    
    struct CartItemRow: View {
        let item: UICartItem
        
        var body: some View {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(Color(.secondarySystemBackground))
                    .frame(width: 70, height: 70)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.label))
                    
                    Text(String(format: "$%.2f", item.price))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .frame(width: 24, height: 24)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(6)
                    }
                    
                    Text("\(item.quantity)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.label))
                    
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(.label))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

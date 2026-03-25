import SwiftUI

struct OrdersView: View {
    @State private var selectedTab = "Active"
    let tabs = ["Active", "Completed", "Cancelled"]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Orders")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                
                Divider()
                
                // Tab Menu
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        VStack(spacing: 8) {
                            Text(tab)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? Color(.label) : Color(.secondaryLabel))
                            
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 2)
                                    .frame(height: 3)
                                    .foregroundColor(Color(.label))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // Orders List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            OrderCard(orderNumber: "ORD-\(1000 + index)", date: "Mar 20, 2026", total: Double(50 + index * 20), status: selectedTab)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

struct OrderCard: View {
    let orderNumber: String
    let date: String
    let total: Double
    let status: String
    
    var statusColor: Color {
        switch status {
        case "Active":
            return .orange
        case "Completed":
            return .green
        case "Cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    var statusIcon: String {
        switch status {
        case "Active":
            return "clock.fill"
        case "Completed":
            return "checkmark.circle.fill"
        case "Cancelled":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(orderNumber)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(.label))
                    
                    Text(date)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(status)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor)
                .cornerRadius(6)
            }
            
            Divider()
            
            HStack {
                Text("3 items")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
                
                Spacer()
                
                Text(String(format: "$%.2f", total))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    OrdersView()
}

import SwiftUI

struct CustomerTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        HomeView()
                    case 1:
                        SearchView()
                    case 2:
                        CartView()
                    case 3:
                        OrdersView()
                    case 4:
                        ProfileView()
                    default:
                        HomeView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Tab Bar
                Divider()
                
                HStack(spacing: 0) {
                    TabBarItem(
                        icon: "house.fill",
                        label: "Home",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabBarItem(
                        icon: "magnifyingglass",
                        label: "Search",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabBarItem(
                        icon: "bag.fill",
                        label: "Cart",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabBarItem(
                        icon: "list.bullet.rectangle.fill",
                        label: "Orders",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                    
                    TabBarItem(
                        icon: "person.fill",
                        label: "Profile",
                        isSelected: selectedTab == 4,
                        action: { selectedTab = 4 }
                    )
                }
                .frame(height: 60)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
            }
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(isSelected ? Color(.label) : Color(.secondaryLabel))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
    }
}

#Preview {
    CustomerTabView()
        .environmentObject(AuthManager())
}

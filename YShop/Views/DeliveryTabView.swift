import SwiftUI

struct DeliveryTabView: View {
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
                        DeliveryHomeView()
                    case 1:
                        DeliveryJobsView()
                    case 2:
                        DeliveryEarningsView()
                    case 3:
                        DeliveryProfileView()
                    default:
                        DeliveryHomeView()
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
                        icon: "car.fill",
                        label: "Jobs",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabBarItem(
                        icon: "dollarsign.circle.fill",
                        label: "Earnings",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabBarItem(
                        icon: "person.fill",
                        label: "Profile",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                }
                .frame(height: 60)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
            }
        }
    }
}

struct DeliveryHomeView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back!")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                            
                            Text((authManager.currentUser?.name ?? "Driver").split(separator: " ").first.map(String.init) ?? "Driver")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(.label))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(.label))
                            .opacity(0.6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Stats Cards
                    VStack(spacing: 12) {
                        StatCard(icon: "mappin.and.ellipse", title: "Active Jobs", value: "2", color: .blue)
                        StatCard(icon: "checkmark.circle.fill", title: "Completed Today", value: "5", color: .green)
                        StatCard(icon: "dollarsign.circle.fill", title: "Today's Earnings", value: "$120", color: .orange)
                    }
                    .padding(.horizontal, 16)
                    
                    // Upcoming Deliveries
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Deliveries")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(.label))
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<2, id: \.self) { index in
                                DeliveryJobCard(index: index)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Color.clear
                        .frame(height: 20)
                }
                .padding(.vertical, 16)
            }
        }
    }
}

struct DeliveryJobsView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Available Jobs")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(.label))
                    .padding(.horizontal, 16)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { index in
                            DeliveryJobCard(index: index)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

struct DeliveryEarningsView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Earnings")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    // Total Earnings
                    VStack(spacing: 8) {
                        Text("Total This Week")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Text("$640")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(.label))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    
                    // Daily Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Breakdown")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(.label))
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 8) {
                            EarningsRow(day: "Monday", amount: 95)
                            EarningsRow(day: "Tuesday", amount: 110)
                            EarningsRow(day: "Wednesday", amount: 85)
                            EarningsRow(day: "Thursday", amount: 120)
                            EarningsRow(day: "Friday", amount: 130)
                            EarningsRow(day: "Saturday", amount: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Color.clear
                        .frame(height: 20)
                }
                .padding(.vertical, 16)
            }
        }
    }
}

struct DeliveryProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .foregroundColor(Color(.secondarySystemBackground))
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                        .frame(width: 80, height: 80)
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentUser?.name ?? "Driver")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(.label))
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(.secondarySystemBackground))
                    
                    VStack(spacing: 12) {
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "person.fill",
                                title: "Edit Profile",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.vertical, 0)
                            
                            ProfileMenuItem(
                                icon: "mappin.circle.fill",
                                title: "Work Zone",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.vertical, 0)
                            
                            ProfileMenuItem(
                                icon: "star.fill",
                                title: "Ratings",
                                action: {}
                            )
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "lock.fill",
                                title: "Change Password",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.vertical, 0)
                            
                            ProfileMenuItem(
                                icon: "gear",
                                title: "Settings",
                                action: {}
                            )
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Button(action: { showLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "arrowshape.turn.up.left.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Logout")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding(.top, 16)
                    }
                    .padding(16)
                }
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    authManager.logout()
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DeliveryJobCard: View {
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Delivery #\(1000 + index)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(.label))
                    
                    Text("2.5 km away")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Text("$12")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle")
                    .foregroundColor(Color(.secondaryLabel))
                
                Text("123 Main St, Downtown")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Accept")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Decline")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(.label))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct EarningsRow: View {
    let day: String
    let amount: Double
    
    var body: some View {
        HStack {
            Text(day)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.label))
            
            Spacer()
            
            Text(String(format: "$%.0f", amount))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(.label))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    DeliveryTabView()
        .environmentObject(AuthManager())
}

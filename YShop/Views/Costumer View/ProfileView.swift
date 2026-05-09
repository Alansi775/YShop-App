import SwiftUI

struct ProfileView: View {
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
                            Text(authManager.currentUser?.name ?? "User")
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
                        // Profile Menu Items
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
                                title: "Delivery Addresses",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.vertical, 0)
                            
                            ProfileMenuItem(
                                icon: "heart.fill",
                                title: "Wishlist",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.vertical, 0)
                            
                            ProfileMenuItem(
                                icon: "bell.fill",
                                title: "Notifications",
                                action: {}
                            )
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Settings Section
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
                            
                            Divider()
                                .padding(.vertical, 0)
                            
                            ProfileMenuItem(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                action: {}
                            )
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Logout Button
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

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .padding(.horizontal, 12)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @State private var showCustomerSignup = false
    @State private var showDriverSignup = false
    
    // YSHOP Brand Blue
    private var accentBlue: Color {
        Color(red: 0.0, green: 0.48, blue: 1.0)
    }
    
    var body: some View {
        ZStack {
            // Native iOS background - adapts to Dark/Light Mode
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 32)
                    
                    // Logo Section - مع Shimmer أزرق فخم
                    VStack(spacing: 12) {
                        Text("YSHOP")
                            .font(.system(size: 48, weight: .bold))
                            .tracking(6)
                            .foregroundColor(Color(.label))
                            .shimmer(color: Color(red: 0.4, green: 0.7, blue: 1.0), intensity: 0.70, duration: 10.0)
                        
                        Text("Everything Delivered")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .padding(.bottom, 56)
                    
                    // Form Section
                    VStack(spacing: 14) {
                        YShopTextField(
                            placeholder: "Email Address",
                            icon: "envelope.fill",
                            text: $viewModel.email,
                            keyboardType: .emailAddress
                        )
                        
                        YShopTextField(
                            placeholder: "Password",
                            icon: "lock.fill",
                            text: $viewModel.password,
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button(action: { HapticManager.shared.selection() }) {
                            HStack(spacing: 4) {
                                Text("Forgot Password?")
                                    .font(.system(size: 13, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(accentBlue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                    
                    // Buttons Section
                    VStack(spacing: 12) {
                        PrimaryButton(
                            title: "Enter Boutique",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.loginAsCustomer()
                            }
                        }
                        
                        SecondaryButton(
                            title: "Login as Driver",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.loginAsDriver()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    
                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color(.separator).opacity(0.5))
                            .frame(height: 0.5)
                        
                        Text("OR")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        Rectangle()
                            .fill(Color(.separator).opacity(0.5))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    
                    // Signup Options
                    VStack(spacing: 10) {
                        SignupOptionCard(
                            icon: "bag.fill",
                            title: "New to YSHOP?",
                            subtitle: "Create Customer Account",
                            accentColor: accentBlue
                        ) {
                            showCustomerSignup = true
                        }
                        
                        SignupOptionCard(
                            icon: "scooter",
                            title: "Become a Driver?",
                            subtitle: "Create Driver Account",
                            accentColor: accentBlue
                        ) {
                            showDriverSignup = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(minHeight: 40)
                    
                    // Footer
                    VStack(spacing: 4) {
                        Text("YSHOP © 2026")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        Text("Premium Shopping Experience")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(Color(.quaternaryLabel))
                    }
                    .padding(.bottom, 20)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .alert("Login Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showCustomerSignup) {
            CustomerSignupView()
        }
        .sheet(isPresented: $showDriverSignup) {
            DeliverySignupView()
        }
    }
}

// MARK: - Signup Option Card

private struct SignupOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.label))
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    LoginView()
}

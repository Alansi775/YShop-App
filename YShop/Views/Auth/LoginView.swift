import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @State private var showCustomerSignup = false
    @State private var showDriverSignup = false
    
    var body: some View {
        ZStack {
            // Native iOS background - adapts to Dark/Light Mode
            Color(.systemBackground)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 32)
                        
                        // Logo Section
                        VStack(spacing: 12) {
                            Text("YSHOP")
                                .font(.system(size: 48, weight: .bold))
                                .tracking(6)
                                .foregroundColor(Color(.label))
                            
                            Text("Fashion Delivered")
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
                        .padding(.bottom, 20)
                        
                        // Forgot Password Link
                        HStack {
                            Spacer()
                            Button(action: { HapticManager.shared.selection() }) {
                                HStack(spacing: 4) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(Color(.secondaryLabel))
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
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.secondaryLabel))
                            
                            Rectangle()
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        
                        // Signup Options
                        VStack(spacing: 10) {
                            Button(action: { showCustomerSignup = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("New to YSHOP?")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(.label))
                                        
                                        Text("Create Customer Account")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showDriverSignup = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Become a Driver?")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(.label))
                                        
                                        Text("Create Driver Account")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
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


#Preview {
    LoginView()
}

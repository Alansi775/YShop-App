import SwiftUI

struct DeliverySignupView: View {
    @State private var viewModel = DeliverySignupViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showSuccessAnimation = false
    @State private var formOpacity: Double = 0
    @State private var showMapPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BECOME A DRIVER")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(2)
                                .foregroundColor(Color(hex: "42A5F5"))
                            
                            Text("Join Our Fleet")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Color(.label))
                            
                            Text("Start earning as a delivery partner")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .opacity(formOpacity)
                        .padding(.bottom, 32)
                        
                        VStack(spacing: 12) {
                            // Personal Information
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Personal Information")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Color(.secondaryLabel))
                                
                                YShopTextField(
                                    placeholder: "Full Name",
                                    icon: "person",
                                    text: Binding(
                                        get: { viewModel.name },
                                        set: { viewModel.name = $0 }
                                    )
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                            
                            // Contact Information
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Contact Information")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Color(.secondaryLabel))
                                
                                YShopTextField(
                                    placeholder: "Email Address",
                                    icon: "envelope",
                                    text: Binding(
                                        get: { viewModel.email },
                                        set: { viewModel.email = $0 }
                                    ),
                                    keyboardType: .emailAddress
                                )
                                
                                YShopTextField(
                                    placeholder: "Phone Number",
                                    icon: "phone",
                                    text: Binding(
                                        get: { viewModel.phone },
                                        set: { viewModel.phone = $0 }
                                    ),
                                    keyboardType: .phonePad
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                            
                            // Verification
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Verification")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Color(.secondaryLabel))
                                
                                YShopTextField(
                                    placeholder: "National ID",
                                    icon: "doc.text",
                                    text: Binding(
                                        get: { viewModel.nationalId },
                                        set: { viewModel.nationalId = $0 }
                                    ),
                                    keyboardType: .numberPad
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                            
                            // Service Area
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Service Area")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Color(.secondaryLabel))
                                
                                Button(action: {
                                    showMapPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "42A5F5"))
                                            .frame(width: 28)
                                        
                                        Text(viewModel.selectedAddress.isEmpty ? "Select Service Area" : viewModel.selectedAddress)
                                            .font(.system(size: 16))
                                            .foregroundColor(viewModel.selectedAddress.isEmpty ? Color(.tertiaryLabel) : Color(.label))
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(.tertiaryLabel))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .frame(height: 52)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                            
                            // Security
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Create Password")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Color(.secondaryLabel))
                                
                                YShopTextField(
                                    placeholder: "Password",
                                    icon: "lock",
                                    text: Binding(
                                        get: { viewModel.password },
                                        set: { viewModel.password = $0 }
                                    ),
                                    isSecure: true
                                )
                                
                                YShopTextField(
                                    placeholder: "Confirm Password",
                                    icon: "lock.rotation",
                                    text: Binding(
                                        get: { viewModel.confirmPassword },
                                        set: { viewModel.confirmPassword = $0 }
                                    ),
                                    isSecure: true
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            
                            // Disclaimer
                            VStack(alignment: .leading, spacing: 12) {
                                Text("By requesting a driver account, you agree to our Terms of Service and will be verified by our team before activation.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(.secondaryLabel))
                                    .lineLimit(5)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            
                            // Submit Button
                            VStack(spacing: 12) {
                                PrimaryButton(
                                    title: "Request Driver Account",
                                    isLoading: viewModel.isLoading
                                ) {
                                    Task {
                                        await viewModel.signup()
                                    }
                                }
                                
                                Button(action: {
                                    HapticManager.shared.selection()
                                    dismiss()
                                }) {
                                    Text("Back to Login")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "42A5F5"))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
            .alert("Success", isPresented: Binding(
                get: { viewModel.signupSuccess },
                set: { viewModel.signupSuccess = $0 }
            )) {
                Button("Continue") {
                    HapticManager.shared.selection()
                    dismiss()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showMapPicker) {
                MapPickerView(
                    isPresented: $showMapPicker,
                    onConfirm: { lat, lng, address in
                        viewModel.selectedLatitude = lat
                        viewModel.selectedLongitude = lng
                        viewModel.selectedAddress = address
                    }
                )
                .presentationDetents([.large])
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.showError },
                set: { viewModel.showError = $0 }
            )) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    formOpacity = 1.0
                }
                if viewModel.signupSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSuccessAnimation = true
                    }
                }
            }
        }
    }
}

#Preview {
    DeliverySignupView()
}

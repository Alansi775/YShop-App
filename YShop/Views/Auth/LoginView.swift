import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @State private var showCustomerSignup = false
    @State private var showDriverSignup = false
    @State private var showCompleteProfile = false
    @State private var googleErrorMessage: String?
    @State private var showGoogleError = false
    @EnvironmentObject private var authManager: AuthManager
    // Only meaningful when this view is presented modally (guest add-to-cart
    // detour, or the profile sheet's "Sign In" CTA) — when it's the app's
    // root content instead, there's no active presentation to dismiss and
    // this call is a harmless no-op.
    @Environment(\.dismiss) private var dismiss
    
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
                    .padding(.bottom, 16)

                    GoogleSignInButton(isLoading: viewModel.isLoading) {
                        Task { await handleGoogleSignIn() }
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
        .fullScreenCover(isPresented: $showCompleteProfile, onDismiss: {
            // completeProfile() itself dismisses this cover on success; if the
            // user got here at all Google auth already succeeded, so either
            // way there's a valid session now — close the login screen too.
            dismiss()
        }) {
            CompleteProfileView()
        }
        .alert("Google Sign-In Failed", isPresented: $showGoogleError) {
            Button("OK") { showGoogleError = false }
        } message: {
            Text(googleErrorMessage ?? "Something went wrong.")
        }
        .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn && !showCompleteProfile { dismiss() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Same back-button convention as MyOrdersView/OrderTrackingView
            // — requires this view to sit inside a NavigationStack, which
            // every presenter (ProfileView, HomeView, ProductDetailView)
            // now wraps it in.
            ToolbarItem(placement: .topBarLeading) {
                NativeCircleIconButton(
                    systemName: "chevron.left",
                    action: { dismiss() },
                    iconColor: .primary,
                    size: 35.5,
                    iconSize: 14,
                    showBackground: false
                )
            }
        }
    }

    private func handleGoogleSignIn() async {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        do {
            let result = try await authManager.signInWithGoogle(presenting: rootVC)
            if result.needsProfileCompletion {
                showCompleteProfile = true
            }
            // Otherwise: authManager.isLoggedIn is now true, the onChange
            // above dismisses this screen.
        } catch {
            let nsError = error as NSError
            // GIDSignInError.canceled — user closed the picker, not a real error.
            if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 { return }
            googleErrorMessage = error.localizedDescription
            showGoogleError = true
        }
    }
}

// MARK: - Google Sign-In Button

// Same visual language as PrimaryButton/SecondaryButton (54pt tall, 14pt
// radius, tertiarySystemBackground fill, press-scale + haptic) so this
// reads as a native sibling of "Enter Boutique"/"Login as Driver" instead
// of an unstyled outlier bolted on underneath them.
private struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            action()
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(Color(.secondaryLabel))
                } else {
                    GoogleLogoMark()
                        .frame(width: 18, height: 18)
                    Text("Continue with Google")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.label))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.tertiaryLabel), lineWidth: 1.5)
            )
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isLoading ? 0.7 : 1.0)
        .onLongPressGesture(minimumDuration: 0.01, perform: {}, onPressingChanged: { isPressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = isPressing
                if isPressing { HapticManager.shared.impact(style: .light) }
            }
        })
    }
}

private struct GoogleLogoMark: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let lineWidth = size.width * 0.22
            let radius = (size.width - lineWidth) / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)

            func arc(_ color: Color, _ startDeg: Double, _ sweepDeg: Double) {
                var path = Path()
                path.addArc(center: center, radius: radius,
                            startAngle: .degrees(startDeg), endAngle: .degrees(startDeg + sweepDeg),
                            clockwise: false)
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            }

            arc(Color(red: 0.259, green: 0.522, blue: 0.957), -45, 95)   // blue
            arc(Color(red: 0.204, green: 0.659, blue: 0.325), 55, 80)    // green
            arc(Color(red: 0.984, green: 0.737, blue: 0.020), 135, 80)   // yellow
            arc(Color(red: 0.918, green: 0.263, blue: 0.208), 215, 90)   // red

            var bar = Path()
            bar.addRect(CGRect(x: center.x, y: center.y - lineWidth * 0.28, width: radius * 0.95, height: lineWidth * 0.56))
            context.fill(bar, with: .color(Color(red: 0.259, green: 0.522, blue: 0.957)))
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

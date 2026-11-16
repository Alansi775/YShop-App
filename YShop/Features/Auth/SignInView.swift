import AuthenticationServices
import GoogleSignIn
import SwiftUI

/// The way in. Apple first (it's an iPhone), then Google, then e-mail.
/// Every path ends in one tap where possible: Apple and Google open an
/// account on the spot, no extra form. A guest can close this and browse.
struct SignInView: View {
    var onClose: (() -> Void)?

    @Environment(SessionStore.self) private var session
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var phase: PrimaryActionButton.Phase = .idle
    @State private var error: String?
    @State private var attempts = 0
    @State private var appeared = false
    @State private var appleBusy = false
    @State private var googleBusy = false
    @State private var creatingAccount = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool { email.trimmed.contains("@") && !password.isEmpty }
    private var busy: Bool { appleBusy || googleBusy || phase != .idle }

    var body: some View {
        NavigationStack {
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $creatingAccount) {
                    CreateAccountView(prefilledEmail: email.trimmed)
                }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandWordmark(size: 46)
                    .padding(.top, 56)
                    .appear(0, appeared)

                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.largeTitle.bold())
                    Text("Sign in to order, track and reorder.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 28)
                .appear(1, appeared)

                VStack(spacing: 12) {
                    appleButton
                    googleButton
                }
                .padding(.top, 36)
                .appear(2, appeared)

                OrDivider()
                    .padding(.vertical, 24)
                    .appear(3, appeared)

                FormCard {
                    FieldRow(icon: "envelope", title: "E-mail", text: $email,
                             keyboard: .emailAddress, content: .username, isInvalid: error != nil)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                    FormDivider()
                    FieldRow(icon: "lock", title: "Password", text: $password, secure: true,
                             content: .password, isInvalid: error != nil)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(submit)
                }
                .shake(attempts)
                .appear(4, appeared)

                if let error {
                    InlineError(message: error)
                        .padding(.top, 12)
                        .padding(.horizontal, 6)
                }

                Button("Create an account") { creatingAccount = true }
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 22)
                    .disabled(busy)
                    .appear(5, appeared)

                Text("By continuing you agree to YShop's Terms and Privacy Policy.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                    .appear(6, appeared)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .animation(.spring(duration: 0.45, bounce: 0.25), value: error)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .background { BrandBackground() }
        .safeAreaInset(edge: .bottom) {
            PrimaryActionButton(title: "Sign in", phase: phase, isEnabled: canSubmit && !appleBusy && !googleBusy, action: submit)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .overlay(alignment: .topTrailing) {
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.body.weight(.semibold)).frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Browse without signing in")
                .padding(.trailing, 20)
                .padding(.top, 8)
            }
        }
        .sensoryFeedback(.error, trigger: attempts)
        .sensoryFeedback(trigger: phase) { _, new in new == .success ? .success : nil }
        .onAppear { appeared = true }
        .onChange(of: email) { error = nil }
        .onChange(of: password) { error = nil }
    }

    // MARK: Buttons

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            apple(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        // Apple's button keeps the style it was born with — rebuild it on a theme change.
        .id(colorScheme)
        .frame(height: 50)
        .clipShape(.capsule)
        .overlay { if appleBusy { ProgressView().tint(colorScheme == .dark ? .black : .white) } }
        .opacity(busy ? 0.5 : 1)
        .disabled(busy)
    }

    private var googleButton: some View {
        Button(action: google) {
            HStack(spacing: 10) {
                if googleBusy { ProgressView() } else { GoogleMark().frame(width: 18, height: 18) }
                Text("Continue with Google")
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 26)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .disabled(busy)
    }

    // MARK: Actions

    private func submit() {
        guard canSubmit, phase == .idle else { return }
        focus = nil
        error = nil
        phase = .loading
        Task {
            do {
                try await session.login(email: email.trimmed, password: password)
                phase = .success
            } catch {
                phase = .idle
                fail(error)
            }
        }
    }

    private func apple(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
            if case .failure(let e) = result, (e as? ASAuthorizationError)?.code != .canceled {
                fail(API.Failure(status: 0, code: "APPLE", message: "Couldn't continue with Apple. Try again."))
            }
            return
        }
        appleBusy = true
        Task {
            defer { appleBusy = false }
            do {
                try await session.signInWithApple(identityToken: token,
                                                  firstName: credential.fullName?.givenName,
                                                  lastName: credential.fullName?.familyName)
            } catch {
                fail(error)
            }
        }
    }

    private func google() {
        guard let presenter = UIApplication.shared.topViewController else { return }
        googleBusy = true
        Task {
            defer { googleBusy = false }
            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
                guard let idToken = result.user.idToken?.tokenString else { return }
                try await session.signInWithGoogle(idToken: idToken)
            } catch let e as GIDSignInError where e.code == .canceled {
                return
            } catch {
                fail(error)
            }
        }
    }

    private func fail(_ error: Error) {
        self.error = (error as? API.Failure)?.message ?? "Something went wrong. Try again."
        attempts += 1
    }
}

/// Google's four-colour "G", drawn so it needs no image asset.
struct GoogleMark: View {
    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let w = r * 0.38
            func arc(_ from: Double, _ to: Double, _ color: Color) {
                var p = Path()
                p.addArc(center: c, radius: r - w / 2, startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w))
            }
            arc(-40, 45, Color(red: 0.26, green: 0.52, blue: 0.96))
            arc(45, 135, Color(red: 0.20, green: 0.66, blue: 0.33))
            arc(135, 200, Color(red: 0.98, green: 0.74, blue: 0.02))
            arc(200, 320, Color(red: 0.92, green: 0.26, blue: 0.21))
            ctx.fill(Path(CGRect(x: c.x, y: c.y - w / 2, width: r, height: w)),
                     with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))
        }
    }
}

extension UIApplication {
    /// The view controller on top — Google's sheet must be presented from it.
    var topViewController: UIViewController? {
        let scene = connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

#Preview {
    SignInView(onClose: {})
        .environment(SessionStore.shared)
}

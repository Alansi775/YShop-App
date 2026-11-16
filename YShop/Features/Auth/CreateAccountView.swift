import SwiftUI

/// E-mail sign-up in one short sheet: name, e-mail, password. The server
/// signs the person in straight away — no "now go sign in" step.
struct CreateAccountView: View {
    var prefilledEmail = ""

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phase: PrimaryActionButton.Phase = .idle
    @State private var error: String?
    @State private var attempts = 0
    @FocusState private var focus: Field?

    private enum Field { case first, last, email, password }

    private var canSubmit: Bool {
        !firstName.trimmed.isEmpty && !lastName.trimmed.isEmpty && email.trimmed.contains("@") && password.count >= 8
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your name and an e-mail — that's all it takes.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    FormCard {
                        FieldRow(icon: "person", title: "First name", text: $firstName, content: .givenName)
                            .focused($focus, equals: .first)
                            .submitLabel(.next)
                            .onSubmit { focus = .last }
                        FormDivider()
                        FieldRow(icon: "person", title: "Last name", text: $lastName, content: .familyName)
                            .focused($focus, equals: .last)
                            .submitLabel(.next)
                            .onSubmit { focus = .email }
                    }

                    FormCard {
                        FieldRow(icon: "envelope", title: "E-mail", text: $email, keyboard: .emailAddress,
                                 content: .username, isInvalid: error != nil)
                            .focused($focus, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focus = .password }
                        FormDivider()
                        FieldRow(icon: "lock", title: "Password", text: $password, secure: true, content: .newPassword)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(submit)
                    }
                    .shake(attempts)

                    PasswordHint(password: password)

                    if let error { InlineError(message: error) }
                }
                .padding(24)
                .animation(.spring(duration: 0.4, bounce: 0.25), value: error)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryActionButton(title: "Create account", phase: phase, isEnabled: canSubmit, action: submit)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
        .sensoryFeedback(.error, trigger: attempts)
        .onAppear {
            email = prefilledEmail
            focus = .first
        }
        .onChange(of: email) { error = nil }
    }

    private func submit() {
        guard canSubmit, phase == .idle else { return }
        focus = nil
        phase = .loading
        Task {
            do {
                try await session.register(.init(email: email.trimmed, password: password,
                                                 firstName: firstName.trimmed, lastName: lastName.trimmed, phone: nil))
                phase = .success
                try? await Task.sleep(for: .milliseconds(600))
                dismiss()
            } catch {
                phase = .idle
                self.error = (error as? API.Failure)?.message ?? "Something went wrong. Try again."
                attempts += 1
            }
        }
    }
}

/// A live check under the password, so nobody learns the rule from an error.
private struct PasswordHint: View {
    let password: String

    var body: some View {
        let ok = password.count >= 8
        Label("At least 8 characters", systemImage: ok ? "checkmark.circle.fill" : "circle")
            .font(.footnote.weight(.medium))
            .foregroundStyle(ok ? .green : .secondary)
            .contentTransition(.symbolEffect(.replace))
            .animation(.smooth, value: ok)
            .padding(.horizontal, 6)
    }
}

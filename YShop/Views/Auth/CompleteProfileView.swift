// CompleteProfileView.swift
//
// Shown right after a first-time Google sign-in. This is a hard gate, not
// a skippable nag — the session already has a valid token at this point
// (Google sign-in itself succeeded), but the account isn't considered
// fully set up until these fields (the same ones the email/password
// signup form collects) are submitted. No back/dismiss gesture.
import SwiftUI

struct CompleteProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var surname: String = ""
    @State private var nationalId: String = ""
    @State private var phone: String = ""
    @State private var buildingName: String = ""
    @State private var apartmentNumber: String = ""
    @State private var deliveryInstructions: String = ""

    @State private var selectedAddress: String = ""
    @State private var selectedLatitude: Double = 0.0
    @State private var selectedLongitude: Double = 0.0
    @State private var showMapPicker = false

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // True when completing a first-time Google sign-up (no account/session
    // exists yet — submit() calls authManager.completeGoogleSignup, which
    // creates the account). False for an already-authenticated account
    // that's just missing required fields (submit() uses the normal
    // PUT /users/profile path via authManager.completeProfile).
    private var isPendingGoogleSignup: Bool { authManager.pendingGoogleProfile != nil }
    private var nameLocked: Bool { !(authManager.pendingGoogleProfile?.givenName ?? "").isEmpty }
    private var surnameLocked: Bool { !(authManager.pendingGoogleProfile?.familyName ?? "").isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("One last step")
                            .font(.system(size: 26, weight: .bold))
                        Text("We need a few more details before your account is ready.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    if isPendingGoogleSignup {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Signing up as \(authManager.pendingGoogleProfile?.email ?? "")")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    YShopTextField(placeholder: nameLocked ? "First Name (from Google)" : "First Name", icon: nameLocked ? "lock.fill" : "person.fill", text: $firstName)
                        .disabled(nameLocked)
                        .opacity(nameLocked ? 0.65 : 1.0)
                    YShopTextField(placeholder: surnameLocked ? "Surname (from Google)" : "Surname", icon: surnameLocked ? "lock.fill" : "person.fill", text: $surname)
                        .disabled(surnameLocked)
                        .opacity(surnameLocked ? 0.65 : 1.0)
                    YShopTextField(placeholder: "National ID / Residency", icon: "person.text.rectangle.fill", text: $nationalId, keyboardType: .numberPad)
                    YShopTextField(placeholder: "Phone Number", icon: "phone.fill", text: $phone, keyboardType: .phonePad)

                    Button(action: { showMapPicker = true }) {
                        YShopTextField(
                            placeholder: "Address (tap to pick on map)",
                            icon: "mappin.and.ellipse",
                            text: .constant(selectedAddress)
                        )
                        .allowsHitTesting(false)
                    }

                    YShopTextField(placeholder: "Building Name (Number)", icon: "building.2.fill", text: $buildingName)
                    YShopTextField(placeholder: "Apartment Number", icon: "number", text: $apartmentNumber)
                    YShopTextField(placeholder: "Delivery Instructions", icon: "note.text", text: $deliveryInstructions)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }

                    PrimaryButton(title: "Continue", isLoading: isSubmitting) {
                        Task { await submit() }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            if let pending = authManager.pendingGoogleProfile {
                if let given = pending.givenName, !given.isEmpty { firstName = given }
                if let family = pending.familyName, !family.isEmpty { surname = family }
            }
        }
        .sheet(isPresented: $showMapPicker) {
            MapPickerView(
                isPresented: $showMapPicker,
                onConfirm: { lat, lng, address in
                    selectedLatitude = lat
                    selectedLongitude = lng
                    selectedAddress = address
                }
            )
            .presentationDetents([.large])
        }
    }

    private func submit() async {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedSurname = surname.trimmingCharacters(in: .whitespaces)
        let trimmedNationalId = nationalId.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)

        guard !trimmedFirst.isEmpty, !trimmedSurname.isEmpty, !trimmedNationalId.isEmpty, !trimmedPhone.isEmpty, !selectedAddress.isEmpty else {
            errorMessage = "Please fill in all required fields before continuing."
            return
        }

        isSubmitting = true
        errorMessage = nil
        do {
            if isPendingGoogleSignup {
                // Creates the account and a real session together — nothing
                // was written to the database until this call succeeds.
                try await authManager.completeGoogleSignup(
                    phone: trimmedPhone,
                    nationalId: trimmedNationalId,
                    address: selectedAddress,
                    latitude: selectedLatitude != 0.0 ? selectedLatitude : nil,
                    longitude: selectedLongitude != 0.0 ? selectedLongitude : nil,
                    buildingInfo: buildingName,
                    apartmentNumber: apartmentNumber,
                    deliveryInstructions: deliveryInstructions,
                    firstName: trimmedFirst,
                    surname: trimmedSurname
                )
            } else {
                try await authManager.completeProfile(
                    displayName: "\(trimmedFirst) \(trimmedSurname)",
                    surname: trimmedSurname,
                    phone: trimmedPhone,
                    nationalId: trimmedNationalId,
                    address: selectedAddress,
                    latitude: selectedLatitude != 0.0 ? selectedLatitude : nil,
                    longitude: selectedLongitude != 0.0 ? selectedLongitude : nil,
                    buildingInfo: buildingName,
                    apartmentNumber: apartmentNumber,
                    deliveryInstructions: deliveryInstructions
                )
            }
            isSubmitting = false
            dismiss()
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}

import Foundation
import Observation

@Observable
final class CustomerSignupViewModel {
    var firstName: String = ""
    var surname: String = ""
    var nationalId: String = ""
    var phone: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    
    var buildingName: String = ""
    var apartmentNumber: String = ""
    var deliveryInstructions: String = ""
    
    var selectedLatitude: Double = 0.0
    var selectedLongitude: Double = 0.0
    var selectedAddress: String = ""
    
    var isLoading: Bool = false
    var errorMessage: String = ""
    var showError: Bool = false
    var showMapPicker: Bool = false
    var signupSuccess: Bool = false
    
    func signup() async {
        guard validateInputs() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Combine first and last name
            let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(surname.trimmingCharacters(in: .whitespaces))".trimmingCharacters(in: .whitespaces)
            
            let response = try await AuthService.signup(
                displayName: fullName,
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                phone: phone.trimmingCharacters(in: .whitespaces),
                nationalId: nationalId.trimmingCharacters(in: .whitespaces).isEmpty ? nil : nationalId,
                address: selectedAddress.isEmpty ? nil : selectedAddress,
                latitude: selectedLatitude > 0 ? selectedLatitude : nil,
                longitude: selectedLongitude > 0 ? selectedLongitude : nil,
                buildingInfo: buildingName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : buildingName,
                apartmentNumber: apartmentNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : apartmentNumber,
                deliveryInstructions: deliveryInstructions.trimmingCharacters(in: .whitespaces).isEmpty ? nil : deliveryInstructions
            )
            
            // Signup successful - user needs to verify email
            await MainActor.run {
                errorMessage = response.message
                signupSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func validateInputs() -> Bool {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedSurname = surname.trimmingCharacters(in: .whitespaces)
        let trimmedNationalId = nationalId.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespaces)
        
        if trimmedFirstName.isEmpty {
            errorMessage = "First name is required."
            showError = true
            return false
        }
        
        if trimmedSurname.isEmpty {
            errorMessage = "Surname is required."
            showError = true
            return false
        }
        
        if trimmedNationalId.isEmpty {
            errorMessage = "National ID is required."
            showError = true
            return false
        }
        
        if trimmedPhone.isEmpty {
            errorMessage = "Phone number is required."
            showError = true
            return false
        }
        
        if trimmedEmail.isEmpty {
            errorMessage = "Email address is required."
            showError = true
            return false
        }
        
        if !isValidEmail(trimmedEmail) {
            errorMessage = "Please enter a valid email address."
            showError = true
            return false
        }
        
        if trimmedPassword.isEmpty {
            errorMessage = "Password is required."
            showError = true
            return false
        }
        
        if trimmedPassword.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            showError = true
            return false
        }
        
        if trimmedPassword != trimmedConfirm {
            errorMessage = "Passwords do not match."
            showError = true
            return false
        }
        
        if selectedLatitude == 0.0 || selectedLongitude == 0.0 {
            errorMessage = "Please select a delivery location."
            showError = true
            return false
        }
        
        if selectedAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Address could not be determined. Please try again."
            showError = true
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func setLocation(latitude: Double, longitude: Double, address: String) {
        self.selectedLatitude = latitude
        self.selectedLongitude = longitude
        self.selectedAddress = address
    }
    
    func reset() {
        firstName = ""
        surname = ""
        nationalId = ""
        phone = ""
        email = ""
        password = ""
        confirmPassword = ""
        buildingName = ""
        apartmentNumber = ""
        deliveryInstructions = ""
        selectedLatitude = 0.0
        selectedLongitude = 0.0
        selectedAddress = ""
        errorMessage = ""
        showError = false
        signupSuccess = false
    }
}

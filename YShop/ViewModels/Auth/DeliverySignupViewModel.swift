import Foundation
import Observation

@Observable
final class DeliverySignupViewModel {
    var name: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var phone: String = ""
    var nationalId: String = ""
    var vehicleType: String = "motorcycle"
    
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
            let response = try await AuthService.deliverySignup(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                phone: phone.trimmingCharacters(in: .whitespaces)
            )
            
            // Application submitted - pending admin approval & email verification
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
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedNationalId = nationalId.trimmingCharacters(in: .whitespaces)
        
        if trimmedName.isEmpty {
            errorMessage = "Name is required."
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
        
        if trimmedPhone.isEmpty {
            errorMessage = "Phone number is required."
            showError = true
            return false
        }
        
        if trimmedNationalId.isEmpty {
            errorMessage = "National ID is required."
            showError = true
            return false
        }
        
        if selectedLatitude == 0.0 || selectedLongitude == 0.0 {
            errorMessage = "Please select your location."
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
        name = ""
        email = ""
        password = ""
        confirmPassword = ""
        phone = ""
        nationalId = ""
        selectedLatitude = 0.0
        selectedLongitude = 0.0
        selectedAddress = ""
        errorMessage = ""
        showError = false
        signupSuccess = false
    }
}

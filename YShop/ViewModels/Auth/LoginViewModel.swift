import Foundation
import Observation

@Observable
final class LoginViewModel {
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String = ""
    var showError: Bool = false
    var isPasswordVisible: Bool = false
    
    func loginAsCustomer() async {
        guard validateInputs() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        print("🔐 [LOGIN] Attempting customer login with email: \(trimmedEmail)")
        print("📍 [LOGIN] API Base URL: \(AppConstants.baseURL)")
        
        do {
            let response = try await AuthService.login(
                email: trimmedEmail,
                password: password
            )
            
            print("✅ [LOGIN] Success! Token received: \(response.token.prefix(20))...")
            
            // Store token and update auth state on main thread
            await MainActor.run {
                AuthManager.shared.token = response.token
                AuthManager.shared.currentUser = response.user
                // Determine role from API response
                AuthManager.shared.userRole = response.user.role == "driver" ? .driver : .customer
                AuthManager.shared.isLoggedIn = true
                UserDefaults.standard.set(response.user.role, forKey: "userRole")
                print("🎯 [LOGIN] Auth state updated for customer: \(response.user.email)")
            }
        } catch {
            print("❌ [LOGIN] Customer login failed: \(error.localizedDescription)")
            // Try to parse backend error response
            let parsedError = parseErrorMessage(error)
            errorMessage = parsedError
            showError = true
        }
    }
    
    func loginAsDriver() async {
        guard validateInputs() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        print("🚗 [DRIVER LOGIN] Attempting driver login with email: \(trimmedEmail)")
        print("📍 [DRIVER LOGIN] API Base URL: \(AppConstants.baseURL)")
        
        do {
            let response = try await AuthService.deliveryLogin(
                email: trimmedEmail,
                password: password
            )
            
            print("✅ [DRIVER LOGIN] Success! Token received: \(response.token.prefix(20))...")
            
            // Store token and update auth state on main thread
            await MainActor.run {
                AuthManager.shared.token = response.token
                AuthManager.shared.currentUser = response.user
                // Determine role from API response
                AuthManager.shared.userRole = response.user.role == "driver" ? .driver : .customer
                AuthManager.shared.isLoggedIn = true
                UserDefaults.standard.set(response.user.role, forKey: "userRole")
                print("🎯 [DRIVER LOGIN] Auth state updated for driver: \(response.user.email)")
            }
        } catch {
            print("❌ [DRIVER LOGIN] Driver login failed: \(error.localizedDescription)")
            // Try to parse backend error response
            let parsedError = parseErrorMessage(error)
            errorMessage = parsedError
            showError = true
        }
    }
    
    private func parseErrorMessage(_ error: Error) -> String {
        // Check if it's an APIError with more details
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let message):
                return message
            case .validationError(let message):
                // This includes email verification messages from backend
                return message
            case .decodingError(let message):
                return message.contains("Unknown error") ? "Unable to process response from server. Please try again." : message
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .unauthorized:
                return "Invalid email or password."
            case .forbidden:
                return "Access denied. Please try again."
            case .notFound:
                return "User not found. Please check your email."
            case .invalidRequest:
                return "Invalid request. Please check your information."
            case .timeout:
                return "Request timed out. Please try again."
            case .unknown(let message):
                return message.isEmpty ? "An unexpected error occurred. Please try again." : message
            }
        }
        
        // Fallback to generic error message
        let errorDescription = error.localizedDescription
        return errorDescription.isEmpty ? "An error occurred. Please try again." : errorDescription
    }
    
    private func validateInputs() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
        
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
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func reset() {
        email = ""
        password = ""
        errorMessage = ""
        showError = false
        isPasswordVisible = false
    }
}

import Foundation

struct AuthValidator {
    
    // Requirements:
    // - Full Name: minimum 2 characters, no whitespace-only input
    static func validateName(_ name: String?) -> String? {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return "Name is required"
        }
        if name.count < 2 {
            return "Name must be at least 2 characters"
        }
        return nil
    }
    
    // - Email: standard email format validation
    static func validateEmail(_ email: String?) -> String? {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            return "Email is required"
        }
        
        // Simple but effective regex for basic email validation
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if !emailPred.evaluate(with: email) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    // - Password: minimum 8 characters, must contain uppercase, lowercase, and number
    static func validatePassword(_ password: String?) -> String? {
        guard let password = password, !password.isEmpty else {
            return "Password is required"
        }
        
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        
        let hasUpperCase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        if !hasUpperCase {
            return "Password must contain an uppercase letter"
        }
        
        let hasLowerCase = password.range(of: "[a-z]", options: .regularExpression) != nil
        if !hasLowerCase {
            return "Password must contain a lowercase letter"
        }
        
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        if !hasNumber {
            return "Password must contain a number"
        }
        
        return nil
    }
}

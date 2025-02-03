import Foundation

struct User: Codable {
    let id: UUID
    let email: String
    let fullName: String
    let age: Int
    let monthlyIncome: Double
}

struct UserRegistration {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var fullName: String = ""
    var age: Int = 0
    var monthlyIncome: Double = 0.0
    var acceptedTerms: Bool = false
    
    var isValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        !fullName.isEmpty &&
        age >= 18 &&
        monthlyIncome >= 0 &&
        acceptedTerms
    }
} 
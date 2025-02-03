import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var registration = RegistrationViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Registration Form
                    VStack(spacing: 16) {
                        // Email
                        FormField(title: "Email",
                                text: $registration.email,
                                placeholder: "Enter your email",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress)
                        
                        // Password
                        SecureFormField(title: "Password",
                                      text: $registration.password,
                                      placeholder: "Create a password")
                        
                        // Confirm Password
                        SecureFormField(title: "Confirm Password",
                                      text: $registration.confirmPassword,
                                      placeholder: "Confirm your password")
                        
                        // Full Name
                        FormField(title: "Full Name",
                                text: $registration.fullName,
                                placeholder: "Enter your full name",
                                textContentType: .name)
                        
                        // Age
                        FormField(title: "Age",
                                text: Binding(
                                    get: { String(registration.age) },
                                    set: { registration.age = Int($0) ?? 0 }
                                ),
                                placeholder: "Enter your age",
                                keyboardType: .numberPad)
                        
                        // Monthly Income
                        FormField(title: "Monthly Income",
                                text: Binding(
                                    get: { String(format: "%.2f", registration.monthlyIncome) },
                                    set: { registration.monthlyIncome = Double($0) ?? 0 }
                                ),
                                placeholder: "Enter your monthly income",
                                keyboardType: .decimalPad)
                        
                        // Terms and Conditions
                        Toggle(isOn: $registration.acceptedTerms) {
                            Text("I accept the Terms and Conditions")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Register Button
                    Button(action: {
                        authManager.register(user: registration.userRegistration)
                        dismiss()
                    }) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(registration.isValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!registration.isValid)
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class RegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var age = 0
    @Published var monthlyIncome = 0.0
    @Published var acceptedTerms = false
    
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
    
    var userRegistration: UserRegistration {
        UserRegistration(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            fullName: fullName,
            age: age,
            monthlyIncome: monthlyIncome,
            acceptedTerms: acceptedTerms
        )
    }
} 
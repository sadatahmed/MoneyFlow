import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and Welcome Text
                        VStack(spacing: 12) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            
                            Text("Welcome to MoneyFlow")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Login to manage your finances")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // Login Form
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                            }
                            
                            // Forgot Password
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        
                        // Login Button
                        Button(action: {
                            authManager.login(email: email, password: password)
                        }) {
                            Text("Login")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Register Button
                        Button(action: {
                            showingRegistration = true
                        }) {
                            Text("Don't have an account? Register")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .alert("Error", isPresented: $authManager.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authManager.authError?.localizedDescription ?? "An error occurred")
            }
            .sheet(isPresented: $showingRegistration) {
                RegistrationView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                //ForgotPasswordView()
            }
        }
    }
} 

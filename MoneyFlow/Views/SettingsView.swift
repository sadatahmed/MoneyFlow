import SwiftUI

struct SettingsView: View {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    NavigationLink("Profile Settings") {
                        Text("Profile Settings")
                    }
                    NavigationLink("Notification Preferences") {
                        Text("Notification Settings")
                    }
                }
                
                Section("Data") {
                    NavigationLink("Export Data") {
                        Text("Export Data")
                    }
                    Button("Reset App", role: .destructive) {
                        showingResetAlert = true
                    }
                }
                
                Section("About") {
                    NavigationLink("Help & Support") {
                        Text("Help & Support")
                    }
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy")
                    }
                    NavigationLink("Terms of Service") {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset App", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("Are you sure you want to reset the app? This will delete all your data.")
            }
        }
    }
    
    private func resetApp() {
        // Implement reset logic
        isFirstLaunch = true
    }
} 
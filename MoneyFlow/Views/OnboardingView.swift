import SwiftUI

struct OnboardingView: View {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    
    var body: some View {
        TabView {
            OnboardingPage(
                title: "Track Your Money",
                description: "Keep track of your income and expenses with ease",
                imageName: "dollarsign.circle.fill"
            )
            
            OnboardingPage(
                title: "Set Budgets",
                description: "Create budgets and get notifications when you're close to limits",
                imageName: "chart.bar.fill"
            )
            
            OnboardingPage(
                title: "Analyze Spending",
                description: "View detailed reports and insights about your spending habits",
                imageName: "chart.pie.fill"
            )
            
            FinalOnboardingPage(isFirstLaunch: $isFirstLaunch)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct OnboardingPage: View {
    let title: String
    let description: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.title)
                .bold()
            
            Text(description)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct FinalOnboardingPage: View {
    @Binding var isFirstLaunch: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ready to Start?")
                .font(.title)
                .bold()
            
            Button("Get Started") {
                isFirstLaunch = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
} 
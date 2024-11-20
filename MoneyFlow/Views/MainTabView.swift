import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.bar.fill")
                }
            
            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
} 

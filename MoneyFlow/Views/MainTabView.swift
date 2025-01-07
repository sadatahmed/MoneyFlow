import SwiftUI

struct MainTabView: View {
    @State private var showingAddTransaction = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            TransactionsView(showingAddTransaction: $showingAddTransaction)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(2)
                .overlay {
                    // Add a plus button overlay when on the Transactions tab
                    if selectedTab == 2 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    showingAddTransaction = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.blue)
                                        .background(Color(.systemBackground))
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 64)
                            }
                        }
                    }
                }
            
            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
    }
} 

import SwiftUI
import CoreData

struct AccountsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var showingAddAccount = false
    @State private var showingTransfer = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(accounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        AccountRow(account: account)
                    }
                }
                .onDelete(perform: deleteAccounts)
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddAccount = true }) {
                            Label("Add Account", systemImage: "plus")
                        }
                        
                        Button(action: { showingTransfer = true }) {
                            Label("Transfer Money", systemImage: "arrow.left.arrow.right")
                        }
                        .disabled(accounts.count < 2)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingTransfer) {
                AddTransferView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .refreshable {
                try? viewContext.save()
            }
        }
    }
    
    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            offsets.map { accounts[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct AccountRow: View {
    @ObservedObject var account: Account
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(getAccountTypeColor())
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: getAccountTypeIcon())
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name ?? "Unnamed Account")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(account.type?.capitalized ?? "Unknown Type")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("$\(account.balance, specifier: "%.2f")")
                .bold()
                .foregroundStyle(account.balance >= 0 ? .primary : Color.red)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func getAccountTypeColor() -> Color {
        switch account.type {
        case "checking": return .blue
        case "savings": return .green
        case "credit": return .red
        case "cash": return .orange
        case "investment": return .purple
        default: return .gray
        }
    }
    
    private func getAccountTypeIcon() -> String {
        switch account.type {
        case "checking": return "dollarsign.circle.fill"
        case "savings": return "banknote.fill"
        case "credit": return "creditcard.fill"
        case "cash": return "money.bill.fill"
        case "investment": return "chart.line.uptrend.xyaxis.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
} 
import SwiftUI
import CoreData

struct AccountDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var account: Account
    @State private var showingEditSheet = false
    @State private var searchText = ""
    @State private var selectedFilter = "all"
    
    private let filterOptions = ["all", "income", "expense", "transfer"]
    
    var body: some View {
        VStack {
            // Account Summary
            AccountSummaryView(account: account)
                .padding(.horizontal)
                .padding(.top)
            
            // Filter Pills
            FilterPillsView(
                options: filterOptions,
                selectedFilter: $selectedFilter
            )
            .padding(.vertical, 8)
            
            // Transactions List
            TransactionsListView(
                transactions: groupedTransactions,
                searchText: searchText
            )
        }
        .navigationTitle(account.name ?? "Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search transactions")
        .sheet(isPresented: $showingEditSheet) {
            EditAccountView(account: account)
        }
    }
    
    // Filter and group transactions
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        
        // Apply search and filter logic
        let filteredTransactions = account.transactions?.allObjects as? [Transaction] ?? []
        let filteredBySearch = filteredTransactions.filter {
            guard !searchText.isEmpty else { return true }
            return ($0.category?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        let filteredByType = filteredBySearch.filter {
            switch selectedFilter {
            case "income": return $0.amount > 0
            case "expense": return $0.amount < 0
            case "transfer": return $0.type == "transfer"
            default: return true
            }
        }
        
        // Group by date
        let grouped = Dictionary(grouping: filteredByType) {
            calendar.startOfDay(for: $0.date ?? Date())
        }
        
        return grouped.map { (date: $0.key, transactions: $0.value.sorted(by: { $0.date ?? Date() > $1.date ?? Date() })) }
            .sorted { $0.date > $1.date }
    }
}

struct AccountSummaryView: View {
    let account: Account
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(getAccountTypeColor())
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: getAccountTypeIcon())
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.type?.capitalized ?? "Unknown Type")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("$\(account.balance, specifier: "%.2f")")
                    .font(.title)
                    .bold()
                    .foregroundStyle(account.balance >= 0 ? .primary : Color.red)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
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

struct FilterPillsView: View {
    let options: [String]
    @Binding var selectedFilter: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Text(filter.capitalized)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct TransactionsListView: View {
    let transactions: [(date: Date, transactions: [Transaction])]
    let searchText: String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(transactions, id: \.date) { group in
                    Section(header: TransactionDateHeader(date: group.date)) {
                        VStack(spacing: 0) {
                            ForEach(group.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal)
                                
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

//// Example Placeholder for Date Header
//struct TransactionDateHeader: View {
//    let date: Date
//    
//    var body: some View {
//        Text(date, style: .date)
//            .font(.subheadline)
//            .padding()
//            .background(Color(.secondarySystemGroupedBackground))
//    }
//}

// Example Placeholder for Transaction Row
//struct TransactionRow: View {
//    let transaction: Transaction
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(transaction.category ?? "Unknown Category")
//                    .font(.headline)
//                Text(transaction.note ?? "")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            Spacer()
//            Text("$\(transaction.amount, specifier: "%.2f")")
//                .foregroundColor(transaction.amount >= 0 ? .green : .red)
//        }
//        .padding()
//    }
//}

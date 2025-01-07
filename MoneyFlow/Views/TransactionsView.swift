import SwiftUI
import CoreData

// MARK: - Transaction Filter Enum
/// Enum for type-safe filter options
enum TransactionFilter: String, CaseIterable {
    case all, income, expense, transfer
    
    var title: String { rawValue.capitalized }
}

// MARK: - Main Transactions View
struct TransactionsView: View {
    // MARK: - Environment & Bindings
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showingAddTransaction: Bool
    
    // MARK: - Fetch Request
    /// Optimized fetch request with proper sort descriptors and animation
    @FetchRequest private var transactions: FetchedResults<Transaction>
    
    // MARK: - State
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: Transaction?
    
    // MARK: - Initialization
    init(showingAddTransaction: Binding<Bool>) {
        self._showingAddTransaction = showingAddTransaction
        
        // Initialize fetch request with proper sorting
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        self._transactions = FetchRequest(
            fetchRequest: request,
            animation: .default
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    EmptyStateView(
                        title: "No Transactions Yet",
                        message: "Start adding your income and expenses to track your spending",
                        systemImage: "empty_transaction"
                    )
                } else {
                    transactionListView
                }
            }
            .navigationTitle("Transactions")
            // .toolbar { transactionToolbar }
            .searchable(text: $searchText, prompt: "Search transactions")
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
    
    // MARK: - Computed Properties
    /// Filtered transactions based on search text and selected filter
    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            let matchesSearch = searchText.isEmpty ||
            transaction.category?.localizedCaseInsensitiveContains(searchText) == true ||
            transaction.note?.localizedCaseInsensitiveContains(searchText) == true
            
            let matchesFilter = selectedFilter == .all ||
            transaction.type == selectedFilter.rawValue
            
            return matchesSearch && matchesFilter
        }
    }
    
    /// Grouped transactions by date
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date ?? Date())
        }
        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - View Components
    /// Main transaction list view
    private var transactionListView: some View {
        VStack(spacing: 0) {
            filterPillsView
            transactionScrollView
        }
    }
    
    /// Filter pills scroll view
    private var filterPillsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    /// Transaction scroll view with lazy loading
    private var transactionScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedTransactions, id: \.date) { group in
                    Section(header: TransactionDateHeader(date: group.date)) {
                        transactionGroupView(for: group.transactions)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    /// Transaction group view
    private func transactionGroupView(for transactions: [Transaction]) -> some View {
        VStack(spacing: 0) {
            ForEach(transactions) { transaction in
                transactionItemView(for: transaction)
            }
        }
        .background(Color(.systemBackground))
    }
    
    /// Individual transaction item view
    private func transactionItemView(for transaction: Transaction) -> some View {
        VStack(spacing: 0) {
            TransactionRow(transaction: transaction)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTransaction = selectedTransaction == transaction ? nil : transaction
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTransaction(transaction)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        // Edit action
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            
            if selectedTransaction == transaction {
                TransactionDetailView(transaction: transaction)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
                .padding(.leading, 80)
                .padding(.trailing, 16)
        }
    }
    
    /// Toolbar view
    //    private var transactionToolbar: some ToolbarContent {
    //        Group {
    //            ToolbarItem(placement: .navigationBarTrailing) {
    //                Button(action: { showingAddTransaction = true }) {
    //                    Image(systemName: "plus")
    //                        .fontWeight(.semibold)
    //                }
    //            }
    //
    //            ToolbarItem(placement: .navigationBarLeading) {
    //                Button {
    //                    // Show filter/sort options
    //                } label: {
    //                    Image(systemName: "line.3.horizontal.decrease.circle")
    //                        .symbolRenderingMode(.hierarchical)
    //                        .font(.system(.title3))
    //                }
    //            }
    //        }
    //    }
    
    // MARK: - Helper Methods
    /// Delete transaction with proper error handling
    private func deleteTransaction(_ transaction: Transaction) {
        viewContext.performAndWait {
            if let account = transaction.account {
                account.balance -= transaction.amount
            }
            
            viewContext.delete(transaction)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting transaction: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct TransactionDateHeader: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(date, style: .date)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let note = transaction.note, !note.isEmpty {
                Text("Note")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(note)
                    .font(.body)
            }
            
            if let account = transaction.account {
                Text("Account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(account.name ?? "Unknown Account")
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isSelected ? .blue : Color(.secondarySystemGroupedBackground))
                }
                .overlay {
                    Capsule()
                        .strokeBorder(Color(.separator).opacity(0.1), lineWidth: 1)
                }
        }
    }
}

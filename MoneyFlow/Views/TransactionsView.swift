import SwiftUI
import CoreData

struct TransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    @State private var showingAddTransaction = false
    @State private var searchText = ""
    @State private var selectedFilter = "all"
    @State private var selectedTransaction: Transaction?
    
    private let filterOptions = ["all", "income", "expense", "transfer"]
    
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
                    VStack(spacing: 0) {
                        // Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filterOptions, id: \.self) { filter in
                                    FilterPill(
                                        title: filter.capitalized,
                                        isSelected: selectedFilter == filter,
                                        action: { selectedFilter = filter }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 8)
                        
                        // Transactions List
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                ForEach(groupedTransactions, id: \.date) { group in
                                    Section(header: TransactionDateHeader(date: group.date)) {
                                        VStack(spacing: 0) {
                                            ForEach(group.transactions) { transaction in
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
                                        }
                                        .background(Color(.systemBackground))
                                    }
                                }
                            }
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(.title3))
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Show filter/sort options
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(.title3))
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions")
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
    
    // Helper Views
    private func calculateTotalIncome() -> Double {
        transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateTotalExpenses() -> Double {
        transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }
    
    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            let matchesSearch = searchText.isEmpty ||
                              transaction.category?.localizedCaseInsensitiveContains(searchText) == true ||
                              transaction.note?.localizedCaseInsensitiveContains(searchText) == true
            
            let matchesFilter = selectedFilter == "all" ||
                              transaction.type == selectedFilter
            
            return matchesSearch && matchesFilter
        }
    }
    
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date ?? Date())
        }
        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation {
            // Update account balance
            if let account = transaction.account {
                account.balance -= transaction.amount
            }
            
            // Delete transaction
            viewContext.delete(transaction)
            try? viewContext.save()
        }
    }
}

// Updated Transaction Date Header
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

// Filter Pill Component
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

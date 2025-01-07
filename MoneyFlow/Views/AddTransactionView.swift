import SwiftUI
import CoreData

// MARK: - View Model
/// ViewModel to handle business logic and state management for AddTransactionView
final class AddTransactionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var amount: String = ""
    @Published var category: String = ""
    @Published var note: String = ""
    @Published var type: TransactionType = .expense
    @Published var selectedAccount: Account?
    @Published var isRecurring = false
    @Published var frequency: RecurringFrequency = .monthly
    @Published var startDate = Date()
    @Published var endDate: Date?
    @Published var hasEndDate = false
    @Published var date = Date()
    @Published var showAddCategory = false
    
    // MARK: - Alert Properties
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !amount.isEmpty && selectedAccount != nil && !category.isEmpty
    }
    
    // MARK: - Methods
    func validateAndSaveTransaction(in context: NSManagedObjectContext, completion: @escaping () -> Void) {
        guard let amountDouble = Double(amount),
              let account = selectedAccount else { return }
        
        if type == .expense && account.balance < amountDouble {
            showInsufficientFundsAlert(balance: account.balance, amount: amountDouble)
            return
        }
        
        saveTransaction(amountDouble: amountDouble, account: account, in: context, completion: completion)
    }
    
    private func showInsufficientFundsAlert(balance: Double, amount: Double) {
        alertTitle = "Insufficient Funds"
        alertMessage = String(format: "Your account balance ($%.2f) is less than the transaction amount ($%.2f).",
                              balance, amount)
        showAlert = true
    }
    
    private func saveTransaction(amountDouble: Double, account: Account, in context: NSManagedObjectContext, completion: @escaping () -> Void) {
        context.performAndWait {
            let transaction = createTransaction(amount: amountDouble, account: account, in: context)
            updateAccountBalance(account: account, amount: transaction.amount)
            
            if isRecurring {
                createRecurringTransaction(for: transaction, in: context)
            }
            
            if type == .expense {
                updateBudget(for: category, amount: amountDouble, in: context)
            }
            
            do {
                try context.save()
                completion()
            } catch {
                showSaveError(error)
            }
        }
    }
    
    private func createTransaction(amount: Double, account: Account, in context: NSManagedObjectContext) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = type == .expense ? -amount : amount
        transaction.category = category
        transaction.date = date
        transaction.note = note
        transaction.type = type.rawValue
        transaction.account = account
        transaction.isRecurring = isRecurring
        return transaction
    }
    
    private func createRecurringTransaction(for transaction: Transaction, in context: NSManagedObjectContext) {
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.frequency = frequency.rawValue
        recurring.startDate = startDate
        recurring.endDate = hasEndDate ? endDate : nil
        recurring.lastProcessed = Date()
        recurring.transaction = transaction
    }
    
    private func updateAccountBalance(account: Account, amount: Double) {
        account.balance += amount
    }
    
    private func updateBudget(for category: String, amount: Double, in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let budgets = try context.fetch(fetchRequest)
            budgets.forEach { $0.spent += abs(amount) }
        } catch {
            print("Error updating budget: \(error)")
        }
    }
    
    private func showSaveError(_ error: Error) {
        alertTitle = "Error"
        alertMessage = "Failed to save transaction: \(error.localizedDescription)"
        showAlert = true
    }
}

// MARK: - Enums
enum TransactionType: String {
    case expense
    case income
}

enum RecurringFrequency: String, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
    
    var displayName: String { rawValue.capitalized }
}

// MARK: - View
struct AddTransactionView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    @StateObject private var viewModel = AddTransactionViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color(.black)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Type Selection
                    VStack(spacing: 16) {
                        HStack {
                            Text("Add Transaction")
                                .font(.title)
                                .fontWeight(.bold)
                            Spacer()
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Transaction Type Selector
                        HStack(spacing: 20) {
                            transactionTypeButton(.expense)
                            transactionTypeButton(.income)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    
                    // Amount Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("$")
                                .font(.title)
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $viewModel.amount)
                                .font(.system(size: 34, weight: .bold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Details Card
                    VStack(spacing: 20) {
                        // Category Selection
                        HStack {
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button {
                                        viewModel.category = category.name ?? ""
                                    } label: {
                                        HStack {
                                            Text(category.name ?? "")
                                            if viewModel.category == category.name {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.blue)
                                    Text(viewModel.category.isEmpty ? "Select Category" : viewModel.category)
                                        .foregroundColor(viewModel.category.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button(action: {
                                viewModel.showAddCategory = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Account Selection
                        Menu {
                            ForEach(accounts) { account in
                                Button {
                                    viewModel.selectedAccount = account
                                } label: {
                                    HStack {
                                        Text(account.name ?? "")
                                        if viewModel.selectedAccount == account {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.blue)
                                Text(viewModel.selectedAccount?.name ?? "Select Account")
                                    .foregroundColor(viewModel.selectedAccount == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Date Selection
                        DatePicker(selection: $viewModel.date, displayedComponents: .date) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Date")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Note Input
                        TextField("Add note", text: $viewModel.note)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Recurring Transaction Section
                    VStack(spacing: 20) {
                        Toggle("Recurring Transaction", isOn: $viewModel.isRecurring)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        if viewModel.isRecurring {
                            VStack(spacing: 20) {
                                // Frequency Picker
                                Picker("Frequency", selection: $viewModel.frequency) {
                                    ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                                        Text(frequency.displayName).tag(frequency)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                // Start Date
                                DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                
                                // End Date Toggle and Picker
                                VStack(spacing: 12) {
                                    Toggle("Has End Date", isOn: $viewModel.hasEndDate)
                                    if viewModel.hasEndDate {
                                        DatePicker("End Date", selection: Binding(
                                            get: { viewModel.endDate ?? Date() },
                                            set: { viewModel.endDate = $0 }
                                        ), displayedComponents: .date)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            
            // Save Button
            VStack {
                Spacer()
                Button(action: {
                    viewModel.validateAndSaveTransaction(in: viewContext) {
                        dismiss()
                    }
                }) {
                    Text("Save Transaction")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(!viewModel.isFormValid)
                .padding()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .sheet(isPresented: $viewModel.showAddCategory) {
            AddCategoryView(showAddCategory: $viewModel.showAddCategory)
        }
    }
    
    // MARK: - Helper Views
    private func transactionTypeButton(_ type: TransactionType) -> some View {
        Button(action: {
            viewModel.type = type
        }) {
            VStack(spacing: 8) {
                Image(systemName: type == .expense ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                Text(type == .expense ? "Expense" : "Income")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.type == type ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(viewModel.type == type ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.type == type ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

import SwiftUI
import CoreData

struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var amount: String = ""
    @State private var category: String = ""
    @State private var date = Date()
    @State private var note: String = ""
    @State private var type: String = "expense"
    @State private var selectedAccount: Account?
    @State private var isRecurring = false
    
    // Alert states
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Recurring transaction properties
    @State private var frequency: String = "monthly"
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    
    let categories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"]
    let frequencies = ["daily", "weekly", "monthly", "yearly"]
    
    var body: some View {
        NavigationView {
            Form {
                // Amount Section
                Section("Amount") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Type", selection: $type) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                    }
                    .pickerStyle(.segmented)
                }
                
                // Details Section
                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Account", selection: $selectedAccount) {
                        ForEach(accounts) { account in
                            Text(account.name ?? "").tag(account as Account?)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Note", text: $note)
                }
                
                // Recurring Section
                Section {
                    Toggle("Recurring Transaction", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(frequencies, id: \.self) { frequency in
                                Text(frequency.capitalized).tag(frequency)
                            }
                        }
                        
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        
                        Toggle("Has End Date", isOn: $hasEndDate)
                        if hasEndDate {
                            DatePicker("End Date", selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        validateAndSaveTransaction()
                    }
                    .disabled(amount.isEmpty || selectedAccount == nil || category.isEmpty)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateAndSaveTransaction() {
        guard let amountDouble = Double(amount),
              let account = selectedAccount else { return }
        
        // For expenses, check if there's enough balance
        if type == "expense" && account.balance < amountDouble {
            alertTitle = "Insufficient Funds"
            alertMessage = String(format: "Your account balance ($%.2f) is less than the transaction amount ($%.2f). Please adjust the amount or choose a different account.", account.balance, amountDouble)
            showAlert = true
            return
        }
        
        // If validation passes, proceed with saving
        saveTransaction(amountDouble: amountDouble, account: account)
    }
    
    private func saveTransaction(amountDouble: Double, account: Account) {
        // Create transaction
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.amount = type == "expense" ? -amountDouble : amountDouble
        transaction.category = category
        transaction.date = date
        transaction.note = note
        transaction.type = type
        transaction.account = account
        transaction.isRecurring = isRecurring
        
        // Update account balance
        account.balance += transaction.amount
        
        // Create recurring transaction if needed
        if isRecurring {
            let recurring = RecurringTransaction(context: viewContext)
            recurring.id = UUID()
            recurring.frequency = frequency
            recurring.startDate = startDate
            recurring.endDate = hasEndDate ? endDate : nil
            recurring.lastProcessed = Date()
            recurring.transaction = transaction
        }
        
        // Update budget spending for expenses
        if type == "expense" {
            let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", category)
            
            do {
                let budgets = try viewContext.fetch(fetchRequest)
                for budget in budgets {
                    budget.spent += abs(amountDouble)
                }
            } catch {
                print("Error updating budget: \(error)")
            }
        }
        
        // Save context
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save transaction: \(error.localizedDescription)"
            showAlert = true
        }
    }
} 

import SwiftUI
import CoreData

struct AddTransferView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var fromAccount: Account?
    @State private var toAccount: Account?
    @State private var date = Date()
    
    // Alert states
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transfer Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("From Account", selection: $fromAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(accounts) { account in
                            Text(account.name ?? "")
                                .tag(account as Account?)
                        }
                    }
                    
                    Picker("To Account", selection: $toAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(accounts) { account in
                            Text(account.name ?? "")
                                .tag(account as Account?)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Transfer Money")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Transfer") {
                        validateAndSaveTransfer()
                    }
                    .disabled(amount.isEmpty || fromAccount == nil || toAccount == nil || fromAccount == toAccount)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateAndSaveTransfer() {
        guard let amountDouble = Double(amount),
              let sourceAccount = fromAccount,
              let destinationAccount = toAccount else { return }
        
        // Validate amount is positive
        guard amountDouble > 0 else {
            alertTitle = "Invalid Amount"
            alertMessage = "Transfer amount must be greater than zero."
            showAlert = true
            return
        }
        
        // Check if source account has sufficient funds
        guard sourceAccount.balance >= amountDouble else {
            alertTitle = "Insufficient Funds"
            alertMessage = String(format: "Your account balance ($%.2f) is less than the transfer amount ($%.2f).", sourceAccount.balance, amountDouble)
            showAlert = true
            return
        }
        
        // Create withdrawal transaction
        let withdrawalTransaction = Transaction(context: viewContext)
        withdrawalTransaction.id = UUID()
        withdrawalTransaction.amount = -amountDouble
        withdrawalTransaction.category = "Transfer"
        withdrawalTransaction.date = date
        withdrawalTransaction.note = "Transfer to \(destinationAccount.name ?? "Unknown Account")\(note.isEmpty ? "" : ": \(note)")"
        withdrawalTransaction.type = "transfer"
        withdrawalTransaction.account = sourceAccount
        
        // Update source account balance
        sourceAccount.balance -= amountDouble
        
        // Create deposit transaction
        let depositTransaction = Transaction(context: viewContext)
        depositTransaction.id = UUID()
        depositTransaction.amount = amountDouble
        depositTransaction.category = "Transfer"
        depositTransaction.date = date
        depositTransaction.note = "Transfer from \(sourceAccount.name ?? "Unknown Account")\(note.isEmpty ? "" : ": \(note)")"
        depositTransaction.type = "transfer"
        depositTransaction.account = destinationAccount
        
        // Update destination account balance
        destinationAccount.balance += amountDouble
        
        // Save context
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to complete transfer: \(error.localizedDescription)"
            showAlert = true
        }
    }
} 
import SwiftUI
import CoreData

// MARK: - Add Transfer View
struct AddTransferView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var fromAccount: Account?
    @State private var toAccount: Account?
    @State private var date = Date()
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5)
    }
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Transfer Money")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Amount Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Amount")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("$")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                TextField("0.00", text: $amount)
                                    .font(.system(size: 34, weight: .bold))
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(secondaryBackgroundColor)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Account Selection
                        VStack(spacing: 16) {
                            // From Account
                            VStack(alignment: .leading, spacing: 12) {
                                Text("From Account")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Menu {
                                    ForEach(accounts) { account in
                                        Button {
                                            fromAccount = account
                                        } label: {
                                            HStack {
                                                Text(account.name ?? "")
                                                if fromAccount == account {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.up.right")
                                            .foregroundColor(.red)
                                        Text(fromAccount?.name ?? "Select Account")
                                            .foregroundColor(fromAccount == nil ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(secondaryBackgroundColor)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // To Account
                            VStack(alignment: .leading, spacing: 12) {
                                Text("To Account")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Menu {
                                    ForEach(accounts) { account in
                                        Button {
                                            toAccount = account
                                        } label: {
                                            HStack {
                                                Text(account.name ?? "")
                                                if toAccount == account {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.down.left")
                                            .foregroundColor(.green)
                                        Text(toAccount?.name ?? "Select Account")
                                            .foregroundColor(toAccount == nil ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(secondaryBackgroundColor)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Additional Details
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Date")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(secondaryBackgroundColor)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Note")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Add note", text: $note)
                                    .padding()
                                    .background(secondaryBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Transfer Button
                Button(action: validateAndSaveTransfer) {
                    Text("Transfer Money")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!amount.isEmpty && fromAccount != nil && toAccount != nil && fromAccount != toAccount ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(amount.isEmpty || fromAccount == nil || toAccount == nil || fromAccount == toAccount)
                .padding()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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

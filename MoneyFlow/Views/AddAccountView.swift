import SwiftUI

// MARK: - Add Account View
struct AddAccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var name: String = ""
    @State private var type: String = "checking"
    @State private var balance: String = ""
    @State private var isDefault: Bool = false
    
    let accountTypes = ["checking", "savings", "credit", "cash", "investment"]
    
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5)
    }
    
    private let accountTypeIcons: [String: String] = [
        "checking": "banknote",
        "savings": "bank",
        "credit": "creditcard",
        "cash": "dollarsign.circle",
        "investment": "chart.line.uptrend.xyaxis"
    ]
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Add Account")
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
                        // Account Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Account Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter account name", text: $name)
                                .padding()
                                .background(secondaryBackgroundColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Account Type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Account Type")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(accountTypes, id: \.self) { accountType in
                                        Button(action: {
                                            type = accountType
                                        }) {
                                            HStack {
                                                Image(systemName: accountTypeIcons[accountType] ?? "questionmark")
                                                Text(accountType.capitalized)
                                                    .fontWeight(.medium)
                                            }
                                            .padding()
                                            .background(type == accountType ? Color.blue.opacity(0.2) : secondaryBackgroundColor)
                                            .foregroundColor(type == accountType ? .blue : .primary)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(type == accountType ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Initial Balance
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Initial Balance")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("$")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                TextField("0.00", text: $balance)
                                    .font(.system(size: 34, weight: .bold))
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(secondaryBackgroundColor)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Default Account Toggle
                        Toggle("Set as Default Account", isOn: $isDefault)
                            .padding()
                            .background(secondaryBackgroundColor)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                
                // Save Button
                Button(action: saveAccount) {
                    Text("Save Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!name.isEmpty && !balance.isEmpty ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(name.isEmpty || balance.isEmpty)
                .padding()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
            }
        }
    }
    
    private func saveAccount() {
        guard let balanceDouble = Double(balance) else { return }
        
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = name
        account.type = type
        account.balance = balanceDouble
        account.isDefault = isDefault
        account.createdAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving account: \(error)")
        }
    }
}

import SwiftUI

struct AddAccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var type: String = "checking"
    @State private var balance: String = ""
    @State private var isDefault: Bool = false
    
    let accountTypes = ["checking", "savings", "credit", "cash", "investment"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $name)
                    
                    Picker("Account Type", selection: $type) {
                        ForEach(accountTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    TextField("Initial Balance", text: $balance)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Toggle("Set as Default Account", isOn: $isDefault)
                }
                
                Section {
                    Button("Save Account", action: saveAccount)
                        .disabled(name.isEmpty || balance.isEmpty)
                }
            }
            .navigationTitle("Add Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
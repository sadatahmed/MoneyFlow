import SwiftUI

struct EditAccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var account: Account
    @State private var name: String
    @State private var type: String
    @State private var isDefault: Bool
    @State private var showingDeleteAlert = false
    
    let accountTypes = ["checking", "savings", "credit", "cash", "investment"]
    
    init(account: Account) {
        self.account = account
        _name = State(initialValue: account.name ?? "")
        _type = State(initialValue: account.type ?? "checking")
        _isDefault = State(initialValue: account.isDefault)
    }
    
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
                    
                    Toggle("Set as Default Account", isOn: $isDefault)
                }
                
                Section {
                    Button("Delete Account", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Edit Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete this account? This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() {
        account.name = name
        account.type = type
        account.isDefault = isDefault
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving account changes: \(error)")
        }
    }
    
    private func deleteAccount() {
        viewContext.delete(account)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting account: \(error)")
        }
    }
} 
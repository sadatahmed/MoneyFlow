import SwiftUI

struct AddBudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var category: String = ""
    @State private var limit: String = ""
    @State private var period: String = "monthly"
    
    let categories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"]
    let periods = ["weekly", "monthly", "yearly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("Budget Limit", text: $limit)
                        .keyboardType(.decimalPad)
                    
                    Picker("Period", selection: $period) {
                        ForEach(periods, id: \.self) { period in
                            Text(period.capitalized).tag(period)
                        }
                    }
                }
                
                Section {
                    Button("Save Budget") {
                        saveBudget()
                    }
                    .disabled(category.isEmpty || limit.isEmpty)
                }
            }
            .navigationTitle("Add Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let limitDouble = Double(limit) else { return }
        
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.category = category
        budget.limit = limitDouble
        budget.period = period
        budget.spent = 0
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving budget: \(error)")
        }
    }
}

#Preview {
    AddBudgetView()
        .environment(\.managedObjectContext, DataController().container.viewContext)
} 
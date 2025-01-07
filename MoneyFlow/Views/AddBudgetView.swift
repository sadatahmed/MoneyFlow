import SwiftUI

struct AddBudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var category: String = ""
    @State private var limit: String = ""
    @State private var period: String = "monthly"
    
    let categories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"]
    let periods = ["weekly", "monthly", "yearly"]
    
    private let categoryIcons: [String: String] = [
        "Food": "fork.knife",
        "Transport": "car.fill",
        "Entertainment": "tv.fill",
        "Shopping": "cart.fill",
        "Bills": "doc.text.fill",
        "Other": "square.grid.2x2.fill"
    ]
    
    // Color computing properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.black) : .white
    }
    
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Add Budget")
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
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(categories, id: \.self) { categoryItem in
                                    categoryButton(categoryItem)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Budget Limit Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Budget Limit")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("$")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                TextField("0.00", text: $limit)
                                    .font(.system(size: 34, weight: .bold))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(secondaryBackgroundColor)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Period Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Period")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                ForEach(periods, id: \.self) { periodItem in
                                    periodButton(periodItem)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveBudget) {
                    Text("Save Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!category.isEmpty && !limit.isEmpty ? Color.blue : Color.gray.opacity(0.5))
                        .cornerRadius(16)
                }
                .disabled(category.isEmpty || limit.isEmpty)
                .padding()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
            }
        }
    }
    
    private func categoryButton(_ categoryItem: String) -> some View {
        Button(action: {
            category = categoryItem
        }) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcons[categoryItem] ?? "square.fill")
                    .font(.title3)
                    .frame(width: 24) // Fixed width for icon
                
                Text(categoryItem)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75) // Scale down to 75% if needed
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                category == categoryItem ?
                Color.blue.opacity(0.2) :
                    secondaryBackgroundColor
            )
            .foregroundColor(category == categoryItem ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(category == categoryItem ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func periodButton(_ periodItem: String) -> some View {
        Button(action: {
            period = periodItem
        }) {
            Text(periodItem.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    period == periodItem ?
                    Color.blue.opacity(0.2) :
                        secondaryBackgroundColor
                )
                .foregroundColor(period == periodItem ? .blue : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(period == periodItem ? Color.blue : Color.clear, lineWidth: 2)
                )
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

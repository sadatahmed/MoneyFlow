//
//  AddCategoryView.swift
//  MoneyFlow
//
//  Created by Sadat Ahmed on 7/1/25.
//

import SwiftUI
import CoreData

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var showAddCategory: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Category Name", text: $categoryName)
                }
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveCategory() {
        // Check if category already exists
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", categoryName)
        
        do {
            let count = try viewContext.count(for: fetchRequest)
            if count > 0 {
                alertMessage = "This category already exists"
                showAlert = true
                return
            }
            
            let category = Category(context: viewContext)
            category.id = UUID()
            category.name = categoryName
            category.createdAt = Date()
            
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "Error saving category: \(error.localizedDescription)"
            showAlert = true
        }
    }
}


//#Preview {
//    AddCategoryView(showAddCategory: true)
//}

//
//  DataController.swift
//  MoneyFlow
//
//  Created by Sadat Ahmed on 20/11/24.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "MoneyFlow")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                return
            }
            
            // Enable constraints
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    // MARK: - Saving Context
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Account Methods
    func createAccount(name: String, type: String, balance: Double, isDefault: Bool = false) -> Account {
        let account = Account(context: container.viewContext)
        account.id = UUID()
        account.name = name
        account.type = type
        account.balance = balance
        account.isDefault = isDefault
        account.createdAt = Date()
        save()
        return account
    }
    
    // MARK: - Transaction Methods
    func createTransaction(amount: Double, category: String, date: Date, note: String, type: String, account: Account) -> Transaction {
        let transaction = Transaction(context: container.viewContext)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.category = category
        transaction.date = date
        transaction.note = note
        transaction.type = type
        transaction.account = account
        
        // Update account balance
        account.balance += amount
        
        save()
        return transaction
    }
    
    // MARK: - RecurringTransaction Methods
    func createRecurringTransaction(transaction: Transaction, frequency: String, startDate: Date, endDate: Date?) -> RecurringTransaction {
        let recurring = RecurringTransaction(context: container.viewContext)
        recurring.id = UUID()
        recurring.frequency = frequency
        recurring.startDate = startDate
        recurring.endDate = endDate
        recurring.lastProcessed = Date()
        recurring.transaction = transaction
        transaction.isRecurring = true
        
        save()
        return recurring
    }
    
    // MARK: - Budget Methods
    func createBudget(category: String, limit: Double, period: String) -> Budget {
        let budget = Budget(context: container.viewContext)
        budget.id = UUID()
        budget.category = category
        budget.limit = limit
        budget.period = period
        budget.spent = 0
        
        save()
        return budget
    }
    
    // MARK: - Budget Update Methods
    func updateBudgetSpending(for category: String, amount: Double) {
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let budgets = try container.viewContext.fetch(fetchRequest)
            for budget in budgets {
                if shouldUpdateBudget(budget) {
                    budget.spent += abs(amount) // Use absolute value for expenses
                }
            }
            save()
        } catch {
            print("Error updating budget spending: \(error)")
        }
    }
    
    private func shouldUpdateBudget(_ budget: Budget) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch budget.period {
        case "weekly":
            // Check if the budget is for the current week
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))
            return true // Simplified for now, you might want to add more complex logic
            
        case "monthly":
            // Check if the budget is for the current month
            let currentMonth = calendar.component(.month, from: now)
            let budgetMonth = calendar.component(.month, from: now)
            return currentMonth == budgetMonth
            
        case "yearly":
            // Check if the budget is for the current year
            let currentYear = calendar.component(.year, from: now)
            let budgetYear = calendar.component(.year, from: now)
            return currentYear == budgetYear
            
        default:
            return false
        }
    }
    
    // MARK: - Delete Methods
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
    
    // Add these methods
    func createCategory(name: String) -> Category {
        let category = Category(context: container.viewContext)
        category.id = UUID()
        category.name = name
        category.createdAt = Date()
        save()
        return category
    }
    
    func deleteCategory(_ category: Category) {
        container.viewContext.delete(category)
        save()
    }
    
    // Add this method to seed default categories if needed
    func seedDefaultCategories() {
        let defaultCategories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"]
        
        for categoryName in defaultCategories {
            // Only create if it doesn't exist
            if !categoryExists(categoryName) {
                let category = Category(context: container.viewContext)
                category.id = UUID()
                category.name = categoryName
                category.createdAt = Date()
            }
        }
        
        // Save after creating all categories
        save()
    }
    
    // Add a method to check if a category already exists
    func categoryExists(_ name: String) -> Bool {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        
        do {
            let count = try container.viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking category existence: \(error)")
            return false
        }
    }
}


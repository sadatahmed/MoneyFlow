import SwiftUI
import CoreData

class UserDataManager: ObservableObject {
    private let dataController: DataController
    private let authManager: AuthenticationManager
    
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var budgets: [Budget] = []
    @Published var categories: [Category] = []
    
    init(dataController: DataController, authManager: AuthenticationManager) {
        self.dataController = dataController
        self.authManager = authManager
    }
    
    // MARK: - Data Refresh
    func refreshUserData() {
        guard let userId = authManager.currentUser?.id,
              let userEntity = getCurrentUserEntity() else {
            clearData()
            return
        }
        
        fetchUserAccounts(userId)
        fetchUserTransactions(userId)
        fetchUserBudgets(userId)
        fetchUserCategories(userId)
        
        // Seed categories for new users
        if categories.isEmpty {
            dataController.seedDefaultCategories(for: userEntity)
            fetchUserCategories(userId)
        }
    }
    
    // MARK: - User Entity Helper
    private func getCurrentUserEntity() -> UserEntity? {
        guard let userId = authManager.currentUser?.id else { return nil }
        
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        
        do {
            return try dataController.container.viewContext.fetch(request).first
        } catch {
            print("Error fetching user entity: \(error)")
            return nil
        }
    }
    
    // MARK: - Create Methods
    func createAccount(name: String, type: String, balance: Double, isDefault: Bool = false) {
        guard let userEntity = getCurrentUserEntity() else { return }
        let _ = dataController.createAccount(name: name,
                                           type: type,
                                           balance: balance,
                                           isDefault: isDefault,
                                           user: userEntity)
        refreshUserData()
    }
    
    func createTransaction(amount: Double, category: String, date: Date, note: String, type: String, account: Account) {
        guard let userEntity = getCurrentUserEntity() else { return }
        let _ = dataController.createTransaction(amount: amount,
                                               category: category,
                                               date: date,
                                               note: note,
                                               type: type,
                                               account: account,
                                               user: userEntity)
        refreshUserData()
    }
    
    func createBudget(category: String, limit: Double, period: String) {
        guard let userEntity = getCurrentUserEntity() else { return }
        let _ = dataController.createBudget(category: category,
                                          limit: limit,
                                          period: period,
                                          user: userEntity)
        refreshUserData()
    }
    
    // MARK: - Fetch Methods
    private func fetchUserAccounts(_ userId: UUID) {
        guard let userEntity = getCurrentUserEntity() else {
            accounts = []
            return
        }
        accounts = dataController.fetchUserAccounts(for: userEntity)
    }
    
    private func fetchUserTransactions(_ userId: UUID) {
        guard let userEntity = getCurrentUserEntity() else {
            transactions = []
            return
        }
        transactions = dataController.fetchUserTransactions(for: userEntity)
    }
    
    private func fetchUserBudgets(_ userId: UUID) {
        guard let userEntity = getCurrentUserEntity() else {
            budgets = []
            return
        }
        budgets = dataController.fetchUserBudgets(for: userEntity)
    }
    
    private func fetchUserCategories(_ userId: UUID) {
        guard let userEntity = getCurrentUserEntity() else {
            categories = []
            return
        }
        categories = dataController.fetchUserCategories(for: userEntity)
    }
    
    // MARK: - Clear Data
    private func clearData() {
        accounts = []
        transactions = []
        budgets = []
        categories = []
    }
    
    // MARK: - Delete Methods
    func deleteAccount(_ account: Account) {
        dataController.delete(account)
        refreshUserData()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        dataController.delete(transaction)
        refreshUserData()
    }
    
    func deleteBudget(_ budget: Budget) {
        dataController.delete(budget)
        refreshUserData()
    }
} 
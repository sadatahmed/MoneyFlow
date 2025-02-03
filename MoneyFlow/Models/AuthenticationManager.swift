import SwiftUI
import CoreData
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authError: AuthError?
    @Published var showError = false
    
    // User defaults key for persisting login state
    private let isAuthenticatedKey = "isAuthenticated"
    private let userKey = "currentUser"
    
    private let dataController: DataController
    
    init(dataController: DataController) {
        self.dataController = dataController
        // Load persisted authentication state
        isAuthenticated = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        }
    }
    
    func login(email: String, password: String) {
        let context = dataController.container.viewContext
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let results = try context.fetch(request)
            if let userEntity = results.first {
                // In a real app, you should use proper password hashing
                if userEntity.password == password {
                    let user = User(id: userEntity.id ?? UUID(),
                                  email: userEntity.email ?? "",
                                  fullName: userEntity.fullName ?? "",
                                  age: Int(userEntity.age),
                                  monthlyIncome: userEntity.monthlyIncome)
                    
                    self.currentUser = user
                    self.isAuthenticated = true
                    
                    // Persist authentication state
                    UserDefaults.standard.set(true, forKey: self.isAuthenticatedKey)
                    if let encoded = try? JSONEncoder().encode(user) {
                        UserDefaults.standard.set(encoded, forKey: self.userKey)
                    }
                } else {
                    self.authError = .invalidCredentials
                    self.showError = true
                }
            } else {
                self.authError = .invalidCredentials
                self.showError = true
            }
        } catch {
            self.authError = .unknown
            self.showError = true
            print("Error fetching user: \(error)")
        }
    }
    
    func logout() {
        // Clear user data from UserDefaults
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.set(false, forKey: isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        
        // Clear Core Data context to prevent data leakage
        let context = dataController.container.viewContext
        
        // Reset the context
        context.reset()
        
        // Create a new background context for cleanup
        let backgroundContext = dataController.container.newBackgroundContext()
        backgroundContext.perform {
            // Fetch and delete any orphaned data
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Account")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try backgroundContext.execute(deleteRequest)
            } catch {
                print("Error cleaning up data: \(error)")
            }
        }
    }
    
    func register(user: UserRegistration) {
        let context = dataController.container.viewContext
        
        // Check if email already exists
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", user.email)
        
        do {
            let results = try context.fetch(request)
            if !results.isEmpty {
                self.authError = .emailAlreadyExists
                self.showError = true
                return
            }
            
            // Create new user entity
            let userEntity = UserEntity(context: context)
            userEntity.id = UUID()
            userEntity.email = user.email
            userEntity.password = user.password // In a real app, hash the password
            userEntity.fullName = user.fullName
            userEntity.age = Int16(user.age)
            userEntity.monthlyIncome = user.monthlyIncome
            
            try context.save()
            
            // Create User model and set as current user
            let newUser = User(id: userEntity.id ?? UUID(),
                              email: userEntity.email ?? "",
                              fullName: userEntity.fullName ?? "",
                              age: Int(userEntity.age),
                              monthlyIncome: userEntity.monthlyIncome)
            
            self.currentUser = newUser
            self.isAuthenticated = true
            
            // Persist authentication state
            UserDefaults.standard.set(true, forKey: self.isAuthenticatedKey)
            if let encoded = try? JSONEncoder().encode(newUser) {
                UserDefaults.standard.set(encoded, forKey: self.userKey)
            }
            
        } catch {
            self.authError = .unknown
            self.showError = true
            print("Error registering user: \(error)")
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case passwordMismatch
    case networkError
    case emailAlreadyExists
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .passwordMismatch:
            return "Passwords do not match"
        case .networkError:
            return "Network error occurred"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .unknown:
            return "An unknown error occurred"
        }
    }
} 

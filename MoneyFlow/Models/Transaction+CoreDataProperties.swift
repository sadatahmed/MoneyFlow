import Foundation
import CoreData

extension Transaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var type: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var account: Account?
    @NSManaged public var recurring: RecurringTransaction?
} 
import Foundation
import CoreData

extension RecurringTransaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurringTransaction> {
        return NSFetchRequest<RecurringTransaction>(entityName: "RecurringTransaction")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var frequency: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var lastProcessed: Date?
    @NSManaged public var transaction: Transaction?
} 
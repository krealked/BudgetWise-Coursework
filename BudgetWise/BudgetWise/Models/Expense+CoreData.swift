import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject {
    
}

extension Expense {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var amount: Double
    @NSManaged public var category: String
    @NSManaged public var date: Date
    @NSManaged public var note: String
    
}

import Foundation
import CoreData

@objc(BudgetLimit)
public class BudgetLimit: NSManagedObject {
    
}

extension BudgetLimit {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BudgetLimit> {
        return NSFetchRequest<BudgetLimit>(entityName: "BudgetLimit")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var category: String
    @NSManaged public var monthlyLimit: Double
    @NSManaged public var createdAt: Date
    
}

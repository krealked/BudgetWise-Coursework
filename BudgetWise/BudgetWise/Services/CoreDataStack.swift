import Foundation
import CoreData

public class CoreDataStack {
    
    // MARK: - Singleton
    public static let shared = CoreDataStack()
    
    // MARK: - Properties
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BudgetWise")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Core Data Saving
    public func saveContext() {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Fetch Functions
    public func fetchExpenses() -> [Expense] {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }
}

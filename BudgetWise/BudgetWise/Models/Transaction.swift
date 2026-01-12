import Foundation
import CoreData

// MARK: - Transaction Category Enum
public enum TransactionCategory: String, CaseIterable, Identifiable {
    case food = "Продукты"
    case transport = "Транспорт"
    case entertainment = "Развлечения"
    case shopping = "Покупки"
    case bills = "Счета"
    case health = "Здоровье"
    case education = "Образование"
    case cafe = "Кафе"
    case other = "Другое"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .food: return "cart.fill"
        case .transport: return "car.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .bills: return "doc.text.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Transaction Model
public struct Transaction: Identifiable, Hashable {
    public let id: UUID
    public var amount: Double
    public var category: TransactionCategory
    public var date: Date
    public var note: String
    
    public init(
        id: UUID = UUID(),
        amount: Double,
        category: TransactionCategory,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
    }
}

// MARK: - Core Data Compatibility
extension Transaction {
    /// Создает Transaction из Expense (Core Data)
    public init(from expense: Expense) {
        self.id = expense.id
        self.amount = expense.amount
        self.category = TransactionCategory(rawValue: expense.category) ?? .other
        self.date = expense.date
        self.note = expense.note
    }
    
    /// Создает или обновляет Expense (Core Data) из Transaction
    public func toExpense(context: NSManagedObjectContext) -> Expense {
        let expense: Expense
        
        // Пытаемся найти существующий Expense по id
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let existingExpense = try? context.fetch(fetchRequest).first {
            expense = existingExpense
        } else {
            expense = Expense(context: context)
            expense.id = id
        }
        
        expense.amount = amount
        expense.category = category.rawValue
        expense.date = date
        expense.note = note
        
        return expense
    }
}

// MARK: - Array Extensions
extension Array where Element == Expense {
    /// Конвертирует массив Expense в массив Transaction
    public func toTransactions() -> [Transaction] {
        return self.map { Transaction(from: $0) }
    }
}

extension Array where Element == Transaction {
    /// Конвертирует массив Transaction в массив Expense в контексте
    public func toExpenses(context: NSManagedObjectContext) -> [Expense] {
        return self.map { $0.toExpense(context: context) }
    }
}

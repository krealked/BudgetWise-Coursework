import Foundation
import CoreData

public class CoreDataTest {
    
    /// Пример создания и сохранения тестовой транзакции через CoreDataStack
    public static func createTestExpense() {
        let context = CoreDataStack.shared.viewContext
        
        // Создание новой транзакции (Expense)
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = 1500.0
        expense.category = "Продукты"
        expense.date = Date()
        expense.note = "Тестовая транзакция"
        
        // Сохранение контекста
        CoreDataStack.shared.saveContext()
        
        print("Тестовая транзакция успешно создана и сохранена")
    }
    
    /// Пример создания нескольких тестовых транзакций
    public static func createMultipleTestExpenses() {
        let context = CoreDataStack.shared.viewContext
        
        let testExpenses = [
            (amount: 1500.0, category: "Продукты", note: "Покупка продуктов"),
            (amount: 2500.0, category: "Транспорт", note: "Бензин"),
            (amount: 500.0, category: "Кафе", note: "Обед"),
            (amount: 3000.0, category: "Развлечения", note: "Кино")
        ]
        
        for testExpense in testExpenses {
            let expense = Expense(context: context)
            expense.id = UUID()
            expense.amount = testExpense.amount
            expense.category = testExpense.category
            expense.date = Date()
            expense.note = testExpense.note
        }
        
        // Сохранение всех транзакций
        CoreDataStack.shared.saveContext()
        
        print("Создано \(testExpenses.count) тестовых транзакций")
    }
    
    /// Пример получения всех транзакций
    public static func fetchAllExpenses() {
        let expenses = CoreDataStack.shared.fetchExpenses()
        print("Найдено транзакций: \(expenses.count)")
        
        for expense in expenses {
            print("ID: \(expense.id), Категория: \(expense.category), Сумма: \(expense.amount), Дата: \(expense.date)")
        }
    }
}

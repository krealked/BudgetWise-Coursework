import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
public class ExpenseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Predictions
    @Published var simpleAveragePrediction: Double = 0.0
    @Published var movingAveragePrediction: Double = 0.0
    @Published var linearRegressionPrediction: Double = 0.0
    
    // MARK: - Statistics
    @Published var totalSpending: Double = 0.0
    @Published var averageMonthlySpending: Double = 0.0
    @Published var limits: [TransactionCategory: Double] = [:]
    
    // MARK: - Core Data
    private let coreDataStack = CoreDataStack.shared
    private let limitsStorageKey = "budgetwise.category.limits"
    private var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }
    
    // MARK: - Initialization
    public init() {
        loadLimits()
        loadTransactions()
        if transactions.count < 10 {
            generateRandomTransactions(count: 200)
        }
    }
    
    // MARK: - Load Transactions
    /// Загружает все транзакции из Core Data
    public func loadTransactions() {
        isLoading = true
        errorMessage = nil
        
        let expenses = coreDataStack.fetchExpenses()
        transactions = expenses.toTransactions()
        
        isLoading = false
        updatePredictions()
        updateStatistics()
    }
    
    // MARK: - Add Transaction
    /// Добавляет новую транзакцию
    /// - Parameter transaction: Транзакция для добавления
    public func addTransaction(_ transaction: Transaction) {
        let expense = transaction.toExpense(context: viewContext)
        
        do {
            try viewContext.save()
            loadTransactions()
        } catch {
            errorMessage = "Ошибка при добавлении транзакции: \(error.localizedDescription)"
            print("Error adding transaction: \(error)")
        }
    }
    
    // MARK: - Update Transaction
    /// Обновляет существующую транзакцию
    /// - Parameter transaction: Обновленная транзакция
    public func updateTransaction(_ transaction: Transaction) {
        let expense = transaction.toExpense(context: viewContext)
        
        do {
            try viewContext.save()
            loadTransactions()
        } catch {
            errorMessage = "Ошибка при обновлении транзакции: \(error.localizedDescription)"
            print("Error updating transaction: \(error)")
        }
    }
    
    // MARK: - Delete Transaction
    /// Удаляет транзакцию
    /// - Parameter transaction: Транзакция для удаления
    public func deleteTransaction(_ transaction: Transaction) {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)
        
        do {
            if let expense = try viewContext.fetch(fetchRequest).first {
                viewContext.delete(expense)
                try viewContext.save()
                loadTransactions()
            }
        } catch {
            errorMessage = "Ошибка при удалении транзакции: \(error.localizedDescription)"
            print("Error deleting transaction: \(error)")
        }
    }
    
    // MARK: - Delete Transactions at Offsets
    /// Удаляет транзакции по индексам
    /// - Parameter offsets: Набор индексов для удаления
    public func deleteTransactions(at offsets: IndexSet) {
        offsets.forEach { index in
            guard index < transactions.count else { return }
            deleteTransaction(transactions[index])
        }
    }

    /// Удаляет все транзакции из Core Data.
    public func deleteAllTransactions() {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()

        do {
            let expenses = try viewContext.fetch(fetchRequest)
            expenses.forEach { viewContext.delete($0) }
            try viewContext.save()
            loadTransactions()
        } catch {
            errorMessage = "Ошибка при удалении всех транзакций: \(error.localizedDescription)"
            print("Error deleting all transactions: \(error)")
        }
    }
    
    // MARK: - Predictions
    /// Обновляет все прогнозы на основе текущих транзакций
    public func updatePredictions() {
        simpleAveragePrediction = BudgetPredictor.simpleAverage(transactions)
        movingAveragePrediction = BudgetPredictor.movingAverage4Weeks(transactions)
        linearRegressionPrediction = BudgetPredictor.linearRegressionNextMonth(transactions)
    }
    
    // MARK: - Statistics
    /// Обновляет статистику трат
    public func updateStatistics() {
        totalSpending = transactions.reduce(0.0) { $0 + $1.amount }
        averageMonthlySpending = BudgetPredictor.averageMonthlySpending(transactions)
    }
    
    // MARK: - Filtered Transactions
    /// Возвращает транзакции за указанный период
    /// - Parameters:
    ///   - startDate: Начальная дата
    ///   - endDate: Конечная дата
    /// - Returns: Отфильтрованные транзакции
    public func transactions(from startDate: Date, to endDate: Date) -> [Transaction] {
        return transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
    }
    
    /// Возвращает транзакции по категории
    /// - Parameter category: Категория для фильтрации
    /// - Returns: Отфильтрованные транзакции
    public func transactions(for category: TransactionCategory) -> [Transaction] {
        return transactions.filter { $0.category == category }
    }
    
    /// Возвращает транзакции за текущий месяц
    /// - Returns: Транзакции за текущий месяц
    public func transactionsForCurrentMonth() -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        return transactions(from: startOfMonth, to: endOfMonth)
    }
    
    // MARK: - Category Statistics
    /// Возвращает сумму трат по категориям
    /// - Returns: Словарь с категориями и суммами
    public func spendingByCategory() -> [TransactionCategory: Double] {
        var categorySpending: [TransactionCategory: Double] = [:]
        
        for transaction in transactions {
            categorySpending[transaction.category, default: 0.0] += transaction.amount
        }
        
        return categorySpending
    }
    
    /// Возвращает процент трат по категориям
    /// - Returns: Словарь с категориями и процентами
    public func spendingPercentageByCategory() -> [TransactionCategory: Double] {
        let categorySpending = spendingByCategory()
        let total = totalSpending
        
        guard total > 0 else { return [:] }
        
        return categorySpending.mapValues { ($0 / total) * 100 }
    }
    
    // MARK: - Refresh
    /// Обновляет все данные
    public func refresh() {
        loadTransactions()
    }

    // MARK: - Demo / Test Data
    /// Добавляет случайные транзакции за последний год (не удаляет существующие).
    public func generateRandomTransactions(count: Int = 200) {
        let calendar = Calendar.current
        let now = Date()
        let categories = TransactionCategory.allCases

        for _ in 0..<count {
            guard let category = categories.randomElement() else { continue }
            let amount = Double.random(in: 100...5000)
            let daysAgo = Int.random(in: 0...365)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let note = Bool.random() ? "Тест" : ""

            let transaction = Transaction(
                amount: amount,
                category: category,
                date: date,
                note: note
            )
            _ = transaction.toExpense(context: viewContext)
        }

        do {
            try viewContext.save()
            loadTransactions()
        } catch {
            errorMessage = "Ошибка при генерации тестовых данных: \(error.localizedDescription)"
            print("Error generating transactions: \(error)")
        }
    }

    // MARK: - Category Limits
    public func loadLimits() {
        guard let stored = UserDefaults.standard.dictionary(forKey: limitsStorageKey) as? [String: Double] else {
            limits = [:]
            return
        }

        var mapped: [TransactionCategory: Double] = [:]
        for (rawCategory, value) in stored {
            guard let category = TransactionCategory(rawValue: rawCategory), value >= 0 else { continue }
            mapped[category] = value
        }
        limits = mapped
    }

    public func saveLimits() {
        let encoded: [String: Double] = limits.reduce(into: [:]) { partialResult, item in
            partialResult[item.key.rawValue] = max(0, item.value)
        }
        UserDefaults.standard.set(encoded, forKey: limitsStorageKey)
    }

    public func setLimit(_ value: Double, for category: TransactionCategory) {
        let sanitized = max(0, value)
        limits[category] = sanitized
        saveLimits()
    }

    public func limit(for category: TransactionCategory) -> Double {
        limits[category] ?? 0
    }

    /// Лимиты по категориям на месяц (то же хранилище, что и `limits`).
    public var monthlyLimits: [TransactionCategory: Double] {
        limits
    }

    // MARK: - Month filtering

    /// Транзакции за календарный месяц и год указанной даты.
    public func transactions(for month: Date) -> [Transaction] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return transactions.filter { interval.contains($0.date) }
    }

    /// Первый день каждого месяца, в котором есть транзакции (по возрастанию).
    public var monthsWithTransactions: [Date] {
        let calendar = Calendar.current
        let monthStarts = Set(
            transactions.compactMap { transaction in
                calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.date))
            }
        )
        return monthStarts.sorted()
    }

    // MARK: - Grouping by category

    public func groupedByCategory(for transactions: [Transaction]) -> [TransactionCategory: Double] {
        var totals: [TransactionCategory: Double] = [:]
        for transaction in transactions {
            totals[transaction.category, default: 0.0] += transaction.amount
        }
        return totals
    }

    public var categoryTotalsForCurrentMonth: [TransactionCategory: Double] {
        groupedByCategory(for: transactionsForCurrentMonth())
    }

    // MARK: - Forecast (BudgetPredictor)

    private func transactionsForLinearRegression(lastMonths: Int = 3, category: TransactionCategory?) -> [Transaction] {
        let calendar = Calendar.current
        let anchor = Date()
        guard let windowStart = calendar.date(byAdding: .month, value: -lastMonths, to: anchor) else {
            return []
        }
        var slice = transactions.filter { $0.date >= windowStart }
        if let category = category {
            slice = slice.filter { $0.category == category }
        }
        return slice
    }

    /// Прогноз трат на ближайшие `months` месяцев по линейной регрессии на данных за последние 3 месяца (или все, если меньше).
    public func predictedExpense(for category: TransactionCategory? = nil, months: Int = 1) -> Double {
        let history = transactionsForLinearRegression(lastMonths: 3, category: category)
        guard !history.isEmpty else { return 0.0 }
        let oneMonth = BudgetPredictor.linearRegressionPrediction(history)
        let horizon = max(1, months)
        return max(0.0, oneMonth * Double(horizon))
    }

    public func predictedExpenseForNextMonth() -> Double {
        predictedExpense(for: nil, months: 1)
    }

    // MARK: - Totals & balance

    /// Без поля `type` в `Transaction`: общая сумма по полю `amount` (как накопленные траты в приложении).
    public var totalExpense: Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }

    /// Без поля типа доход не различается — по заданию возвращаем 0.
    public var totalIncome: Double {
        0.0
    }

    public var balance: Double {
        totalIncome - totalExpense
    }

    // MARK: - Budget checks

    public func isBudgetExceeded(for category: TransactionCategory, limit: Double) -> Bool {
        guard limit > 0 else { return false }
        let spent = groupedByCategory(for: transactionsForCurrentMonth())[category, default: 0.0]
        return spent > limit
    }

    public func exceededCategories() -> [TransactionCategory] {
        monthlyLimits.compactMap { category, limit -> TransactionCategory? in
            guard limit > 0, isBudgetExceeded(for: category, limit: limit) else { return nil }
            return category
        }
        .sorted { $0.rawValue < $1.rawValue }
    }
}

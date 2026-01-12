import Foundation

public class BudgetPredictor {
    
    // MARK: - Simple Average
    /// Простое среднее арифметическое всех транзакций
    /// - Parameter transactions: Массив транзакций
    /// - Returns: Среднее значение суммы транзакций
    public static func simpleAverage(_ transactions: [Transaction]) -> Double {
        guard !transactions.isEmpty else { return 0.0 }
        
        let totalAmount = transactions.reduce(0.0) { $0 + $1.amount }
        return totalAmount / Double(transactions.count)
    }
    
    // MARK: - Moving Average (4 weeks)
    /// Скользящее среднее за последние 4 недели
    /// - Parameter transactions: Массив транзакций
    /// - Returns: Среднее значение суммы транзакций за последние 4 недели
    public static func movingAverage4Weeks(_ transactions: [Transaction]) -> Double {
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        
        let recentTransactions = transactions.filter { $0.date >= fourWeeksAgo }
        
        guard !recentTransactions.isEmpty else { return 0.0 }
        
        let totalAmount = recentTransactions.reduce(0.0) { $0 + $1.amount }
        return totalAmount / Double(recentTransactions.count)
    }
    
    // MARK: - Linear Regression
    /// Линейная регрессия для прогноза трат на следующий месяц
    /// Группирует транзакции по неделям и вычисляет линейную регрессию
    /// - Parameter transactions: Массив транзакций
    /// - Returns: Прогнозируемая сумма трат на следующий месяц
    public static func linearRegressionNextMonth(_ transactions: [Transaction]) -> Double {
        guard !transactions.isEmpty else { return 0.0 }
        
        // Группируем транзакции по неделям
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: transactions) { transaction in
            calendar.dateInterval(of: .weekOfYear, for: transaction.date)?.start ?? transaction.date
        }
        
        // Сортируем недели по дате
        let sortedWeeks = groupedByWeek.keys.sorted()
        
        guard sortedWeeks.count >= 2 else {
            // Если недостаточно данных, возвращаем простое среднее
            return simpleAverage(transactions) * 4.33 // Примерно 4.33 недели в месяце
        }
        
        // Вычисляем сумму трат для каждой недели
        var weeklyAmounts: [(x: Double, y: Double)] = []
        for (index, weekStart) in sortedWeeks.enumerated() {
            let weekTransactions = groupedByWeek[weekStart] ?? []
            let weekTotal = weekTransactions.reduce(0.0) { $0 + $1.amount }
            weeklyAmounts.append((x: Double(index), y: weekTotal))
        }
        
        // Вычисляем линейную регрессию: y = a + b*x
        let n = Double(weeklyAmounts.count)
        let sumX = weeklyAmounts.reduce(0.0) { $0 + $1.x }
        let sumY = weeklyAmounts.reduce(0.0) { $0 + $1.y }
        let sumXY = weeklyAmounts.reduce(0.0) { $0 + $1.x * $1.y }
        let sumX2 = weeklyAmounts.reduce(0.0) { $0 + $1.x * $1.x }
        
        // Формулы для линейной регрессии
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else {
            // Если знаменатель равен нулю, возвращаем простое среднее
            return simpleAverage(transactions) * 4.33
        }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        // Прогнозируем на следующие 4-5 недель (примерно месяц)
        let nextWeekIndex = Double(sortedWeeks.count)
        let predictedWeeklyAmount = intercept + slope * nextWeekIndex
        
        // Умножаем на количество недель в месяце (примерно 4.33)
        let monthlyPrediction = predictedWeeklyAmount * 4.33
        
        // Убеждаемся, что прогноз не отрицательный
        return max(0.0, monthlyPrediction)
    }
    
    // MARK: - Helper Methods
    
    /// Вычисляет среднее значение трат за месяц на основе исторических данных
    /// - Parameter transactions: Массив транзакций
    /// - Returns: Средняя сумма трат за месяц
    public static func averageMonthlySpending(_ transactions: [Transaction]) -> Double {
        guard !transactions.isEmpty else { return 0.0 }
        
        // Группируем транзакции по месяцам
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: transactions) { transaction in
            calendar.dateInterval(of: .month, for: transaction.date)?.start ?? transaction.date
        }
        
        // Вычисляем сумму для каждого месяца
        let monthlyTotals = groupedByMonth.values.map { monthTransactions in
            monthTransactions.reduce(0.0) { $0 + $1.amount }
        }
        
        guard !monthlyTotals.isEmpty else { return 0.0 }
        
        let average = monthlyTotals.reduce(0.0, +) / Double(monthlyTotals.count)
        return average
    }
}

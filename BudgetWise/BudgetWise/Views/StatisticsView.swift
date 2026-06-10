import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var selectedPeriod: StatisticsPeriod = .month

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Picker("Период", selection: $selectedPeriod) {
                    ForEach(StatisticsPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.themeAccent)
                .padding(.horizontal)

                if categoryTotalsForSelectedPeriod.isEmpty && lastSixMonthsTotals.isEmpty {
                    placeholderView
                } else {
                    pieChartSection
                    lineChartSection
                }
            }
            .padding(.vertical)
        }
        .background(Color.midnightSky)
    }

    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Распределение по категориям")
                .font(.headline)
                .foregroundStyle(Color.themeHeadingOnDark)

            if categoryTotalsForSelectedPeriod.isEmpty {
                Text("Нет данных за выбранный период")
                    .foregroundStyle(Color.themeCaptionOnDark)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
            } else {
                Chart(categoryTotalsForSelectedPeriod) { item in
                    SectorMark(
                        angle: .value("Сумма", item.total),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Категория", item.category.rawValue))
                }
                .frame(height: 260)
                .chartLegend(.hidden)

                categoryBreakdownList(items: categoryTotalsForSelectedPeriod)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.themeAccent.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func categoryBreakdownList(items: [CategoryTotal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.category.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(Color.themeAccent)
                        .frame(width: 28, alignment: .center)
                    Text(item.category.rawValue)
                        .foregroundStyle(Color.themeHeadingOnDark)
                    Spacer()
                    Text(item.total, format: .currency(code: "RUB"))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.themeAccent)
                }
            }
        }
        .padding(.top, 8)
    }

    private var lineChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Динамика за последние 6 месяцев")
                .font(.headline)
                .foregroundStyle(Color.themeHeadingOnDark)

            if lastSixMonthsTotals.isEmpty {
                Text("Недостаточно данных для графика")
                    .foregroundStyle(Color.themeCaptionOnDark)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
            } else {
                Chart(lastSixMonthsTotals) { item in
                    LineMark(
                        x: .value("Месяц", item.month, unit: .month),
                        y: .value("Сумма", item.total)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.themeAccent)

                    PointMark(
                        x: .value("Месяц", item.month, unit: .month),
                        y: .value("Сумма", item.total)
                    )
                    .foregroundStyle(Color.themeAccent)
                }
                .frame(height: 260)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 1)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.themeAccent.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.system(size: 32))
                .foregroundStyle(Color.themeAccent.opacity(0.85))
            Text("Пока нет данных для статистики")
                .foregroundStyle(Color.themeCaptionOnDark)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(.horizontal)
    }

    private var categoryTotalsForSelectedPeriod: [CategoryTotal] {
        let filtered = filteredTransactions(for: selectedPeriod)
        let grouped = Dictionary(grouping: filtered, by: \.category)

        return grouped
            .map { category, transactions in
                CategoryTotal(
                    category: category,
                    total: transactions.reduce(0) { $0 + $1.amount }
                )
            }
            .sorted { $0.total > $1.total }
    }

    private var lastSixMonthsTotals: [MonthlyTotal] {
        let calendar = Calendar.current
        let now = Date()
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }

        var result: [MonthlyTotal] = []

        for offset in stride(from: 5, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonthStart),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }

            let total = viewModel.transactions
                .filter { $0.date >= monthStart && $0.date < monthEnd }
                .reduce(0) { $0 + $1.amount }

            result.append(MonthlyTotal(month: monthStart, total: total))
        }

        return result
    }

    private func filteredTransactions(for period: StatisticsPeriod) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }

        let startDate: Date
        switch period {
        case .month:
            startDate = currentMonthStart
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -2, to: currentMonthStart) ?? currentMonthStart
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: currentMonthStart) ?? currentMonthStart
        }

        return viewModel.transactions.filter { $0.date >= startDate && $0.date <= now }
    }
}

private enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case month
    case quarter
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "Месяц"
        case .quarter: return "Квартал"
        case .year: return "Год"
        }
    }
}

private struct CategoryTotal: Identifiable {
    let category: TransactionCategory
    let total: Double

    var id: String { category.rawValue }
}

private struct MonthlyTotal: Identifiable {
    let month: Date
    let total: Double

    var id: Date { month }
}

#Preview {
    StatisticsView(viewModel: statisticsPreviewViewModel)
}

@MainActor
private var statisticsPreviewViewModel: ExpenseViewModel {
    let viewModel = ExpenseViewModel()
    let calendar = Calendar.current
    let now = Date()

    viewModel.transactions = [
        Transaction(amount: 1200, category: .food, date: now, note: "Продукты"),
        Transaction(amount: 900, category: .transport, date: now, note: "Такси"),
        Transaction(amount: 2200, category: .shopping, date: calendar.date(byAdding: .day, value: -12, to: now) ?? now, note: "Одежда"),
        Transaction(amount: 1600, category: .cafe, date: calendar.date(byAdding: .month, value: -1, to: now) ?? now, note: "Кафе"),
        Transaction(amount: 3400, category: .bills, date: calendar.date(byAdding: .month, value: -2, to: now) ?? now, note: "Коммунальные"),
        Transaction(amount: 2800, category: .entertainment, date: calendar.date(byAdding: .month, value: -3, to: now) ?? now, note: "Отдых"),
        Transaction(amount: 1500, category: .health, date: calendar.date(byAdding: .month, value: -4, to: now) ?? now, note: "Аптека")
    ]
    viewModel.updateStatistics()
    viewModel.updatePredictions()
    return viewModel
}

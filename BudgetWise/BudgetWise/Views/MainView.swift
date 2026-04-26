import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var isShowingAddTransaction = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            predictionSection
            contentSection
        }
        .padding(.top, 8)
        .navigationTitle("Бюджет")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Добавить") {
                    isShowingAddTransaction = true
                }
            }
        }
        .sheet(isPresented: $isShowingAddTransaction) {
            AddTransactionView(viewModel: viewModel)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailsView(
                transaction: transaction,
                viewModel: viewModel
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Общая сумма")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(viewModel.totalBalance, specifier: "%.2f") руб.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .padding(.horizontal)
    }

    private var predictionSection: some View {
        Text("Прогноз на след. месяц: \(viewModel.predictedExpense(), specifier: "%.2f") руб.")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.transactions.isEmpty {
            VStack(spacing: 12) {
                Text("Нет трат")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Button("Добавить первую") {
                    isShowingAddTransaction = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.transactions) { transaction in
                    Button {
                        selectedTransaction = transaction
                    } label: {
                        TransactionRowView(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteTransaction(transaction)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteTransactions)
            }
            .listStyle(.plain)
        }
    }
}

// Compatibility helpers with the current ExpenseViewModel API.
private extension ExpenseViewModel {
    var totalBalance: Double { totalSpending }

    func predictedExpense() -> Double {
        linearRegressionPrediction
    }
}

#Preview {
    MainView(viewModel: ExpenseViewModel())
}

private struct TransactionDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var selectedCategory: TransactionCategory

    init(transaction: Transaction, viewModel: ExpenseViewModel) {
        self.transaction = transaction
        self.viewModel = viewModel
        _selectedCategory = State(initialValue: transaction.category)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Сумма")
                        Spacer()
                        Text(transaction.amount, format: .currency(code: "RUB"))
                    }

                    HStack {
                        Text("Дата")
                        Spacer()
                        Text(Self.detailsDateFormatter.string(from: transaction.date))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Информация")
                }

                Section {
                    Text(transaction.note.isEmpty ? "Без заметки" : transaction.note)
                } header: {
                    Text("Заметка")
                }

                Section {
                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                } header: {
                    Text("Изменить категорию")
                }
            }
            .navigationTitle("Покупка")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveCategory()
                    }
                    .disabled(selectedCategory == transaction.category)
                }
            }
        }
    }

    private func saveCategory() {
        var updated = transaction
        updated.category = selectedCategory
        viewModel.updateTransaction(updated)
        dismiss()
    }

    private static let detailsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd.MM.yy"
        return formatter
    }()
}

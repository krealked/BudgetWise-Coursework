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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.midnightSky)
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
                .foregroundStyle(Color.themeCaptionOnDark)

            Text("\(viewModel.totalBalance, specifier: "%.2f") руб.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.themeAccent)
        }
        .padding(.horizontal)
    }

    private var predictionSection: some View {
        HStack(spacing: 0) {
            Text("Прогноз на след. месяц: ")
                .foregroundStyle(Color.themeHeadingOnDark)
            Text("\(viewModel.predictedExpense(), specifier: "%.2f") руб.")
                .foregroundStyle(Color.themeAccent)
        }
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
                    .foregroundStyle(Color.themeCaptionOnDark)

                Button("Добавить первую") {
                    isShowingAddTransaction = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.themeAccent)
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
                    .listRowBackground(Color.listCellOnMidnight)
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
            .budgetWiseListChrome()
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
                            .foregroundStyle(Color.themeHeadingOnDark)
                        Spacer()
                        Text(transaction.amount, format: .currency(code: "RUB"))
                            .foregroundStyle(Color.themeAccent)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Дата")
                            .foregroundStyle(Color.themeHeadingOnDark)
                        Spacer()
                        Text(Self.detailsDateFormatter.string(from: transaction.date))
                            .foregroundStyle(Color.themeCaptionOnDark)
                    }
                } header: {
                    Text("Информация")
                        .foregroundStyle(Color.themeHeadingOnDark)
                }

                Section {
                    Text(transaction.note.isEmpty ? "Без заметки" : transaction.note)
                } header: {
                    Text("Заметка")
                        .foregroundStyle(Color.themeHeadingOnDark)
                }

                Section {
                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases) { category in
                            Label {
                                Text(category.rawValue)
                            } icon: {
                                Image(systemName: category.iconName)
                            }
                            .tag(category)
                        }
                    }
                } header: {
                    Text("Изменить категорию")
                        .foregroundStyle(Color.themeHeadingOnDark)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.midnightSky)
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
        .budgetWiseNavigationBar()
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

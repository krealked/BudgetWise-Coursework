import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var isShowingAddTransaction = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        List {
            Section {
                budgetHeaderCard
            }
            .listRowBackground(Color.midnightSky)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)

            contentSection
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .budgetWiseListChrome()
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

    private var budgetHeaderCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("Общая сумма")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeCaptionOnDark)

                Text("\(viewModel.totalBalance, specifier: "%.2f") руб.")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.themeAccent)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 0) {
                Text("Прогноз на след. месяц: ")
                    .foregroundStyle(Color.themeHeadingOnDark)
                Text("\(viewModel.predictedExpense(), specifier: "%.2f") руб.")
                    .foregroundStyle(Color.themeAccent)
            }
            .font(.headline)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.transactions.isEmpty {
            Section {
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
                .listRowBackground(Color.midnightSky)
                .listRowSeparator(.hidden)
            }
        } else {
            ForEach(viewModel.transactions) { transaction in
                Button {
                    selectedTransaction = transaction
                } label: {
                    TransactionRowView(transaction: transaction)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
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

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpenseViewModel

    @State private var amountText: String = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""

    private var amountValue: Double? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var isSaveDisabled: Bool {
        guard let amount = amountValue else { return true }
        return amount <= 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Транзакция") {
                    TextField("Сумма", text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    DatePicker("Дата", selection: $selectedDate, displayedComponents: .date)

                    TextField("Заметка", text: $note)
                }
            }
            .navigationTitle("Добавить транзакцию")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveTransaction()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func saveTransaction() {
        guard let amount = amountValue, amount > 0 else { return }

        let transaction = Transaction(
            amount: amount,
            category: selectedCategory,
            date: selectedDate,
            note: note
        )

        viewModel.addTransaction(transaction)
        dismiss()
    }
}

#Preview {
    AddTransactionView(viewModel: previewViewModel)
}

@MainActor
private var previewViewModel: ExpenseViewModel {
    let viewModel = ExpenseViewModel()
    viewModel.transactions = [
        Transaction(amount: 1200, category: .food, date: Date(), note: "Продукты"),
        Transaction(amount: 450, category: .transport, date: Date(), note: "Метро")
    ]
    viewModel.updateStatistics()
    viewModel.updatePredictions()
    return viewModel
}

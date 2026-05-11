import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var inputByCategory: [TransactionCategory: String] = [:]
    @State private var showExportView = false

    var body: some View {
        List {
            Section {
                ForEach(TransactionCategory.allCases) { category in
                    limitRow(for: category)
                }
            } header: {
                Text("Лимиты по категориям")
            }

            Section {
                HStack {
                    Text("Общий бюджет на месяц")
                    Spacer()
                    Text(totalBudget, format: .currency(code: "RUB"))
                        .fontWeight(.semibold)
                }
            } header: {
                Text("Итого")
            }

            Section {
                Button {
                    showExportView = true
                } label: {
                    Label("Экспорт транзакций в Excel", systemImage: "arrow.up.doc")
                }
            } header: {
                Text("Экспорт")
            }
        }
        .navigationTitle("Настройки")
        .onAppear {
            syncInputWithLimits()
        }
        .sheet(isPresented: $showExportView) {
            ExportView(viewModel: viewModel)
        }
    }

    private func limitRow(for category: TransactionCategory) -> some View {
        HStack(spacing: 10) {
            Text(category.rawValue)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("0", text: binding(for: category))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 96)

            Button("Сохранить") {
                saveLimit(for: category)
            }
            .disabled(isInvalid(category: category))
        }
    }

    private var totalBudget: Double {
        TransactionCategory.allCases.reduce(0) { partial, category in
            partial + viewModel.limit(for: category)
        }
    }

    private func binding(for category: TransactionCategory) -> Binding<String> {
        Binding(
            get: { inputByCategory[category] ?? "" },
            set: { newValue in inputByCategory[category] = newValue }
        )
    }

    private func syncInputWithLimits() {
        var updated: [TransactionCategory: String] = [:]
        for category in TransactionCategory.allCases {
            let value = viewModel.limit(for: category)
            updated[category] = value == 0 ? "" : String(format: "%.2f", value)
        }
        inputByCategory = updated
    }

    private func parsedLimit(for category: TransactionCategory) -> Double? {
        let raw = (inputByCategory[category] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        let normalized = raw.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func isInvalid(category: TransactionCategory) -> Bool {
        guard let parsed = parsedLimit(for: category) else { return true }
        return parsed < 0
    }

    private func saveLimit(for category: TransactionCategory) {
        guard let parsed = parsedLimit(for: category), parsed >= 0 else { return }
        viewModel.setLimit(parsed, for: category)
        inputByCategory[category] = String(format: "%.2f", parsed)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: settingsPreviewViewModel)
    }

    @MainActor
    private static var settingsPreviewViewModel: ExpenseViewModel {
        let viewModel = ExpenseViewModel()
        viewModel.setLimit(12000, for: .food)
        viewModel.setLimit(5000, for: .transport)
        viewModel.setLimit(7000, for: .entertainment)
        return viewModel
    }
}

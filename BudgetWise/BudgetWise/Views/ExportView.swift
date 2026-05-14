import SwiftUI
import UIKit

// MARK: - ExportView

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpenseViewModel

    @State private var startDate: Date = Calendar.current.startOfMonth(for: Date())
    @State private var endDate: Date   = Calendar.current.endOfMonth(for: Date())

    @State private var showShareSheet   = false
    @State private var showEmptyAlert   = false
    @State private var csvURL: URL?

    var body: some View {
        NavigationView {
            Form {
                Section("Период экспорта") {
                    DatePicker(
                        "Начальная дата",
                        selection: $startDate,
                        in: ...endDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Конечная дата",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }

                Section {
                    Button {
                        generateAndShare()
                    } label: {
                        Label("Сформировать CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .tint(Color.themeAccent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.midnightSky)
            .navigationTitle("Экспорт транзакций")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
            .alert("Нет данных", isPresented: $showEmptyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Нет транзакций за выбранный период.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = csvURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
        .budgetWiseNavigationBar()
    }

    // MARK: - Private

    private func generateAndShare() {
        let endOfDay = Calendar.current.endOfDay(for: endDate)
        let slice    = viewModel.transactions(from: startDate, to: endOfDay)

        guard !slice.isEmpty else {
            showEmptyAlert = true
            return
        }

        csvURL        = ExportService.exportToCSV(transactions: slice)
        showShareSheet = csvURL != nil
    }
}

// MARK: - Calendar helpers

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }

    func endOfMonth(for date: Date) -> Date {
        guard let start = self.date(from: dateComponents([.year, .month], from: date)),
              let next  = self.date(byAdding: .month, value: 1, to: start),
              let last  = self.date(byAdding: .second, value: -1, to: next) else {
            return date
        }
        return last
    }

    func endOfDay(for date: Date) -> Date {
        var components        = DateComponents()
        components.hour       = 23
        components.minute     = 59
        components.second     = 59
        return self.date(byAdding: components, to: startOfDay(for: date)) ?? date
    }
}

// MARK: - Preview

#Preview {
    ExportView(viewModel: {
        let vm = ExpenseViewModel()
        vm.transactions = [
            Transaction(amount: 1200, category: .food,      date: Date(), note: "Продукты"),
            Transaction(amount: 350,  category: .transport, date: Date(), note: "Метро")
        ]
        return vm
    }())
}

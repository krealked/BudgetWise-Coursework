//
//  ContentView.swift
//  BudgetWise
//
//  Created by кирюха on 12.01.2026.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: true)],
        animation: .default)
    private var expenses: FetchedResults<Expense>

    var body: some View {
        NavigationView {
            List {
                ForEach(expenses, id: \.objectID) { expense in
                    NavigationLink {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Категория: \(expense.category)")
                            Text("Сумма: \(expense.amount, format: .currency(code: "RUB"))")
                            Text("Дата: \(expense.date, formatter: itemFormatter)")
                            if !expense.note.isEmpty {
                                Text("Примечание: \(expense.note)")
                            }
                        }
                        .padding()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(expense.category)
                                .font(.headline)
                            Text(expense.amount, format: .currency(code: "RUB"))
                                .font(.subheadline)
                            Text(expense.date, formatter: itemFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteExpenses)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addExpense) {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
            }
            Text("Выберите расход")
        }
    }

    private func addExpense() {
        withAnimation {
            let newExpense = Expense(context: viewContext)
            newExpense.id = UUID()
            newExpense.amount = 0.0
            newExpense.category = "Новая категория"
            newExpense.date = Date()
            newExpense.note = ""

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            offsets.map { expenses[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

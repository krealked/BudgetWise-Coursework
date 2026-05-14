//
//  BudgetWiseApp.swift
//  BudgetWise
//
//  Created by кирюха on 12.01.2026.
//

import SwiftUI
import CoreData

@main
struct BudgetWiseApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        BudgetWiseAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .budgetWiseRootAppearance()
        }
    }
}

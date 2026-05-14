//
//  ContentView.swift
//  BudgetWise
//
//  Created by кирюха on 12.01.2026.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        MainContentView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.midnightSky.ignoresSafeArea())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .budgetWiseRootAppearance()
    }
}

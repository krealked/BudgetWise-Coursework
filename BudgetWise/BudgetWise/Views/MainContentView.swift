import SwiftUI

struct MainContentView: View {
    @StateObject private var viewModel = ExpenseViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                MainView(viewModel: viewModel)
            }
            .budgetWiseNavigationBar()
            .tabItem {
                Label("Главная", systemImage: "list.bullet")
            }

            NavigationStack {
                StatisticsView(viewModel: viewModel)
                    .navigationTitle("Статистика")
            }
            .budgetWiseNavigationBar()
            .tabItem {
                Label("Статистика", systemImage: "chart.pie")
            }

            NavigationStack {
                SettingsView(viewModel: viewModel)
            }
            .budgetWiseNavigationBar()
            .tabItem {
                Label("Настройки", systemImage: "gear")
            }
        }
        .background(Color.midnightSky)
        .budgetWiseTabBar()
        .toolbar(.visible, for: .tabBar)
    }
}

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .budgetWiseRootAppearance()
    }
}

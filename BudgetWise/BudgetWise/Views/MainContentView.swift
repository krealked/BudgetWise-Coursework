import SwiftUI

struct MainContentView: View {
    @StateObject private var viewModel = ExpenseViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                MainView(viewModel: viewModel)
            }
                .tabItem {
                    Label("Главная", systemImage: "list.bullet")
                }

            NavigationStack {
                StatisticsView(viewModel: viewModel)
                    .navigationTitle("Статистика")
            }
                .tabItem {
                    Label("Статистика", systemImage: "chart.pie")
                }

            NavigationStack {
                SettingsView(viewModel: viewModel)
            }
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
        .toolbar(.visible, for: .tabBar)
    }
}

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}

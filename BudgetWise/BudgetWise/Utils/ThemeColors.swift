//
//  ThemeColors.swift
//  BudgetWise
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color + BudgetWise theme

extension Color {
    /// Pantone Midnight Sky (#16151D) — фон экранов, списков, таббара.
    static let midnightSky = Color(rgb: 0x16151D)

    /// Обратная совместимость с прежним именем.
    static let themeMidnightSky = Color.midnightSky

    /// Pantone Neon Nephrite (#3D8C28) — кнопки, выделения, активные иконки таббара, индикаторы.
    static let themeNeonNephrite = Color(rgb: 0x3D8C28)

    /// Основной фон приложения.
    static var themeBackground: Color { midnightSky }

    /// Акцентный цвет (совпадает с глобальным `.tint`).
    static var themeAccent: Color { themeNeonNephrite }

    /// Слегка приподнятая поверхность (строки списка, карточки).
    static let themeSurfaceElevated = Color(rgb: 0x1E1D27)

    /// Заголовки на тёмном фоне (читаемый контраст к Midnight Sky).
    static var themeHeadingOnDark: Color { Color.white.opacity(0.96) }

    /// Вторичный текст на тёмном фоне.
    static var themeCaptionOnDark: Color { Color.white.opacity(0.56) }

    /// Заголовки на светлых панелях (например, поверх материала в светлой схеме превью).
    static var themeHeadingOnLight: Color { midnightSky }

    /// Фон ячейки списка на `midnightSky` (полупрозрачная светлая плёнка).
    static var listCellOnMidnight: Color { Color.white.opacity(0.08) }

    init(rgb: UInt32, alpha: Double = 1) {
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Общий вид навигации и таббара

extension View {
    /// Тёмная палитра, акцент и фон под safe area (корень `WindowGroup`).
    func budgetWiseRootAppearance() -> some View {
        self
            .preferredColorScheme(.dark)
            .tint(Color.themeAccent)
            .background(Color.midnightSky.ignoresSafeArea())
    }

    func budgetWiseNavigationBar() -> some View {
        self
            .toolbarBackground(Color.midnightSky, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func budgetWiseTabBar() -> some View {
        self
            .toolbarBackground(Color.midnightSky, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
    }

    /// Скрывает системный фон списка/формы; подложка — `midnightSky`. Для `List` задайте `.listStyle(.plain)` отдельно.
    func budgetWiseListChrome() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.midnightSky)
    }
}

// MARK: - UIKit (TabBar / глобальный акцент вкладок)

enum BudgetWiseAppearance {
    private static var didConfigure = false

    /// Вызывать один раз при старте приложения (например, из `App.init()`).
    static func configure() {
        #if canImport(UIKit)
        guard !didConfigure else { return }
        didConfigure = true

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Color.midnightSky)

        let accent = UIColor(Color.themeAccent)
        tab.stackedLayoutAppearance.selected.iconColor = accent
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accent]
        let muted = UIColor.white.withAlphaComponent(0.45)
        tab.stackedLayoutAppearance.normal.iconColor = muted
        tab.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: muted]

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = muted
        #endif
    }
}

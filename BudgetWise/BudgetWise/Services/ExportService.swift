import Foundation
import SwiftUI
import UIKit

/// Генерация CSV из транзакций и шаринг файла.
public final class ExportService {

    private init() {}

    // MARK: - CSV generation

    /// Формирует CSV-строку из транзакций.
    /// Заголовки: "Дата;Сумма;Категория;Заметка". Разделитель — `;` (корректно открывается в Excel с русской локалью).
    public static func generateCSV(from transactions: [Transaction]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.locale = Locale(identifier: "ru_RU")

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "ru_RU")
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2

        let header = ["Дата", "Сумма", "Категория", "Заметка"]
            .map(csvEscape)
            .joined(separator: ";")

        let rows: [String] = transactions.map { tx in
            let dateText     = dateFormatter.string(from: tx.date)
            let amountText   = numberFormatter.string(from: NSNumber(value: tx.amount))
                               ?? String(format: "%.2f", tx.amount)
            let categoryText = tx.category.rawValue
            let noteText     = tx.note

            return [dateText, amountText, categoryText, noteText]
                .map(csvEscape)
                .joined(separator: ";")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - File export

    /// Записывает CSV во временную директорию и возвращает URL.
    /// - Returns: URL созданного файла или `nil`, если файл создать не удалось.
    public static func exportToCSV(transactions: [Transaction]) -> URL? {
        let csvString = generateCSV(from: transactions)
        let fileName  = "budgetwise-transactions-\(Int(Date().timeIntervalSince1970)).csv"
        let url       = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            // UTF-8 BOM — Excel откроет кириллицу без перекодировки.
            let bom  = Data([0xEF, 0xBB, 0xBF])
            let utf8 = csvString.data(using: .utf8) ?? Data()
            try (bom + utf8).write(to: url, options: .atomic)
            return url
        } catch {
            print("ExportService: не удалось создать CSV — \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Share (UIKit)

    /// Показывает `UIActivityViewController` с CSV-файлом.
    public static func exportAndShare(transactions: [Transaction], from viewController: UIViewController) {
        guard let url = exportToCSV(transactions: transactions) else { return }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        // iPad: предотвращаем краш без popover anchor.
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    /// Алиас для совместимости с более ранней версией сервиса.
    public static func shareCSV(transactions: [Transaction], from viewController: UIViewController) {
        exportAndShare(transactions: transactions, from: viewController)
    }

    // MARK: - SwiftUI wrapper

    /// Кнопка "Экспорт CSV", которая находит top-most `UIViewController` и вызывает `exportAndShare`.
    public static func shareSheet(transactions: [Transaction]) -> some View {
        Button("Экспорт CSV") {
            guard let topVC = topViewController() else { return }
            exportAndShare(transactions: transactions, from: topVC)
        }
    }

    // MARK: - Private helpers

    private static func csvEscape(_ value: String) -> String {
        let needsQuotes = value.contains(";") || value.contains("\"")
                       || value.contains("\n") || value.contains("\r")
        if !needsQuotes { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC: UIViewController? = base ?? keyWindow()?.rootViewController
        guard let baseVC else { return nil }

        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = baseVC.presentedViewController {
            return topViewController(base: presented)
        }
        return baseVC
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

/*
 Примеры вызова:

 // UIKit:
 ExportService.exportAndShare(transactions: viewModel.transactions, from: self)

 // SwiftUI (вставляется прямо в body):
 ExportService.shareSheet(transactions: viewModel.transactions)

 // Только строка CSV (без шаринга):
 let csv = ExportService.generateCSV(from: viewModel.transactions)
 */

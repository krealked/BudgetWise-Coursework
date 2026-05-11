import SwiftUI
import UserNotifications

/// Локальные уведомления о превышении лимита бюджета.
public final class NotificationService: NSObject {

    public static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    /// Запрашивает у пользователя право показывать уведомления.
    public func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("NotificationService: ошибка запроса разрешения — \(error.localizedDescription)")
                return
            }
            if !granted {
                print("NotificationService: разрешение на уведомления не выдано")
            }
        }
    }

    private func performWhenAuthorized(_ work: @escaping () -> Void) {
        notificationCenter.getNotificationSettings { settings in
            let ok: Bool
            if #available(iOS 12.0, *) {
                ok = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral
            } else {
                ok = settings.authorizationStatus == .authorized
            }
            guard ok else {
                print("NotificationService: уведомления отключены, отправка пропущена")
                return
            }
            work()
        }
    }

    // MARK: - Budget warning

    /// Немедленное (с задержкой 1 с для триггера) локальное уведомление о превышении лимита.
    public func sendBudgetWarning(for category: String, spent: Double, limit: Double) {
        performWhenAuthorized { [weak self] in
            guard let self = self else { return }

            let body = "Превышение лимита по категории \(category): потрачено \(spent) из \(limit) руб."

            let content = UNMutableNotificationContent()
            content.title = "Бюджет"
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let id = "budget.warning.\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("NotificationService: не удалось добавить уведомление — \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Weekly summary (заглушка)

    /// Планирует еженедельное уведомление с суммой расходов (реализация — позже).
    public func scheduleWeeklySummary(transactions: [Transaction]) {
        _ = transactions
        // Заглушка: сюда можно добавить UNCalendarNotificationTrigger (например, каждое воскресенье 10:00)
        // и тело с суммой transactions.reduce(0) { $0 + $1.amount }.
    }
}

/*
 Пример использования:

 NotificationService.shared.requestAuthorization()

 // После того как пользователь выдал разрешение (и при превышении лимита):
 NotificationService.shared.sendBudgetWarning(
     for: "Продукты",
     spent: 12500,
     limit: 10000
 )

 NotificationService.shared.scheduleWeeklySummary(transactions: viewModel.transactions)
 */

import UserNotifications

/// Schedules daily practice reminder notifications.
enum NotificationManager {

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleDailyReminder(hour: Int = 19, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-practice"])

        let content = UNMutableNotificationContent()
        content.title = "🎸 Hora de practicar"
        content.body = "Unos minutos al día hacen toda la diferencia. ¡Abre GuitarMBS!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-practice", content: content, trigger: trigger)

        center.add(request)
    }

    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-practice"])
    }
}

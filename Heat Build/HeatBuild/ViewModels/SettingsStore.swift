import SwiftUI
import UserNotifications

class SettingsStore: ObservableObject {
    @AppStorage("themeMode") var themeMode: String = "system"
    @AppStorage("units") var units: String = "metric"
    @AppStorage("currency") var currency: String = "EUR"
    @AppStorage("notifyDeadlines") var notifyDeadlines: Bool = true
    @AppStorage("notifyWarnings") var notifyWarnings: Bool = true
    @AppStorage("notifyWeeklyCheck") var notifyWeeklyCheck: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var temperatureUnit: String { units == "metric" ? "°C" : "°F" }
    var areaUnit: String { units == "metric" ? "m²" : "ft²" }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleDeadlineNotification(title: String, date: Date) {
        guard notifyDeadlines else { return }
        let content = UNMutableNotificationContent()
        content.title = "Heat Build — Deadline"
        content.body = title
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: "deadline_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    func scheduleWeeklyCheck() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_check"])
        guard notifyWeeklyCheck else { return }
        let content = UNMutableNotificationContent()
        content.title = "Heat Build — Weekly Check"
        content.body = "Time to check your climate points and update records."
        content.sound = .default
        var comps = DateComponents()
        comps.weekday = 2; comps.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: "weekly_check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func exportData(from store: AppStore) -> String {
        var lines: [String] = ["Heat Build Export — \(Date().formatted())"]
        lines.append("\n=== PROJECTS ===")
        for p in store.projects { lines.append("• \(p.name) [\(p.status.rawValue)] — \(p.address)") }
        lines.append("\n=== RECORDS ===")
        for r in store.records { lines.append("• \(r.title) [\(r.category.rawValue)] \(r.value) — \(r.status.rawValue)") }
        lines.append("\n=== TASKS ===")
        for t in store.tasks { lines.append("• \(t.title) [\(t.priority.rawValue)] — \(t.isCompleted ? "Done" : "Open")") }
        return lines.joined(separator: "\n")
    }
}

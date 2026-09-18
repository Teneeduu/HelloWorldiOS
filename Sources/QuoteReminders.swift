import Foundation
import UserNotifications

/// Pushes a quote to the lock screen on a daily schedule.
final class QuoteReminders: ObservableObject {
    @Published private(set) var permission: UNAuthorizationStatus = .notDetermined

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    @Published var morning: Date {
        didSet { UserDefaults.standard.set(morning, forKey: Self.morningKey) }
    }

    @Published var evening: Date {
        didSet { UserDefaults.standard.set(evening, forKey: Self.eveningKey) }
    }

    private static let enabledKey = "reminders.enabled"
    private static let morningKey = "reminders.morning"
    private static let eveningKey = "reminders.evening"

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        morning = UserDefaults.standard.object(forKey: Self.morningKey) as? Date ?? Self.time(hour: 8, minute: 0)
        evening = UserDefaults.standard.object(forKey: Self.eveningKey) as? Date ?? Self.time(hour: 22, minute: 0)
        refreshPermission()
    }

    private static func time(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    func refreshPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permission = settings.authorizationStatus
            }
        }
    }

    func enable(using library: QuoteLibrary) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    self.refreshPermission()
                    return
                }
                self.isEnabled = true
                self.reschedule(using: library)
            }
        }
    }

    /// Called on launch and whenever the schedule changes, which also rotates
    /// the quote each notification carries. Permission is read fresh every
    /// time, since the stored value may not have arrived yet at launch.
    func reschedule(using library: QuoteLibrary) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permission = settings.authorizationStatus

                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                guard self.isEnabled, settings.authorizationStatus == .authorized else { return }

                self.schedule(at: self.morning, id: "quote.morning", title: "早安", using: library)
                self.schedule(at: self.evening, id: "quote.evening", title: "晚安", using: library)
            }
        }
    }

    private func schedule(at date: Date, id: String, title: String, using library: QuoteLibrary) {
        guard let quote = library.random() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = quote.source.isEmpty ? quote.text : "\(quote.text)\n—— \(quote.source)"
        content.sound = .default

        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

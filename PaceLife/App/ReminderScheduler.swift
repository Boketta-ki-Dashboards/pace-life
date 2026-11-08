import Foundation
import UserNotifications
import PaceLifeCore

/// Adapter around local notifications. Only Sendable values cross the boundary;
/// the system objects never leave the completion handlers.
protocol ReminderScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func isDenied() async -> Bool
    func sync(_ reminders: [ScheduledReminder], body: String) async
}

struct NotificationReminderScheduler: ReminderScheduling {
    static let prefix = "pace.reminder."

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func isDenied() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus == .denied)
            }
        }
    }

    /// Replaces every pending Pace Life reminder with the given weekly requests.
    func sync(_ reminders: [ScheduledReminder], body: String) async {
        let existing: [String] = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: existing)
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = body
            content.sound = .default
            var components = DateComponents()
            components.weekday = reminder.weekday; components.hour = reminder.hour; components.minute = reminder.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                UNUserNotificationCenter.current().add(request) { _ in continuation.resume() }
            }
        }
    }
}

/// UI tests never touch the real notification center or permission prompts.
struct DisabledReminderScheduler: ReminderScheduling {
    func requestAuthorization() async -> Bool { false }
    func isDenied() async -> Bool { false }
    func sync(_ reminders: [ScheduledReminder], body: String) async {}
}

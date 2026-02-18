import Foundation
import UserNotifications

/// Legacy scheduler using UNUserNotifications. Active on iOS 17–25.
/// On iOS 26+ AlarmKitService is used instead.
final class NotificationService: AlarmScheduling {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Scheduling

    func scheduleAlarm(_ alarm: AlarmModel) async {
        // Cancel any existing notification for this alarm first
        cancelAlarm(alarm)

        guard alarm.isEnabled else { return }

        let content = makeContent(for: alarm)

        if alarm.alarmType == .daily {
            await scheduleDailyAlarm(alarm, content: content)
        } else {
            await scheduleFutureAlarm(alarm, content: content)
        }
    }

    private func scheduleDailyAlarm(_ alarm: AlarmModel, content: UNMutableNotificationContent) async {
        if alarm.repeatDays.isEmpty {
            // One-shot: next occurrence of this time
            var dateComponents = DateComponents()
            dateComponents.hour = alarm.hour
            dateComponents.minute = alarm.minute
            dateComponents.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: alarm.notificationIdentifier,
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
                print("[NotificationService] Scheduled one-shot daily alarm \(alarm.notificationIdentifier) at \(alarm.hour):\(alarm.minute)")
            } catch {
                print("[NotificationService] Failed to schedule alarm: \(error)")
            }
        } else {
            // Repeating: one notification per day of week
            for (index, day) in alarm.repeatDays.enumerated() {
                var dateComponents = DateComponents()
                dateComponents.weekday = day
                dateComponents.hour = alarm.hour
                dateComponents.minute = alarm.minute
                dateComponents.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "\(alarm.notificationIdentifier)_\(index)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                do {
                    try await center.add(request)
                    print("[NotificationService] Scheduled repeating alarm \(identifier) weekday=\(day) at \(alarm.hour):\(alarm.minute)")
                } catch {
                    print("[NotificationService] Failed to schedule repeating alarm \(identifier): \(error)")
                }
            }
        }
    }

    private func scheduleFutureAlarm(_ alarm: AlarmModel, content: UNMutableNotificationContent) async {
        guard let localFireDate = alarm.localFireDate else { return }

        let calendar = Calendar.current
        let repeats = alarm.futureRepeatOption != .none

        var dateComponents: DateComponents

        switch alarm.futureRepeatOption {
        case .none:
            // One-shot: full date components
            dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: localFireDate
            )
        case .weekly:
            // Repeat weekly: weekday + time
            dateComponents = calendar.dateComponents(
                [.weekday, .hour, .minute],
                from: localFireDate
            )
        case .monthly:
            // Repeat monthly: day of month + time
            dateComponents = calendar.dateComponents(
                [.day, .hour, .minute],
                from: localFireDate
            )
        case .yearly:
            // Repeat yearly: month + day + time
            dateComponents = calendar.dateComponents(
                [.month, .day, .hour, .minute],
                from: localFireDate
            )
        }

        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(
            identifier: alarm.notificationIdentifier,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
            print("[NotificationService] Scheduled future alarm \(alarm.notificationIdentifier) at \(localFireDate)")
        } catch {
            print("[NotificationService] Failed to schedule future alarm: \(error)")
        }
    }

    // MARK: - Cancel

    func cancelAlarm(_ alarm: AlarmModel) {
        // Cancel all possible identifiers for this alarm
        var identifiers = [alarm.notificationIdentifier]
        for i in 0..<7 {
            identifiers.append("\(alarm.notificationIdentifier)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Notification Count

    func pendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }

    // MARK: - Content

    private func makeContent(for alarm: AlarmModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "UNMUTE"
        content.body = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive

        // Use our bundled 30-second alarm tone (.caf file in app bundle).
        // Falls back to system default if file is missing.
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_tone.caf"))

        // Add snooze action info in userInfo
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "isSnoozeEnabled": alarm.isSnoozeEnabled,
            "snoozeDuration": alarm.snoozeDuration.rawValue
        ]

        return content
    }

    // MARK: - Notification Categories (for snooze/dismiss actions)

    func registerCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: []
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    // MARK: - Snooze

    func scheduleSnooze(alarmId: String, duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "UNMUTE"
        content.body = "Snoozed Alarm"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_tone.caf"))
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(duration * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "snooze_\(alarmId)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
}

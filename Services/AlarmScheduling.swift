import Foundation

/// Abstracts over AlarmKit (iOS 26+) and the legacy UNUserNotifications fallback.
/// Both implementations are drop-in replacements for each other.
protocol AlarmScheduling: AnyObject {

    /// Request the appropriate system permission for this scheduler.
    /// Returns true if permission was granted.
    func requestPermission() async -> Bool

    /// Schedule (or re-schedule) a single alarm.
    func scheduleAlarm(_ alarm: AlarmModel) async

    /// Cancel all scheduled requests for a given alarm.
    func cancelAlarm(_ alarm: AlarmModel)

    /// Number of currently pending alarm requests (used for limit warnings).
    func pendingNotificationCount() async -> Int

    /// Schedule a snooze for `duration` minutes from now.
    func scheduleSnooze(alarmId: String, duration: Int)
}

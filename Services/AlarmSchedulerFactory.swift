import Foundation

/// Returns the best available AlarmScheduling implementation.
///
/// - iOS 26+   → AlarmKitService  (native alarm UI, bypasses Focus/DND, no 64-alarm cap)
/// - iOS 17–25 → NotificationService  (UNUserNotifications fallback)
enum AlarmSchedulerFactory {
    static func make() -> AlarmScheduling {
        if #available(iOS 26.0, *) {
            return AlarmKitService.shared
        }
        return NotificationService.shared
    }
}

import SwiftUI
import SwiftData
import UserNotifications

@main
struct UnmuteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AlarmListView()
        }
        .modelContainer(for: AlarmModel.self)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // On iOS 26+ AlarmKit manages its own delegate; we still register ours
        // so the UNUserNotifications fallback path keeps working on older OS.
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notification banner even when app is in foreground (iOS < 26 only)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle legacy notification actions: snooze / dismiss (iOS < 26 only).
    // On iOS 26+ AlarmKit handles snooze natively and this delegate is not called
    // for AlarmKit alarms.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            if let alarmId = userInfo["alarmId"] as? String,
               let duration = userInfo["snoozeDuration"] as? Int {
                NotificationService.shared.scheduleSnooze(alarmId: alarmId, duration: duration)
            }
        case "DISMISS_ACTION":
            break
        default:
            // Default tap — snooze if enabled
            if let isSnoozeEnabled = userInfo["isSnoozeEnabled"] as? Bool,
               isSnoozeEnabled,
               let alarmId = userInfo["alarmId"] as? String,
               let duration = userInfo["snoozeDuration"] as? Int {
                NotificationService.shared.scheduleSnooze(alarmId: alarmId, duration: duration)
            }
        }

        completionHandler()
    }
}

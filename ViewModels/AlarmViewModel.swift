import Foundation
import SwiftData
import SwiftUI

@Observable
final class AlarmViewModel {
    // Picks AlarmKitService on iOS 26+, NotificationService on older OS
    private let scheduler: AlarmScheduling = AlarmSchedulerFactory.make()

    // Convenience: direct access to NotificationService for category registration
    // and snooze handling (only active on iOS < 26)
    private var notificationService: NotificationService? {
        scheduler as? NotificationService
    }

    var showNotificationDeniedAlert = false
    /// Only shown on iOS < 26 where the 64-notification cap applies
    var showLimitWarning = false
    var pendingCount = 0

    // MARK: - Permission

    func requestNotificationPermission() async {
        let granted = await scheduler.requestPermission()
        if !granted {
            await MainActor.run {
                showNotificationDeniedAlert = true
            }
        }
    }

    func setupNotificationCategories() {
        // Category registration is only needed for the legacy notification path
        notificationService?.registerCategories()
    }

    // MARK: - CRUD

    func addAlarm(_ alarm: AlarmModel, context: ModelContext) async {
        context.insert(alarm)
        try? context.save()
        await scheduleAlarm(alarm)
        await checkNotificationLimit()
    }

    func updateAlarm(_ alarm: AlarmModel, context: ModelContext) async {
        try? context.save()
        await scheduleAlarm(alarm)
        await checkNotificationLimit()
    }

    func deleteAlarm(_ alarm: AlarmModel, context: ModelContext) {
        scheduler.cancelAlarm(alarm)
        context.delete(alarm)
        try? context.save()
    }

    func toggleAlarm(_ alarm: AlarmModel, context: ModelContext) async {
        alarm.isEnabled.toggle()
        try? context.save()

        if alarm.isEnabled {
            await scheduleAlarm(alarm)
        } else {
            scheduler.cancelAlarm(alarm)
        }
        await checkNotificationLimit()
    }

    // MARK: - Scheduling

    private func scheduleAlarm(_ alarm: AlarmModel) async {
        await scheduler.scheduleAlarm(alarm)
    }

    func rescheduleAllAlarms(_ alarms: [AlarmModel]) async {
        for alarm in alarms where alarm.isEnabled {
            await scheduler.scheduleAlarm(alarm)
        }
    }

    // MARK: - Notification Limit (iOS < 26 only)

    private func checkNotificationLimit() async {
        let count = await scheduler.pendingNotificationCount()
        await MainActor.run {
            pendingCount = count
            // AlarmKitService always returns 0, so this warning only fires on iOS < 26
            showLimitWarning = count >= 60
        }
    }

    func isAtNotificationLimit() async -> Bool {
        let count = await scheduler.pendingNotificationCount()
        return count >= 64
    }

    // MARK: - Auto-disable fired one-shot future alarms

    func disableFiredAlarms(_ alarms: [AlarmModel], context: ModelContext) {
        let now = Date()
        for alarm in alarms {
            guard alarm.isEnabled,
                  alarm.alarmType == .future,
                  alarm.futureRepeatOption == .none,
                  let fireDate = alarm.localFireDate,
                  fireDate < now else { continue }

            alarm.isEnabled = false
        }
        try? context.save()
    }
}

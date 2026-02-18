import Foundation
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
final class AlarmKitService: AlarmScheduling {

    static let shared = AlarmKitService()
    private let manager = AlarmManager.shared
    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            return state == .authorized
        } catch {
            print("[AlarmKitService] Permission error: \(error)")
            return false
        }
    }

    // MARK: - Schedule

    func scheduleAlarm(_ alarm: AlarmModel) async {
        cancelAlarm(alarm)
        guard alarm.isEnabled else { return }

        // If AlarmKit isn't entitled yet, fall back to notifications silently.
        let authorized = await requestPermission()
        guard authorized else {
            print("[AlarmKitService] Not authorized — falling back to NotificationService")
            await NotificationService.shared.scheduleAlarm(alarm)
            return
        }

        do {
            let schedules = makeSchedules(for: alarm)
            for (index, schedule) in schedules.enumerated() {
                let id = scheduleID(for: alarm, index: index)

                let title = LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "UNMUTE" : alarm.label)
                let snoozeButton: AlarmButton? = alarm.isSnoozeEnabled
                    ? AlarmButton(text: "Snooze", textColor: .white, systemImageName: "alarm")
                    : nil
                let stopButton = AlarmButton(text: "Stop", textColor: .red, systemImageName: "stop.fill")

                let alertContent: AlarmPresentation.Alert
                if #available(iOS 26.1, *) {
                    alertContent = AlarmPresentation.Alert(
                        title: title,
                        secondaryButton: snoozeButton,
                        secondaryButtonBehavior: alarm.isSnoozeEnabled ? .countdown : nil
                    )
                } else {
                    alertContent = AlarmPresentation.Alert(
                        title: title,
                        stopButton: stopButton,
                        secondaryButton: snoozeButton,
                        secondaryButtonBehavior: alarm.isSnoozeEnabled ? .countdown : nil
                    )
                }
                // Widget extension handles the countdown Live Activity UI.
                let countdownPresentation = alarm.isSnoozeEnabled
                    ? AlarmPresentation.Countdown(
                        title: LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "UNMUTE" : alarm.label),
                        pauseButton: nil
                      )
                    : nil
                let presentation = AlarmPresentation(alert: alertContent, countdown: countdownPresentation)
                let attributes = AlarmAttributes(
                    presentation: presentation,
                    metadata: UnmuteAlarmMetadata(
                        alarmId: alarm.id.uuidString,
                        snoozeDuration: alarm.snoozeDuration.rawValue
                    ),
                    tintColor: Color.orange
                )

                let snoozeDuration = alarm.isSnoozeEnabled
                    ? Alarm.CountdownDuration(preAlert: nil, postAlert: TimeInterval(alarm.snoozeDuration.rawValue * 60))
                    : nil

                let configuration = AlarmManager.AlarmConfiguration(
                    countdownDuration: snoozeDuration,
                    schedule: schedule,
                    attributes: attributes,
                    stopIntent: nil,
                    secondaryIntent: nil,
                    sound: .named("alarm_tone.caf")
                )

                try await manager.schedule(id: id, configuration: configuration)
            }
        } catch {
            print("[AlarmKitService] Schedule error for '\(alarm.label)': \(error)")
        }
    }

    // MARK: - Cancel

    func cancelAlarm(_ alarm: AlarmModel) {
        for id in allIDs(for: alarm) {
            try? manager.cancel(id: id)
        }
    }

    // MARK: - Pending count
    // AlarmKit has no 64-alarm cap — return 0 to suppress the warning UI.
    func pendingNotificationCount() async -> Int { 0 }

    // MARK: - Snooze
    // AlarmKit handles its own UI; this satisfies the protocol but is never called.
    func scheduleSnooze(alarmId: String, duration: Int) {}

    // MARK: - Private helpers

    private func scheduleID(for alarm: AlarmModel, index: Int) -> Alarm.ID {
        let seed = "\(alarm.notificationIdentifier)_\(index)"
        return UUID(uuidString: stableUUID(from: seed)) ?? UUID()
    }

    private func allIDs(for alarm: AlarmModel) -> [Alarm.ID] {
        let count = alarm.alarmType == .daily && !alarm.repeatDays.isEmpty
            ? alarm.repeatDays.count
            : 1
        return (0..<count).map { scheduleID(for: alarm, index: $0) }
    }

    private func makeSchedules(for alarm: AlarmModel) -> [Alarm.Schedule] {
        let time = Alarm.Schedule.Relative.Time(hour: alarm.hour, minute: alarm.minute)

        switch alarm.alarmType {
        case .daily:
            if alarm.repeatDays.isEmpty {
                return [.relative(.init(time: time, repeats: .never))]
            } else {
                // One schedule per weekday
                return alarm.repeatDays.map { day in
                    let weekday = localeWeekday(from: day)
                    return .relative(.init(time: time, repeats: .weekly([weekday])))
                }
            }

        case .future:
            guard let fireDate = alarm.localFireDate else {
                return [.relative(.init(time: time, repeats: .never))]
            }
            switch alarm.futureRepeatOption {
            case .none:
                return [.fixed(fireDate)]
            case .weekly:
                let weekdayInt = Calendar.current.component(.weekday, from: fireDate)
                let weekday = localeWeekday(from: weekdayInt)
                return [.relative(.init(time: time, repeats: .weekly([weekday])))]
            case .monthly, .yearly:
                // AlarmKit only supports weekly repeats natively;
                // schedule as one-shot and reschedule from app on next launch.
                return [.fixed(fireDate)]
            }
        }
    }

    private func localeWeekday(from weekday: Int) -> Locale.Weekday {
        // weekday: 1=Sun, 2=Mon... 7=Sat  →  Locale.Weekday
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }

    /// Deterministic UUID derived from a seed string so cancel/reschedule always use the same IDs.
    private func stableUUID(from seed: String) -> String {
        var hash = seed.utf8.reduce(UInt64(14695981039346656037)) { acc, byte in
            (acc ^ UInt64(byte)) &* 1099511628211
        }
        let a = UInt32(hash & 0xFFFFFFFF); hash >>= 32
        let b = UInt16(hash & 0xFFFF); hash >>= 16
        let c = UInt16((hash & 0x0FFF) | 0x4000); hash >>= 16
        let d = UInt16((hash & 0x3FFF) | 0x8000)
        let e = seed.utf8.prefix(6).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        return String(format: "%08X-%04X-%04X-%04X-%012X", a, b, c, d, e)
    }
}

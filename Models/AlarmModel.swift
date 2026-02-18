import Foundation
import SwiftData

enum AlarmType: String, Codable {
    case daily
    case future
}

enum RepeatOption: String, Codable, CaseIterable, Identifiable {
    case none = "Never"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
}

enum SnoozeDuration: Int, Codable, CaseIterable, Identifiable {
    case five = 5
    case nine = 9
    case fifteen = 15

    var id: Int { rawValue }

    var label: String {
        "\(rawValue) minutes"
    }
}

@Model
final class AlarmModel {
    var id: UUID
    var label: String
    var alarmType: AlarmType

    // Time components (used by both daily and future)
    var hour: Int
    var minute: Int

    // Daily alarm: which days to repeat (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    // Empty means one-shot (next occurrence)
    var repeatDays: [Int]

    // Future alarm: specific date
    var targetDate: Date?

    // Future alarm: repeat option
    var futureRepeatOption: RepeatOption

    // Future alarm: timezone identifier (e.g., "Asia/Kolkata")
    var timezoneIdentifier: String?

    // Alarm settings
    var soundName: String
    var isSnoozeEnabled: Bool
    var snoozeDuration: SnoozeDuration
    var isEnabled: Bool

    // Metadata
    var createdAt: Date
    var notificationIdentifier: String

    init(
        label: String = "Alarm",
        alarmType: AlarmType = .daily,
        hour: Int = 8,
        minute: Int = 0,
        repeatDays: [Int] = [],
        targetDate: Date? = nil,
        futureRepeatOption: RepeatOption = .none,
        timezoneIdentifier: String? = nil,
        soundName: String = "default",
        isSnoozeEnabled: Bool = true,
        snoozeDuration: SnoozeDuration = .nine,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.label = label
        self.alarmType = alarmType
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.targetDate = targetDate
        self.futureRepeatOption = futureRepeatOption
        self.timezoneIdentifier = timezoneIdentifier
        self.soundName = soundName
        self.isSnoozeEnabled = isSnoozeEnabled
        self.snoozeDuration = snoozeDuration
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.notificationIdentifier = UUID().uuidString
    }

    // MARK: - Computed Properties

    /// The timezone for this alarm (local if not set)
    var timeZone: TimeZone {
        if let id = timezoneIdentifier {
            return TimeZone(identifier: id) ?? .current
        }
        return .current
    }

    /// The local fire date/time for display purposes
    var localFireDate: Date? {
        guard alarmType == .future, let targetDate = targetDate else { return nil }

        let sourceTimeZone = timeZone
        let localTimeZone = TimeZone.current

        // Get the date components in the source timezone
        var calendar = Calendar.current
        calendar.timeZone = sourceTimeZone
        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        components.hour = hour
        components.minute = minute
        components.second = 0

        // Create the date in the source timezone
        guard let sourceDate = calendar.date(from: components) else { return nil }

        // The Date object is already in UTC internally, so it represents
        // the correct absolute moment. Just return it.
        return sourceDate
    }

    /// Formatted time string (e.g., "7:30 AM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = alarmType == .future ? timeZone : .current

        var calendar = Calendar.current
        calendar.timeZone = alarmType == .future ? timeZone : .current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }

    /// Formatted local fire time for future alarms (e.g., "Rings at 2:00 AM your time")
    var formattedLocalFireTime: String? {
        guard alarmType == .future,
              timezoneIdentifier != nil,
              timezoneIdentifier != TimeZone.current.identifier,
              let fireDate = localFireDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = .current
        return "Rings at \(formatter.string(from: fireDate)) your time"
    }

    /// Formatted date for future alarms (e.g., "Feb 26, 2026")
    var formattedDate: String? {
        guard alarmType == .future, let targetDate = targetDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = timeZone
        return formatter.string(from: targetDate)
    }

    /// Short repeat description
    var repeatDescription: String {
        if alarmType == .daily {
            if repeatDays.isEmpty {
                return ""
            }
            let daySymbols = Calendar.current.shortWeekdaySymbols
            if repeatDays.count == 7 {
                return "Every day"
            }
            if repeatDays == [2, 3, 4, 5, 6] {
                return "Weekdays"
            }
            if repeatDays == [1, 7] {
                return "Weekends"
            }
            let sorted = repeatDays.sorted()
            return sorted.map { daySymbols[$0 - 1] }.joined(separator: ", ")
        } else {
            return futureRepeatOption == .none ? "" : futureRepeatOption.rawValue
        }
    }

    /// Timezone short name for display (e.g., "IST", "PST")
    var timezoneShortName: String? {
        guard alarmType == .future, let _ = timezoneIdentifier else { return nil }
        let tz = timeZone
        if tz.identifier == TimeZone.current.identifier { return nil }
        return tz.abbreviation() ?? tz.identifier
    }
}

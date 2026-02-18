import Foundation
import AlarmKit

/// Shared metadata for AlarmKit Live Activities.
/// Included in both the main app target and the widget extension target.
public struct UnmuteAlarmMetadata: AlarmMetadata {
    public let alarmId: String
    public let snoozeDuration: Int

    public init(alarmId: String, snoozeDuration: Int) {
        self.alarmId = alarmId
        self.snoozeDuration = snoozeDuration
    }
}

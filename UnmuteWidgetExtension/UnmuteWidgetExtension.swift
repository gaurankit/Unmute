import WidgetKit
import SwiftUI
import ActivityKit
import AlarmKit

// MARK: - Live Activity Widget

struct UnmuteAlarmWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<UnmuteAlarmMetadata>.self) { context in
            UnmuteLockScreenView(state: context.state, attributes: context.attributes)
                .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("UNMUTE", systemImage: "alarm.fill")
                        .foregroundStyle(.orange)
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    UnmuteTimerView(state: context.state, large: false)
                        .foregroundStyle(.orange)
                        .font(.caption.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.presentation.alert.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    UnmuteTimerView(state: context.state, large: true)
                        .font(.system(size: 48, weight: .thin, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                UnmuteTimerView(state: context.state, large: false)
                    .foregroundStyle(.orange)
                    .font(.caption.monospacedDigit())
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Lock Screen Banner

struct UnmuteLockScreenView: View {
    let state: AlarmPresentationState
    let attributes: AlarmAttributes<UnmuteAlarmMetadata>

    var body: some View {
        HStack(spacing: 16) {
            // App icon area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange)
                    .frame(width: 48, height: 48)
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.white)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("UNMUTE")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(attributes.presentation.alert.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                UnmuteStatusLabel(state: state)
                UnmuteTimerView(state: state, large: false)
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Status label (Ringing / Snoozing / Paused)

struct UnmuteStatusLabel: View {
    let state: AlarmPresentationState

    var body: some View {
        switch state.mode {
        case .alert:
            Text("Ringing")
                .font(.caption.bold())
                .foregroundStyle(.orange)
        case .countdown:
            Text("Snoozing")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        case .paused:
            Text("Paused")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Timer view

struct UnmuteTimerView: View {
    let state: AlarmPresentationState
    let large: Bool

    var body: some View {
        switch state.mode {
        case .alert:
            Image(systemName: "bell.fill")
                .symbolEffect(.wiggle, options: .repeating)
                .font(large ? .largeTitle : .body)

        case .countdown(let countdown):
            // .timer style counts down to fireDate live — no manual updates needed
            Text(countdown.fireDate, style: .timer)

        case .paused(let paused):
            let remaining = paused.totalCountdownDuration - paused.previouslyElapsedDuration
            Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond))
        }
    }
}

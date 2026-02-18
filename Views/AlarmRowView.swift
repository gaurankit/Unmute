import SwiftUI

struct AlarmRowView: View {
    let alarm: AlarmModel
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Time
                Text(alarm.formattedTime)
                    .font(.system(size: 48, weight: .light, design: .default))
                    .foregroundStyle(alarm.isEnabled ? .white : .gray)

                // Subtitle line: label + repeat + timezone info
                HStack(spacing: 6) {
                    if !alarm.label.isEmpty && alarm.label != "Alarm" {
                        Text(alarm.label)
                            .font(.subheadline)
                            .foregroundStyle(alarm.isEnabled ? .white.opacity(0.7) : .gray.opacity(0.5))
                    }

                    if let tzShort = alarm.timezoneShortName {
                        Text(tzShort)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.3))
                            .clipShape(Capsule())
                            .foregroundStyle(alarm.isEnabled ? .orange : .gray)
                    }

                    if !alarm.repeatDescription.isEmpty {
                        Text(alarm.repeatDescription)
                            .font(.subheadline)
                            .foregroundStyle(alarm.isEnabled ? .white.opacity(0.5) : .gray.opacity(0.4))
                    }
                }

                // Future alarm: date + local fire time
                if alarm.alarmType == .future {
                    HStack(spacing: 8) {
                        if let date = alarm.formattedDate {
                            Text(date)
                                .font(.caption)
                                .foregroundStyle(alarm.isEnabled ? .orange : .gray.opacity(0.5))
                        }

                        if let localTime = alarm.formattedLocalFireTime {
                            Text(localTime)
                                .font(.caption)
                                .foregroundStyle(alarm.isEnabled ? .white.opacity(0.5) : .gray.opacity(0.4))
                        }
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.orange)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            AlarmRowView(
                alarm: {
                    let a = AlarmModel(
                        label: "Wake Up",
                        alarmType: .daily,
                        hour: 7,
                        minute: 30,
                        repeatDays: [2, 3, 4, 5, 6]
                    )
                    return a
                }(),
                onToggle: {}
            )
            AlarmRowView(
                alarm: {
                    let a = AlarmModel(
                        label: "Flight to NYC",
                        alarmType: .future,
                        hour: 7,
                        minute: 30,
                        targetDate: Date().addingTimeInterval(86400 * 10),
                        timezoneIdentifier: "Asia/Kolkata"
                    )
                    return a
                }(),
                onToggle: {}
            )
        }
        .padding()
    }
}

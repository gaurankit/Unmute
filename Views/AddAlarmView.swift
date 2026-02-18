import SwiftUI
import SwiftData

struct AddAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let viewModel: AlarmViewModel
    let editingAlarm: AlarmModel?

    // MARK: - Form State
    @State private var alarmType: AlarmType = .daily
    @State private var selectedTime = Date()
    @State private var selectedDate = Date()
    @State private var label = "Alarm"
    @State private var soundName = "default"
    @State private var isSnoozeEnabled = true
    @State private var snoozeDuration: SnoozeDuration = .nine

    // Daily
    @State private var repeatDays: Set<Int> = []

    // Future
    @State private var futureRepeatOption: RepeatOption = .none
    @State private var selectedTimezoneId: String? = nil

    // Sheets
    @State private var showSoundPicker = false
    @State private var showTimezonePicker = false
    @State private var showLimitAlert = false

    private var isEditing: Bool { editingAlarm != nil }

    init(viewModel: AlarmViewModel, editingAlarm: AlarmModel? = nil) {
        self.viewModel = viewModel
        self.editingAlarm = editingAlarm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    // Alarm type picker (only when creating)
                    if !isEditing {
                        Section {
                            Picker("Type", selection: $alarmType) {
                                Text("Daily").tag(AlarmType.daily)
                                Text("Future").tag(AlarmType.future)
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                        }
                    }

                    // Time picker
                    Section {
                        DatePicker(
                            "Time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    // Date picker (future only)
                    if alarmType == .future {
                        Section {
                            DatePicker(
                                "Date",
                                selection: $selectedDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .tint(.orange)
                            .listRowBackground(Color(.systemGray6).opacity(0.15))
                        } header: {
                            Text("DATE")
                                .foregroundStyle(.gray)
                        }
                    }

                    // Timezone (future only)
                    if alarmType == .future {
                        Section {
                            Button {
                                showTimezonePicker = true
                            } label: {
                                HStack {
                                    Text("Timezone")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(timezoneDisplayName)
                                        .foregroundStyle(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .listRowBackground(Color(.systemGray6).opacity(0.15))

                            // Show local fire time preview
                            if selectedTimezoneId != nil,
                               selectedTimezoneId != TimeZone.current.identifier {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(.orange)
                                    Text(localFireTimePreview)
                                        .font(.subheadline)
                                        .foregroundStyle(.orange)
                                }
                                .listRowBackground(Color(.systemGray6).opacity(0.15))
                            }
                        } header: {
                            Text("TIMEZONE")
                                .foregroundStyle(.gray)
                        }
                    }

                    // Repeat, Label, Sound, Snooze — single section like iOS Clock
                    Section {
                        if alarmType == .daily {
                            NavigationLink {
                                DayPickerView(selectedDays: $repeatDays)
                            } label: {
                                HStack {
                                    Text("Repeat")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(dailyRepeatLabel)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .listRowBackground(Color(.systemGray6).opacity(0.15))
                        } else {
                            Picker("Repeat", selection: $futureRepeatOption) {
                                ForEach(RepeatOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .foregroundStyle(.white)
                            .listRowBackground(Color(.systemGray6).opacity(0.15))
                        }

                        TextField("Label", text: $label)
                            .foregroundStyle(.white)
                            .listRowBackground(Color(.systemGray6).opacity(0.15))

                        Button {
                            showSoundPicker = true
                        } label: {
                            HStack {
                                Text("Sound")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(soundDisplayName)
                                    .foregroundStyle(.gray)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .listRowBackground(Color(.systemGray6).opacity(0.15))

                        Toggle("Snooze", isOn: $isSnoozeEnabled)
                            .tint(.orange)
                            .foregroundStyle(.white)
                            .listRowBackground(Color(.systemGray6).opacity(0.15))

                        if isSnoozeEnabled {
                            Picker("Snooze Duration", selection: $snoozeDuration) {
                                ForEach(SnoozeDuration.allCases) { duration in
                                    Text(duration.label).tag(duration)
                                }
                            }
                            .foregroundStyle(.white)
                            .listRowBackground(Color(.systemGray6).opacity(0.15))
                        }
                    }

                    // Delete button (edit mode only)
                    if isEditing {
                        Section {
                            Button(role: .destructive) {
                                if let alarm = editingAlarm {
                                    viewModel.deleteAlarm(alarm, context: modelContext)
                                }
                                dismiss()
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Delete Alarm")
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.red.opacity(0.15))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Alarm" : "Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveAlarm() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                }
            }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerView(selectedSound: $soundName)
            }
            .sheet(isPresented: $showTimezonePicker) {
                TimezonePicker(selectedTimezoneId: $selectedTimezoneId)
            }
            .alert("Alarm Limit Reached", isPresented: $showLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("iOS allows a maximum of 64 scheduled notifications. Please delete some existing alarms before adding new ones.")
            }
            .onAppear {
                loadEditingAlarm()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Computed

    private var timezoneDisplayName: String {
        if let id = selectedTimezoneId,
           let city = TimezoneService.shared.city(for: id) {
            return city.displayName
        }
        return "Local (\(TimeZone.current.abbreviation() ?? ""))"
    }

    private var localFireTimePreview: String {
        guard let tzId = selectedTimezoneId,
              let tz = TimeZone(identifier: tzId) else {
            return ""
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var sourceCalendar = Calendar.current
        sourceCalendar.timeZone = tz
        var components = sourceCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0

        guard let sourceDate = sourceCalendar.date(from: components) else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = .current

        let localFormatter = DateFormatter()
        localFormatter.dateStyle = .medium
        localFormatter.timeZone = .current

        return "Rings at \(formatter.string(from: sourceDate)) your time on \(localFormatter.string(from: sourceDate))"
    }

    private var dailyRepeatLabel: String {
        if repeatDays.isEmpty { return "Never" }
        let sorted = repeatDays.sorted()
        let symbols = Calendar.current.shortWeekdaySymbols
        if repeatDays.count == 7 { return "Every day" }
        if sorted == [2, 3, 4, 5, 6] { return "Weekdays" }
        if sorted == [1, 7] { return "Weekends" }
        return sorted.map { symbols[$0 - 1] }.joined(separator: ", ")
    }

    private var soundDisplayName: String {
        AlarmSound.allSounds.first { $0.id == soundName }?.name ?? "Default"
    }

    // MARK: - Actions

    private func saveAlarm() async {
        if !isEditing {
            let atLimit = await viewModel.isAtNotificationLimit()
            if atLimit {
                showLimitAlert = true
                return
            }
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        if let alarm = editingAlarm {
            // Update existing
            alarm.label = label
            alarm.hour = timeComponents.hour ?? 8
            alarm.minute = timeComponents.minute ?? 0
            alarm.soundName = soundName
            alarm.isSnoozeEnabled = isSnoozeEnabled
            alarm.snoozeDuration = snoozeDuration

            if alarm.alarmType == .daily {
                alarm.repeatDays = Array(repeatDays).sorted()
            } else {
                alarm.targetDate = selectedDate
                alarm.futureRepeatOption = futureRepeatOption
                alarm.timezoneIdentifier = selectedTimezoneId
            }

            alarm.isEnabled = true
            await viewModel.updateAlarm(alarm, context: modelContext)
        } else {
            // Create new
            let alarm = AlarmModel(
                label: label,
                alarmType: alarmType,
                hour: timeComponents.hour ?? 8,
                minute: timeComponents.minute ?? 0,
                repeatDays: alarmType == .daily ? Array(repeatDays).sorted() : [],
                targetDate: alarmType == .future ? selectedDate : nil,
                futureRepeatOption: alarmType == .future ? futureRepeatOption : .none,
                timezoneIdentifier: alarmType == .future ? selectedTimezoneId : nil,
                soundName: soundName,
                isSnoozeEnabled: isSnoozeEnabled,
                snoozeDuration: snoozeDuration,
                isEnabled: true
            )
            await viewModel.addAlarm(alarm, context: modelContext)
        }

        dismiss()
    }

    private func loadEditingAlarm() {
        guard let alarm = editingAlarm else { return }

        alarmType = alarm.alarmType
        label = alarm.label
        soundName = alarm.soundName
        isSnoozeEnabled = alarm.isSnoozeEnabled
        snoozeDuration = alarm.snoozeDuration

        // Set time
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        if let date = calendar.date(from: components) {
            selectedTime = date
        }

        if alarm.alarmType == .daily {
            repeatDays = Set(alarm.repeatDays)
        } else {
            selectedDate = alarm.targetDate ?? Date()
            futureRepeatOption = alarm.futureRepeatOption
            selectedTimezoneId = alarm.timezoneIdentifier
        }
    }
}

// MARK: - Day Picker View

struct DayPickerView: View {
    @Binding var selectedDays: Set<Int>

    // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    private let days: [(id: Int, name: String)] = {
        let symbols = Calendar.current.weekdaySymbols
        return symbols.enumerated().map { (index, name) in
            (id: index + 1, name: name)
        }
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List(days, id: \.id) { day in
                Button {
                    if selectedDays.contains(day.id) {
                        selectedDays.remove(day.id)
                    } else {
                        selectedDays.insert(day.id)
                    }
                } label: {
                    HStack {
                        Text("Every \(day.name)")
                            .foregroundStyle(.white)
                        Spacer()
                        if selectedDays.contains(day.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .listRowBackground(Color(.systemGray6).opacity(0.15))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Repeat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    AddAlarmView(viewModel: AlarmViewModel())
        .modelContainer(for: AlarmModel.self, inMemory: true)
}

import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AlarmModel.hour, order: .forward) private var allAlarms: [AlarmModel]
    @State private var viewModel = AlarmViewModel()
    @State private var showAddAlarm = false
    @State private var alarmToEdit: AlarmModel?

    private var dailyAlarms: [AlarmModel] {
        allAlarms
            .filter { $0.alarmType == .daily }
            .sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
    }

    private var futureAlarms: [AlarmModel] {
        allAlarms
            .filter { $0.alarmType == .future }
            .sorted {
                let date0 = $0.localFireDate ?? .distantFuture
                let date1 = $1.localFireDate ?? .distantFuture
                return date0 < date1
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if allAlarms.isEmpty {
                    emptyState
                } else {
                    alarmList
                }
            }
            .navigationTitle("Alarms")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .foregroundStyle(.orange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showAddAlarm) {
                AddAlarmView(viewModel: viewModel)
            }
            .sheet(item: $alarmToEdit) { alarm in
                AddAlarmView(viewModel: viewModel, editingAlarm: alarm)
            }
            .alert("Notifications Disabled", isPresented: $viewModel.showNotificationDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("UNMUTE needs notification permission to ring your alarms. Please enable it in Settings.")
            }
            .alert("Alarm Limit Warning", isPresented: $viewModel.showLimitWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You have \(viewModel.pendingCount) scheduled notifications. iOS allows a maximum of 64. Consider removing some alarms.")
            }
            .task {
                await viewModel.requestNotificationPermission()
                viewModel.setupNotificationCategories()
                viewModel.disableFiredAlarms(allAlarms, context: modelContext)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            Text("No Alarms")
                .font(.title2)
                .foregroundStyle(.gray)
            Text("Tap + to set your first alarm")
                .font(.subheadline)
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    private var alarmList: some View {
        List {
            if !dailyAlarms.isEmpty {
                Section {
                    ForEach(dailyAlarms) { alarm in
                        AlarmRowView(alarm: alarm) {
                            Task { await viewModel.toggleAlarm(alarm, context: modelContext) }
                        }
                        .listRowBackground(Color(.systemGray6).opacity(0.15))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            alarmToEdit = alarm
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteAlarm(dailyAlarms[index], context: modelContext)
                        }
                    }
                } header: {
                    Text("DAILY")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
            }

            if !futureAlarms.isEmpty {
                Section {
                    ForEach(futureAlarms) { alarm in
                        AlarmRowView(alarm: alarm) {
                            Task { await viewModel.toggleAlarm(alarm, context: modelContext) }
                        }
                        .listRowBackground(Color(.systemGray6).opacity(0.15))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            alarmToEdit = alarm
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteAlarm(futureAlarms[index], context: modelContext)
                        }
                    }
                } header: {
                    Text("FUTURE")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    AlarmListView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}

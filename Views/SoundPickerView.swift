import SwiftUI

struct AlarmSound: Identifiable, Hashable {
    let id: String
    let name: String

    static let allSounds: [AlarmSound] = [
        AlarmSound(id: "default", name: "Default"),
        AlarmSound(id: "Alarm", name: "Alarm"),
        AlarmSound(id: "Beacon", name: "Beacon"),
        AlarmSound(id: "Bulletin", name: "Bulletin"),
        AlarmSound(id: "Chimes", name: "Chimes"),
        AlarmSound(id: "Circuit", name: "Circuit"),
        AlarmSound(id: "Constellation", name: "Constellation"),
        AlarmSound(id: "Cosmic", name: "Cosmic"),
        AlarmSound(id: "Crystals", name: "Crystals"),
        AlarmSound(id: "Hillside", name: "Hillside"),
        AlarmSound(id: "Illuminate", name: "Illuminate"),
        AlarmSound(id: "Night Owl", name: "Night Owl"),
        AlarmSound(id: "Opening", name: "Opening"),
        AlarmSound(id: "Playtime", name: "Playtime"),
        AlarmSound(id: "Presto", name: "Presto"),
        AlarmSound(id: "Radar", name: "Radar"),
        AlarmSound(id: "Radiate", name: "Radiate"),
        AlarmSound(id: "Ripples", name: "Ripples"),
        AlarmSound(id: "Sencha", name: "Sencha"),
        AlarmSound(id: "Signal", name: "Signal"),
        AlarmSound(id: "Silk", name: "Silk"),
        AlarmSound(id: "Slow Rise", name: "Slow Rise"),
        AlarmSound(id: "Stargaze", name: "Stargaze"),
        AlarmSound(id: "Summit", name: "Summit"),
        AlarmSound(id: "Twinkle", name: "Twinkle"),
        AlarmSound(id: "Uplift", name: "Uplift"),
        AlarmSound(id: "Waves", name: "Waves"),
    ]
}

struct SoundPickerView: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List(AlarmSound.allSounds) { sound in
                    Button {
                        selectedSound = sound.id
                    } label: {
                        HStack {
                            Text(sound.name)
                                .foregroundStyle(.white)

                            Spacer()

                            if selectedSound == sound.id {
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
            .navigationTitle("Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SoundPickerView(selectedSound: .constant("default"))
}

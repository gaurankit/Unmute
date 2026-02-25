import SwiftUI

struct AlarmSound: Identifiable, Hashable {
    let id: String
    let name: String

    /// Only sounds that have a real .caf file bundled in the app.
    static let allSounds: [AlarmSound] = [
        AlarmSound(id: "default", name: "UNMUTE Alarm"),
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SoundPickerView(selectedSound: .constant("default"))
}

import SwiftUI

struct TimezonePicker: View {
    @Binding var selectedTimezoneId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let service = TimezoneService.shared

    private var results: [TimezoneCity] {
        service.search(query: searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List(results) { city in
                    Button {
                        selectedTimezoneId = city.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(city.displayName)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Text("\(city.abbreviation) \u{2022} \(city.utcOffset)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }

                            Spacer()

                            if selectedTimezoneId == city.id {
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
            .navigationTitle("Select Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search city or country")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedTimezoneId = nil
                        dismiss()
                    } label: {
                        Image(systemName: "location")
                            .foregroundStyle(.orange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TimezonePicker(selectedTimezoneId: .constant("Asia/Kolkata"))
}

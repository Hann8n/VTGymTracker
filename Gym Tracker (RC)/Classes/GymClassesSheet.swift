import SwiftUI

extension TrackedFacility: Identifiable {}

/// A gym's upcoming classes by day. Shows cached classes at once; a spinner only when there are none yet.
struct GymClassesSheet: View {
    let facility: TrackedFacility
    let classes: [GymClass]
    let isRefreshing: Bool

    @Environment(\.dismiss) private var dismiss

    private var days: [(day: Date, classes: [GymClass])] {
        Dictionary(grouping: classes) { Calendar.current.startOfDay(for: $0.start) }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !classes.isEmpty {
                    List {
                        ForEach(days, id: \.day) { day in
                            Section(Self.title(for: day.day)) {
                                ForEach(day.classes) { row($0) }
                            }
                        }
                    }
                } else if isRefreshing {
                    ProgressView()
                } else {
                    ContentUnavailableView("No Classes Scheduled", systemImage: "calendar")
                }
            }
            .navigationTitle(facility.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ gymClass: GymClass) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(gymClass.title)
                    .font(.body.weight(.semibold))
                Text(gymClass.room)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text((gymClass.start..<gymClass.end).formatted(.interval.hour().minute()))
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private static func title(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInTomorrow(day) { return "Tomorrow" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

import SwiftUI

/// Every upcoming class by day, filtered by gym and searchable by name. Cached classes show at once.
struct ClassScheduleSheet: View {
    @ObservedObject var classSchedule: ClassScheduleViewModel

    @AppStorage(ClassGymFilter.storageKey) private var filter: ClassGymFilter = .all
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                let days = filteredDays(now: context.date)

                List {
                    ForEach(days, id: \.day) { day in
                        Section(ClassRowText.dayTitle(day.day, now: context.date)) {
                            ForEach(day.classes) { row($0, now: context.date) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
                .overlay {
                    if days.isEmpty { emptyState }
                }
            }
            .navigationTitle("Classes")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Yoga, Cycle, Barre…")
            .refreshable { await classSchedule.refresh() }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ClassGymPicker(selection: $filter)
                        .fixedSize()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
    }

    private func filteredDays(now: Date) -> [(day: Date, classes: [ScheduledClass])] {
        let days = classSchedule.schedule.days(filter, after: now)
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return days }
        return days.compactMap { day in
            let matches = day.classes.filter {
                $0.gymClass.title.localizedCaseInsensitiveContains(query) || $0.gymClass.room.localizedCaseInsensitiveContains(query)
            }
            return matches.isEmpty ? nil : (day.day, matches)
        }
    }

    private func row(_ scheduled: ScheduledClass, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(scheduled.gymClass.title)
                    .font(.body.weight(.semibold))
                Spacer(minLength: 8)
                Text(EventCard.timeRangeText(start: scheduled.gymClass.start, end: scheduled.gymClass.end))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(filter == .all ? "\(scheduled.gymName) · \(scheduled.gymClass.room)" : scheduled.gymClass.room)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if let status = ClassRowText.status(scheduled, now: now) {
                    Text(status.text)
                        .fontWeight(.semibold)
                        .foregroundStyle(status.color)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ClassRowText.accessibilityLabel(scheduled, now: now))
    }

    @ViewBuilder private var emptyState: some View {
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            ContentUnavailableView.search(text: query)
        } else if classSchedule.isRefreshing {
            ProgressView()
        } else {
            ContentUnavailableView("No Upcoming Classes", systemImage: "calendar",
                                   description: Text("Rec Sports hasn't scheduled classes here yet."))
        }
    }
}

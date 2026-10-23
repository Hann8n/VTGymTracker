import SwiftUI

/// Every upcoming class by day: a standard large title (like Settings), the gym picker pinned beneath it,
/// and search at the bottom. Cached classes show at once; pull to refresh fetches again.
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
                            ForEach(day.classes) { scheduled in
                                ClassRow(scheduled: scheduled, style: .detail, showsGym: filter == .all, now: context.date)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
                .overlay {
                    if days.isEmpty { emptyState }
                }
            }
            .modifier(PinnedTopBar {
                ClassGymPicker(selection: $filter)
                    .padding(.horizontal, DashboardLayout.horizontalGutter)
                    .padding(.bottom, 8)
            })
            .modifier(BottomSearch(text: $query))
            .refreshable { await classSchedule.refresh() }
            .navigationTitle("Classes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton { dismiss() }
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

// MARK: - Bars

/// Pins content under the navigation bar: a scroll-edge bar on iOS 26, a material inset before.
private struct PinnedTopBar<Bar: View>: ViewModifier {
    @ViewBuilder let bar: () -> Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .top, content: bar)
        } else {
            content.safeAreaInset(edge: .top, spacing: 0) {
                bar().frame(maxWidth: .infinity).background(.bar)
            }
        }
    }
}

/// Search in the bottom toolbar on iOS 26; earlier systems keep it under the title.
private struct BottomSearch: ViewModifier {
    @Binding var text: String
    private let prompt = "Yoga, Cycle, Barre…"

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .searchable(text: $text, placement: .toolbar, prompt: prompt)
                .toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }
        } else {
            content.searchable(text: $text, placement: .navigationBarDrawer(displayMode: .always), prompt: prompt)
        }
    }
}

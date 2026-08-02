import SwiftUI

struct EventsSectionBlock: View {
    @ObservedObject var eventsViewModel: EventsViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let motionPolicy: MotionPolicy

    private var groupedEvents: [(date: Date, events: [Event])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: eventsViewModel.events) { event in
            calendar.startOfDay(for: event.startDate)
        }

        return grouped.keys.sorted().map { date in
            let events = grouped[date, default: []].sorted { $0.startDate < $1.startDate }
            return (date: date, events: events)
        }
    }

    private var headerSubtitle: String {
        eventSourceName
    }

    private var eventSourceName: String {
        let hostingBodies = Set(eventsViewModel.events.map(\.hostingBody).filter { !$0.isEmpty })
        return hostingBodies.count == 1 ? hostingBodies.first ?? "Recreational Sports" : "Recreational Sports"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(
                title: "Upcoming Events",
                subtitle: headerSubtitle
            )
            .padding(.horizontal, DashboardLayout.horizontalGutter)

            Group {
                if let errorMessage = eventsViewModel.errorMessage {
                    errorState(errorMessage: errorMessage)
                } else if eventsViewModel.isLoading && eventsViewModel.events.isEmpty {
                    loadingState
                } else if eventsViewModel.events.isEmpty {
                    emptyState
                } else {
                    eventsList
                }
            }
            .transition(motionPolicy.transition)
            .animation(motionPolicy.entryAnimation, value: eventsViewModel.events.count)
        }
        .padding(.top, DashboardLayout.sectionSpacingBeforeHeader)
    }

    private var eventsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(groupedEvents.enumerated()), id: \.element.date) { dayIndex, group in
                VStack(alignment: .leading, spacing: 0) {
                    Text(sectionTitle(for: group.date))
                        .font(.caption.weight(.bold))
                        .fontWidth(.condensed)
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, DashboardLayout.horizontalGutter)
                        .padding(.top, dayIndex == 0 ? 14 : 16)
                        .padding(.bottom, 4)

                    ForEach(Array(group.events.enumerated()), id: \.element.id) { eventIndex, event in
                        EventCard(event: event)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DashboardLayout.horizontalGutter)
                            .padding(.vertical, 10)

                        if eventIndex < group.events.count - 1 {
                            FullBleedDivider()
                                .padding(.leading, DashboardLayout.horizontalGutter + 84)
                        }
                    }
                }

                if dayIndex < groupedEvents.count - 1 {
                    FullBleedDivider()
                }
            }
        }
        .padding(.bottom, 8)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .dashboardCardChrome(networkMonitor: networkMonitor)
    }

    private var loadingState: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                EventCardSkeleton()
                    .padding(.horizontal, DashboardLayout.horizontalGutter)
                    .padding(.vertical, 12)

                if index < 2 {
                    FullBleedDivider()
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .dashboardCardChrome(networkMonitor: networkMonitor)
    }

    private var emptyState: some View {
        Text("Nothing scheduled right now")
            .font(.subheadline.weight(.semibold))
            .fontWidth(.condensed)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, DashboardLayout.horizontalGutter)
            .padding(.vertical, DashboardLayout.cardVerticalPadding)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .dashboardCardChrome(networkMonitor: networkMonitor)
    }

    private func errorState(errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Text(errorMessage)
                .font(.subheadline.weight(.medium))
                .fontWidth(.condensed)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                eventsViewModel.fetchEvents()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, DashboardLayout.horizontalGutter)
        .padding(.vertical, DashboardLayout.cardVerticalPadding)
        .dashboardCardChrome(networkMonitor: networkMonitor)
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        if calendar.isDateInWeekend(date) {
            return "This Weekend"
        }

        return Self.sectionDateFormatter.string(from: date)
    }

    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
}

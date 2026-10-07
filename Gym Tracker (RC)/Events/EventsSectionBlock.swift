import SwiftUI

struct EventsSectionBlock: View {
    @ObservedObject var eventsViewModel: EventsViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let motionPolicy: MotionPolicy

    /// Upcoming (not yet ended) events grouped by calendar day, earliest first.
    private func groupedEvents(now: Date) -> [(date: Date, events: [Event])] {
        let calendar = Calendar.current
        let upcoming = eventsViewModel.events.filter { $0.endDate > now }
        let grouped = Dictionary(grouping: upcoming) { event in
            // An event already under way is filed under today, not the day it began.
            calendar.startOfDay(for: max(event.startDate, now))
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

    // MARK: - States

    /// Re-renders every minute so "Live" / "In N min" tags stay current and ended events drop off.
    private var eventsList: some View {
        TimelineView(.everyMinute) { context in
            let days = groupedEvents(now: context.date)

            Group {
                if days.isEmpty {
                    emptyContent
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.element.date) { dayIndex, group in
                            EventDayGroup(date: group.date, events: group.events, now: context.date)

                            if dayIndex < days.count - 1 {
                                FullBleedDivider()
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .dashboardCardChrome(networkMonitor: networkMonitor)
        }
    }

    /// Only shown on a first launch with nothing cached; otherwise cached events show
    /// immediately and are swapped for fresh ones when the fetch lands.
    private var loadingState: some View {
        ProgressView()
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            .dashboardCardChrome(networkMonitor: networkMonitor)
            .accessibilityLabel("Loading events")
    }

    private var emptyState: some View {
        emptyContent
            .dashboardCardChrome(networkMonitor: networkMonitor)
    }

    private var emptyContent: some View {
        statusMessage(
            systemImage: "calendar",
            title: "Nothing scheduled",
            detail: "New Rec Sports events will show up here."
        )
        .padding(.vertical, DashboardLayout.cardVerticalPadding)
    }

    private func errorState(errorMessage: String) -> some View {
        VStack(spacing: 14) {
            statusMessage(
                systemImage: networkMonitor.isConnected ? "exclamationmark.triangle" : "wifi.slash",
                title: "Events unavailable",
                detail: errorMessage
            )

            Button {
                eventsViewModel.fetchEvents()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .fontWidth(.condensed)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(Color("CustomOrange"))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DashboardLayout.cardVerticalPadding)
        .dashboardCardChrome(networkMonitor: networkMonitor)
    }

    /// Icon + uppercase condensed label + footnote, shared by empty and error states.
    private func statusMessage(systemImage: String, title: String, detail: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 2)
                .accessibilityHidden(true)

            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.9)
                .foregroundStyle(.secondary)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, DashboardLayout.horizontalGutter)
        .accessibilityElement(children: .combine)
    }
}

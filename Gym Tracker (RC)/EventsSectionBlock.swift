import SwiftUI

struct EventsSectionBlock: View {
    @ObservedObject var eventsViewModel: EventsViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let motionPolicy: MotionPolicy

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(
                title: "Upcoming Events",
                subtitle: "Today - \(Constants.formattedDateTwoWeeksAhead())"
            )
            .padding(.horizontal, DashboardLayout.horizontalGutter)

            Group {
                if let errorMessage = eventsViewModel.errorMessage {
                    errorState(errorMessage: errorMessage)
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
        VStack(spacing: 0) {
            ForEach(Array(eventsViewModel.events.enumerated()), id: \.element.id) { index, event in
                EventCard(event: event)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DashboardLayout.horizontalGutter)
                    .padding(.vertical, DashboardLayout.cardVerticalPadding)

                if index < eventsViewModel.events.count - 1 {
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
}

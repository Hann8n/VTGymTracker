import SwiftUI

struct AthleticEventsBlock: View {
    @ObservedObject var eventsViewModel: EventsViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let motionPolicy: MotionPolicy

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AthleticSectionHeader(
                title: "Upcoming Events",
                subtitle: "Today - \(Constants.formattedDateTwoWeeksAhead())"
            )
            .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
            .padding(.top, 6)

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
        }
    }

    private var eventsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(eventsViewModel.events.enumerated()), id: \.element.id) { index, event in
                EventCard(event: event)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
                    .padding(.vertical, AthleticDashboardLayout.cardVerticalPadding)

                if index < eventsViewModel.events.count - 1 {
                    AthleticFullBleedDivider()
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .athleticFrostedCardChrome(networkMonitor: networkMonitor)
    }

    private var emptyState: some View {
        Text("Nothing scheduled right now")
            .font(.subheadline.weight(.semibold))
            .fontWidth(.condensed)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
            .padding(.vertical, AthleticDashboardLayout.cardVerticalPadding)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .athleticFrostedCardChrome(networkMonitor: networkMonitor)
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
        .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
        .padding(.vertical, AthleticDashboardLayout.cardVerticalPadding)
        .athleticFrostedCardChrome(networkMonitor: networkMonitor)
    }
}

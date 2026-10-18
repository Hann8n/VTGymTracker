import SwiftUI

/// Occupancy alongside a scrolling campaign/events feed on expanded displays.
/// Navigation and data ownership stay outside this layout as the window changes shape.
struct DashboardContentLayout<Header: View, Occupancy: View, Events: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ViewBuilder let header: () -> Header
    @ViewBuilder let occupancy: () -> Occupancy
    @ViewBuilder let events: (_ isSeparatePane: Bool) -> Events

    @State private var occupancyPosition: String?
    @State private var eventsPosition: String?

    var body: some View {
        GeometryReader { geometry in
            if shouldUseSeparatePanes(in: geometry) {
                VStack(alignment: .leading, spacing: 8) {
                    header()
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                    expandedContent
                }
            } else {
                DashboardScrollContainer {
                    header()
                    occupancy()
                    events(false)
                }
                .scrollPosition(id: $occupancyPosition, anchor: .top)
            }
        }
        .background(Color(.systemBackground))
    }

    private func shouldUseSeparatePanes(in geometry: GeometryProxy) -> Bool {
        guard horizontalSizeClass == .regular else { return false }
        return geometry.size.width > geometry.size.height && !dynamicTypeSize.isAccessibilitySize
    }

    @ViewBuilder private var expandedContent: some View {
        if #available(iOS 27.1, *) {
            // The native arrangement keeps horizontal panes clear of the fold.
            // Vertical windows always use the continuous feed, including when bent.
            ArrangementView {
                occupancyPane
            } secondary: {
                eventsPane
            }
            .arrangementViewStyle(.split)
        } else {
            HStack(alignment: .top, spacing: 0) {
                occupancyPane
                Divider()
                eventsPane
            }
        }
    }

    private var occupancyPane: some View {
        ViewThatFits(in: .vertical) {
            occupancyContent
                .fixedSize(horizontal: false, vertical: true)
            DashboardScrollContainer {
                occupancyContent
            }
            .scrollPosition(id: $occupancyPosition, anchor: .top)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("dashboard-occupancy-pane")
    }

    private var occupancyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardSectionHeader(title: "Live occupancy")
                .padding(.horizontal, DashboardLayout.horizontalGutter)
                .padding(.bottom, 8)
            occupancy()
        }
        .padding(.top, 4)
    }

    private var eventsPane: some View {
        DashboardScrollContainer {
            events(true)
        }
        .scrollPosition(id: $eventsPosition, anchor: .top)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("dashboard-events-pane")
    }
}

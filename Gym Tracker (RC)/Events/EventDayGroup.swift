import SwiftUI

/// One day in the events list: a date tile on the left, that day's events stacked on the right.
struct EventDayGroup: View {
    let date: Date
    let events: [Event]
    let now: Date

    static let dateColumnWidth: CGFloat = 44
    static let columnSpacing: CGFloat = 14

    var body: some View {
        HStack(alignment: .top, spacing: Self.columnSpacing) {
            EventDateTile(date: date, isToday: Calendar.current.isDate(date, inSameDayAs: now))
                .padding(.top, 12)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    EventCard(event: event, now: now)

                    if index < events.count - 1 {
                        FullBleedDivider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, DashboardLayout.horizontalGutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

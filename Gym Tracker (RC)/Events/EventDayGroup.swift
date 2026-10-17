import SwiftUI

/// One calendar column per day, with aligned event rows and an accessible stacked layout.
struct EventDayGroup: View {
    let date: Date
    let events: [Event]
    let now: Date
    var showsMonth = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    dateColumn(isInline: true)
                        .padding(.trailing, DashboardLayout.horizontalGutter)
                    eventRows
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    dateColumn(isInline: false)
                    eventRows
                }
            }
        }
        .padding(.leading, DashboardLayout.horizontalGutter)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dateColumn(isInline: Bool) -> some View {
        EventDateTile(date: date, isToday: Calendar.current.isDate(date, inSameDayAs: now), isInline: isInline, showsMonth: showsMonth)
    }

    private var eventRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                EventCard(event: event, now: now)
                if index < events.count - 1 {
                    FullBleedDivider()
                        .padding(.trailing, DashboardLayout.horizontalGutter)
                        .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Multiple events") {
    let now = Date(timeIntervalSince1970: 1_792_249_200)
    let start = now.addingTimeInterval(30 * 60)
    EventDayGroup(date: now, events: [
        Event(title: "Toughest Hokie", description: "", link: URL(fileURLWithPath: "/preview-event"), pubDate: now,
              endDate: start.addingTimeInterval(4 * 60 * 60), hostingBody: "Recreational Sports", startDate: start,
              location: "McComas Hall", priceText: "Free"),
        Event(title: "An evening of climbing with the Outdoor Adventure community", description: "", link: URL(fileURLWithPath: "/preview-climbing"), pubDate: now,
              endDate: start.addingTimeInterval(2 * 60 * 60), hostingBody: "Recreational Sports", startDate: start,
              location: "Bouldering Wall", priceText: "Free", attendeeCount: 27)
    ], now: now)
    .background { CardMaterialBackground() }
    .preferredColorScheme(.dark)
}

#Preview("Large text") {
    let now = Date(timeIntervalSince1970: 1_792_249_200)
    EventDayGroup(date: now, events: [
        Event(title: "Outdoor Adventure community climbing and recreation evening", description: "", link: URL(fileURLWithPath: "/preview-event"), pubDate: now,
              endDate: now.addingTimeInterval(2 * 60 * 60), hostingBody: "Recreational Sports", startDate: now,
              location: "War Memorial Hall, Recreational Sports entrance", priceText: "Free", attendeeCount: 27)
    ], now: now)
    .environment(\.dynamicTypeSize, .accessibility3)
}

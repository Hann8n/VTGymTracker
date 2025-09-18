import SwiftUI

struct EventCard: View {
    let event: Event
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Link(destination: event.link) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedStartDate(event.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func formattedStartDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.amSymbol = " AM" // Changed to lowercase
        formatter.pmSymbol = " PM" // Changed to lowercase
        let now = Date()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mma"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mma"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mma"
        } else {
            formatter.dateFormat = "EEEE, MMMM d 'at' h:mma"
        }
        return formatter.string(from: date)
    }
}

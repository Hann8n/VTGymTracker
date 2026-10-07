import SwiftUI

/// Leading date column for a day of events: weekday label, big condensed day number, month.
/// Same "hero number" recipe as `FacilityOccupancyCard`, scaled down for a list.
struct EventDateTile: View {
    let date: Date
    let isToday: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(isToday ? "Today" : Self.weekdayFormatter.string(from: date))
                .font(.caption2.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(isToday ? Color("CustomOrange") : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(Self.dayFormatter.string(from: date))
                .font(.system(size: 30, weight: .black, design: .default))
                .fontWidth(.condensed)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(Self.monthFormatter.string(from: date))
                .font(.caption2.weight(.semibold))
                .fontWidth(.condensed)
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(width: EventDayGroup.dateColumnWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isToday ? "Today" : Self.accessibilityFormatter.string(from: date))
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Formatters

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter
    }()
}

#Preview {
    HStack(spacing: 24) {
        EventDateTile(date: .now, isToday: true)
        EventDateTile(date: .now.addingTimeInterval(86_400 * 3), isToday: false)
    }
    .padding()
}

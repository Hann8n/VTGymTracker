import SwiftUI

/// Calendar column with a distinct day number; an inline date keeps accessibility text readable.
struct EventDateTile: View {
    let date: Date
    let isToday: Bool
    var isInline = false

    @ScaledMetric(relativeTo: .caption2) private var columnWidth: CGFloat = 44
    @ScaledMetric(relativeTo: .title3) private var daySize: CGFloat = 24

    var body: some View {
        Group {
            if isInline {
                Text(isToday ? "Today · \(Self.dateFormatter.string(from: date))" : Self.dateFormatter.string(from: date))
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(isToday ? Color("CustomOrange") : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    Text(isToday ? "Today" : Self.weekdayFormatter.string(from: date))
                        .font(.caption2.weight(.bold))
                        .tracking(0.7)
                        .textCase(.uppercase)
                        .foregroundStyle(isToday ? Color("CustomOrange") : Color.secondary)

                    Text(Self.dayFormatter.string(from: date))
                        .font(.system(size: daySize, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text(Self.monthFormatter.string(from: date))
                        .font(.caption2.weight(.medium))
                        .tracking(0.7)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
                .frame(width: columnWidth)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isToday ? "Today, \(Self.accessibilityFormatter.string(from: date))" : Self.accessibilityFormatter.string(from: date))
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter
    }()
}

#Preview {
    HStack(alignment: .top, spacing: 24) {
        EventDateTile(date: .now, isToday: true)
        EventDateTile(date: .now.addingTimeInterval(86_400 * 3), isToday: false)
    }
    .padding()
}

import SwiftUI

/// A quiet weekday/day box with centered, proportional calendar typography.
struct EventDateTile: View {
    let date: Date
    let isToday: Bool
    var isInline = false

    @ScaledMetric(relativeTo: .caption2) private var columnWidth: CGFloat = 52
    @ScaledMetric(relativeTo: .title3) private var daySize: CGFloat = 24

    var body: some View {
        Group {
            if isInline {
                Text(isToday ? "Today · \(inlineDateText)" : inlineDateText)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(isToday ? Color("CustomOrange") : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    Text(isToday ? "Today" : Self.weekdayFormatter.string(from: date))
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(isToday ? Color("CustomOrange") : Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(Self.dayFormatter.string(from: date))
                        .font(.system(size: daySize, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .multilineTextAlignment(.center)
                .padding(.vertical, 6)
                .frame(width: columnWidth)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isToday ? "Today, \(Self.accessibilityFormatter.string(from: date))" : Self.accessibilityFormatter.string(from: date))
        .accessibilityAddTraits(.isHeader)
    }

    private var inlineDateText: String {
        Self.dayWeekFormatter.string(from: date)
    }

    // MARK: - Formatters

    private static let dayWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEd")
        return formatter
    }()

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

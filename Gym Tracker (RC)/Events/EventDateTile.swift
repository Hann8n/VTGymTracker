import SwiftUI

/// A contained calendar box; month labels appear only when the agenda enters a new month.
struct EventDateTile: View {
    let date: Date
    let isToday: Bool
    var isInline = false
    var showsMonth = false

    @ScaledMetric(relativeTo: .caption2) private var columnWidth: CGFloat = 52
    @ScaledMetric(relativeTo: .title3) private var daySize: CGFloat = 24

    var body: some View {
        Group {
            if isInline {
                Text(isToday ? "Today · \(inlineDateText)" : inlineDateText)
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(isToday ? Color("CustomOrange") : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
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

                    if showsMonth {
                        Text(Self.monthFormatter.string(from: date))
                            .font(.caption2.weight(.medium))
                            .tracking(0.7)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
                .frame(width: columnWidth)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isToday ? "Today, \(Self.accessibilityFormatter.string(from: date))" : Self.accessibilityFormatter.string(from: date))
        .accessibilityAddTraits(.isHeader)
    }

    private var inlineDateText: String {
        (showsMonth ? Self.dateFormatter : Self.dayWeekFormatter).string(from: date)
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

import SwiftUI

struct EventCard: View {
    let event: Event

    @Environment(\.openURL) private var openURL

    /// Width of the leading time column — shared with `EventCardSkeleton` and
    /// `EventsSectionBlock`'s row divider inset so the whole list stays aligned.
    static let leadingColumnWidth: CGFloat = 50
    static let leadingColumnSpacing: CGFloat = 14

    private var attendeeText: String? {
        guard let attendeeCount = event.attendeeCount, attendeeCount > 0 else { return nil }
        return "\(attendeeCount) going"
    }

    private var priceText: String? {
        guard let priceText = event.priceText.nilIfEmpty else { return nil }
        return priceText.localizedCaseInsensitiveCompare("free") == .orderedSame ? "Free" : priceText
    }

    private var summaryText: String {
        [priceText, attendeeText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        Button {
            openURL(event.link)
        } label: {
            HStack(alignment: .center, spacing: Self.leadingColumnSpacing) {
                timeColumn

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.body.weight(.semibold))
                        .fontWidth(.condensed)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if !summaryText.isEmpty {
                        Text(summaryText)
                            .font(.footnote.weight(.medium))
                            .fontWidth(.condensed)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens event details")
    }

    /// Big condensed digit + small uppercase unit — the same "hero number" recipe
    /// `FacilityOccupancyCard` uses for occupancy counts, applied to event start time.
    private var timeColumn: some View {
        VStack(spacing: 0) {
            Text(Self.hourMinuteFormatter.string(from: event.startDate))
                .font(.system(size: 20, weight: .black, design: .default))
                .fontWidth(.condensed)
                .monospacedDigit()
                .foregroundStyle(Color.customOrange)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(Self.periodFormatter.string(from: event.startDate).uppercased())
                .font(.caption2.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.6)
                .foregroundStyle(.secondary)
        }
        .frame(width: Self.leadingColumnWidth)
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        [
            event.title,
            Self.timeFormatter.string(from: event.startDate),
            summaryText.nilIfEmpty
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    private static let hourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    private static let periodFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = " AM"
        formatter.pmSymbol = " PM"
        return formatter
    }()
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

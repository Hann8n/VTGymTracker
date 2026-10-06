import SwiftUI

struct EventCard: View {
    let event: Event
    var now: Date = Date()

    @Environment(\.openURL) private var openURL

    /// Events starting within this window get an "In N min" tag.
    private static let startingSoonWindow: TimeInterval = 60 * 60

    // MARK: - Derived content

    private var statusTag: (text: String, style: EventTag.Style)? {
        if event.startDate <= now && now < event.endDate {
            return (text: "Live", style: EventTag.Style.live)
        }

        let secondsUntilStart = event.startDate.timeIntervalSince(now)
        if secondsUntilStart > 0 && secondsUntilStart <= Self.startingSoonWindow {
            let minutes = max(1, Int((secondsUntilStart / 60).rounded(.up)))
            return (text: "In \(minutes) min", style: EventTag.Style.soon)
        }

        return nil
    }

    private var priceText: String? {
        guard let priceText = event.priceText.nilIfEmpty else { return nil }
        return priceText.localizedCaseInsensitiveCompare("free") == .orderedSame ? "Free" : priceText
    }

    private var attendeeText: String? {
        guard let attendeeCount = event.attendeeCount, attendeeCount > 0 else { return nil }
        return "\(attendeeCount.abbreviatedCount) going"
    }

    private var timeRangeText: String {
        Self.timeRangeText(start: event.startDate, end: event.endDate)
    }

    // MARK: - Body

    var body: some View {
        Button {
            openURL(event.link)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    metaRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .padding(.trailing, DashboardLayout.horizontalGutter)
            .contentShape(Rectangle())
        }
        .buttonStyle(EventRowButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens event details")
        .accessibilityAddTraits(.isButton)
    }

    /// Drops the attendee count, then the price, when the row is too narrow to fit everything.
    private var metaRow: some View {
        ViewThatFits(in: .horizontal) {
            metaContent(showsPrice: true, showsAttendees: true)
            metaContent(showsPrice: true, showsAttendees: false)
            metaContent(showsPrice: false, showsAttendees: false)
        }
    }

    private func metaContent(showsPrice: Bool, showsAttendees: Bool) -> some View {
        HStack(spacing: 6) {
            Text(timeRangeText)
                .font(.footnote.weight(.medium))
                .fontWidth(.condensed)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()

            if let statusTag {
                EventTag(text: statusTag.text, style: statusTag.style)
            }

            if showsPrice, let priceText {
                EventTag(text: priceText, style: .neutral)
            }

            if showsAttendees, let attendeeText {
                Text(attendeeText)
                    .font(.footnote.weight(.medium))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    private var accessibilityLabel: String {
        [
            event.title,
            statusTag?.text,
            Self.accessibilityTimeText(start: event.startDate, end: event.endDate),
            priceText,
            attendeeText
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    // MARK: - Time formatting

    /// "6–7:30 PM", "11 AM – 1 PM", or "6 PM" when the feed gives no end time.
    static func timeRangeText(start: Date, end: Date) -> String {
        let startPeriod = periodFormatter.string(from: start)
        guard end > start else {
            return "\(clockText(start)) \(startPeriod)"
        }

        let endPeriod = periodFormatter.string(from: end)
        if startPeriod == endPeriod && Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(clockText(start))–\(clockText(end)) \(endPeriod)"
        }
        return "\(clockText(start)) \(startPeriod) – \(clockText(end)) \(endPeriod)"
    }

    private static func accessibilityTimeText(start: Date, end: Date) -> String {
        guard end > start else { return accessibilityTimeFormatter.string(from: start) }
        return "\(accessibilityTimeFormatter.string(from: start)) to \(accessibilityTimeFormatter.string(from: end))"
    }

    /// Drops ":00" so on-the-hour times read as "6" rather than "6:00".
    private static func clockText(_ date: Date) -> String {
        let minute = Calendar.current.component(.minute, from: date)
        return (minute == 0 ? hourFormatter : hourMinuteFormatter).string(from: date)
    }

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h"
        return formatter
    }()

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

    private static let accessibilityTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

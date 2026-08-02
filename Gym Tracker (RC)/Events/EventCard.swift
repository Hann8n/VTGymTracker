import SwiftUI

struct EventCard: View {
    let event: Event

    @Environment(\.openURL) private var openURL
    @State private var isAddingToCalendar = false
    @State private var calendarStatus: CalendarEventStatus = .notAdded
    @State private var calendarAlert: CalendarAlert?

    private let thumbnailSize: CGFloat = 64

    private var attendeeText: String? {
        guard let attendeeCount = event.attendeeCount, attendeeCount > 0 else { return nil }
        return "\(attendeeCount) going"
    }

    private var priceText: String? {
        guard let priceText = event.priceText.nilIfEmpty else { return nil }
        return priceText.localizedCaseInsensitiveCompare("free") == .orderedSame ? "Free" : priceText
    }

    private var metadataDetails: [String] {
        [priceText, attendeeText]
            .compactMap { $0 }
    }

    private var summaryText: String {
        metadataDetails.joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            eventDetailsButton

            calendarButton
                .frame(width: 44, height: 44)
        }
        .frame(minHeight: thumbnailSize, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: event.id) {
            calendarStatus = await EventCalendarWriter.shared.status(for: event)
        }
        .alert(item: $calendarAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var eventDetailsButton: some View {
        Button {
            openURL(event.link)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                eventImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    metadataRow(
                        time: Self.timeFormatter.string(from: event.startDate),
                        details: metadataDetails
                    )
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

    private func metadataRow(time: String, details: [String]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(time)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("CustomOrange"))
                .lineLimit(1)

            ForEach(Array(details.enumerated()), id: \.offset) { index, detail in
                if index > 0 {
                    Text("·")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(detail)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var eventImage: some View {
        Group {
            if let imageURL = event.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        imagePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color.primary.opacity(0.08)

            Image(systemName: "figure.run")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var calendarButton: some View {
        Button {
            handleCalendarButtonTap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(calendarButtonBackground)

                if isAddingToCalendar {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: calendarButtonSymbol)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(calendarButtonForeground)
                }
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .disabled(isAddingToCalendar)
        .accessibilityLabel(calendarButtonAccessibilityLabel)
        .accessibilityHint(calendarStatus == .added ? "Event already exists in your calendar" : "Creates a calendar event")
    }

    private var calendarButtonSymbol: String {
        switch calendarStatus {
        case .notAdded:
            return "calendar.badge.plus"
        case .added:
            return "calendar.badge.checkmark"
        }
    }

    private var calendarButtonForeground: Color {
        switch calendarStatus {
        case .notAdded:
            return .secondary
        case .added:
            return Color("CustomGreen")
        }
    }

    private var calendarButtonBackground: Color {
        switch calendarStatus {
        case .notAdded:
            return Color.primary.opacity(0.07)
        case .added:
            return Color("CustomGreen").opacity(0.14)
        }
    }

    private var calendarButtonAccessibilityLabel: String {
        switch calendarStatus {
        case .notAdded:
            return "Add \(event.title) to calendar"
        case .added:
            return "\(event.title) is already in your calendar"
        }
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

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = " AM"
        formatter.pmSymbol = " PM"
        return formatter
    }()

    private func handleCalendarButtonTap() {
        if calendarStatus == .added {
            calendarAlert = CalendarAlert(
                title: "Already in Calendar",
                message: "\(event.title) is already marked as added."
            )
            return
        }

        addToCalendar()
    }

    private func addToCalendar() {
        isAddingToCalendar = true
        Task {
            do {
                let result = try await EventCalendarWriter.shared.addToCalendar(event)
                calendarStatus = .added

                switch result {
                case .added:
                    calendarAlert = CalendarAlert(
                        title: "Added to Calendar",
                        message: "\(event.title) was added to your calendar."
                    )
                case .alreadyExists:
                    calendarAlert = CalendarAlert(
                        title: "Already in Calendar",
                        message: "\(event.title) is already in your calendar."
                    )
                }
            } catch {
                calendarAlert = CalendarAlert(
                    title: "Could Not Add Event",
                    message: error.localizedDescription
                )
            }
            isAddingToCalendar = false
        }
    }
}

private struct CalendarAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

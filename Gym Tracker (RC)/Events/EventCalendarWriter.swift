import EventKit
import Foundation

@MainActor
final class EventCalendarWriter {
    static let shared = EventCalendarWriter()

    private let eventStore = EKEventStore()
    private let userDefaults = UserDefaults.standard
    private let savedEventsKey = "savedCalendarEvents.v1"

    private init() {}

    func status(for event: Event) async -> CalendarEventStatus {
        if canReadCalendarEvents {
            let exists = matchingCalendarEvent(for: event) != nil
            setKnownCalendarStatus(exists, for: event)
            return exists ? .added : .notAdded
        }

        return isKnownCalendarEvent(event) ? .added : .notAdded
    }

    func addToCalendar(_ event: Event) async throws -> CalendarAddResult {
        try await ensureWriteAccess()

        if canReadCalendarEvents {
            if matchingCalendarEvent(for: event) != nil {
                setKnownCalendarStatus(true, for: event)
                return .alreadyExists
            }
        } else if isKnownCalendarEvent(event) {
            return .alreadyExists
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw CalendarWriterError.noDefaultCalendar
        }

        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.calendar = calendar
        calendarEvent.title = event.title
        calendarEvent.startDate = event.startDate
        calendarEvent.endDate = event.endDate
        calendarEvent.url = event.link
        calendarEvent.notes = event.calendarNotes
        calendarEvent.availability = .busy

        try eventStore.save(calendarEvent, span: .thisEvent)
        setKnownCalendarStatus(true, for: event)
        return .added
    }

    private func ensureWriteAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return
        case .notDetermined:
            let granted = try await eventStore.requestWriteOnlyAccessToEvents()
            guard granted else { throw CalendarWriterError.accessDenied }
        case .denied, .restricted:
            throw CalendarWriterError.accessDenied
        @unknown default:
            throw CalendarWriterError.accessDenied
        }
    }

    private var canReadCalendarEvents: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            return true
        case .notDetermined, .restricted, .denied, .writeOnly:
            return false
        @unknown default:
            return false
        }
    }

    private func matchingCalendarEvent(for event: Event) -> EKEvent? {
        let searchStartDate = event.startDate.addingTimeInterval(-60)
        let searchEndDate = event.endDate.addingTimeInterval(60)
        let predicate = eventStore.predicateForEvents(
            withStart: searchStartDate,
            end: searchEndDate,
            calendars: nil
        )

        return eventStore.events(matching: predicate).first { calendarEvent in
            calendarEvent.matches(event)
        }
    }

    private func isKnownCalendarEvent(_ event: Event) -> Bool {
        savedEventFingerprints.contains(fingerprint(for: event))
    }

    private func setKnownCalendarStatus(_ isAdded: Bool, for event: Event) {
        var fingerprints = savedEventFingerprints
        let fingerprint = fingerprint(for: event)

        if isAdded {
            fingerprints.insert(fingerprint)
        } else {
            fingerprints.remove(fingerprint)
        }

        userDefaults.set(Array(fingerprints), forKey: savedEventsKey)
    }

    private var savedEventFingerprints: Set<String> {
        Set(userDefaults.stringArray(forKey: savedEventsKey) ?? [])
    }

    private func fingerprint(for event: Event) -> String {
        event.link.absoluteString.lowercased()
    }
}

enum CalendarAddResult {
    case added
    case alreadyExists
}

enum CalendarEventStatus {
    case notAdded
    case added
}

enum CalendarWriterError: LocalizedError {
    case accessDenied
    case noDefaultCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access is required to add this event."
        case .noDefaultCalendar:
            return "No writable default calendar is available."
        }
    }
}

private extension EKEvent {
    func matches(_ event: Event) -> Bool {
        let sameTime = abs(startDate.timeIntervalSince(event.startDate)) < 60
            && abs(endDate.timeIntervalSince(event.endDate)) < 60
        let sameTitle = title.normalizedCalendarText == event.title.normalizedCalendarText
        let sameURL = url?.absoluteString == event.link.absoluteString
        let notesContainLink = notes?.contains(event.link.absoluteString) == true

        return sameTime && sameTitle && (sameURL || notesContainLink)
    }
}

private extension Event {
    var calendarNotes: String {
        var lines: [String] = []
        if !description.isEmpty {
            lines.append(description)
        }
        if !priceText.isEmpty {
            lines.append(priceText)
        }
        if let attendeeCount, attendeeCount > 0 {
            lines.append("\(attendeeCount) going")
        }
        lines.append("Details: \(link.absoluteString)")
        return lines.joined(separator: "\n\n")
    }
}

private extension String {
    var normalizedCalendarText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

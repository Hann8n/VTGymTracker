import Foundation

enum EventsDialog {
    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: Constants.eventsTimeZoneIdentifier)
        formatter.dateFormat = "EEE, MMM d, h:mm a z"
        return formatter.string(from: date)
    }

    static func freshness(_ snapshot: EventsSnapshot) -> String {
        if let age = snapshot.cacheAgeSeconds {
            let minutes = Int(ceil(age / 60))
            return "Cached \(minutes) \(minutes == 1 ? "minute" : "minutes") ago; live events unavailable. "
        }
        return ""
    }

    static func search(_ selection: EventsSelection, snapshot: EventsSnapshot) -> String {
        guard snapshot.status != .unavailable else { return "Events are unavailable from CampusGroups right now." }
        let prefix = freshness(snapshot)
        guard !selection.events.isEmpty else {
            return prefix + "No matching upcoming events in the available Recreational Sports feed."
        }
        let events = selection.events.prefix(3).map { "\($0.title), \(dateText($0.startDate))" }.joined(separator: "; ")
        let partial = (snapshot.rejectedRecordCount ?? 0) > 0 ? " Some source records could not be read." : ""
        return prefix + "Returning \(selection.events.count) of \(selection.matchingCount) matching events. " + events + "." + partial
    }

    static func details(_ event: Event?, snapshot: EventsSnapshot) -> String {
        guard let event else {
            return snapshot.status == .unavailable ? "Event details are unavailable right now."
                : freshness(snapshot) + "This event is absent from the available upcoming-events feed."
        }
        var parts = [event.title, "\(dateText(event.startDate)) to \(dateText(event.endDate))"]
        if !event.location.isEmpty { parts.append("Location: \(event.location)") }
        if !event.hostingBody.isEmpty { parts.append("Organizer: \(event.hostingBody)") }
        parts.append(event.priceText.isEmpty ? "Price not provided" : "Price: \(event.priceText)")
        return freshness(snapshot) + parts.joined(separator: ". ") + "."
    }
}

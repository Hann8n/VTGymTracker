import Foundation

// MARK: - CampusGroupsEventsParser

private struct CampusGroupsEventItem: Decodable {
    private let valuesByField: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CampusGroupsCodingKey.self)
        let fields = try container.decode(String.self, forKey: CampusGroupsCodingKey(stringValue: "fields")!)
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }

        let keyedValues = container.allKeys.reduce(into: [Int: String]()) { values, key in
            guard key.stringValue.hasPrefix("p"),
                  let index = Int(key.stringValue.dropFirst()),
                  let value = try? container.decodeIfPresent(String.self, forKey: key)
            else { return }
            values[index] = value
        }

        valuesByField = fields.enumerated().reduce(into: [String: String]()) { values, field in
            values[field.element] = keyedValues[field.offset]
        }
    }

    func value(for field: String) -> String? {
        valuesByField[field]
    }
}

private struct CampusGroupsCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

struct CampusGroupsEventsParser {
    private let baseURL = Constants.eventsBaseURL

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: Constants.eventsTimeZoneIdentifier)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.isLenient = false
        formatter.dateFormat = "E, MMM d, yyyy h:mm a"
        return formatter
    }()

    func parse(data: Data, now: Date = Date()) throws -> [Event] {
        try parseFeed(data: data, now: now).events
    }

    func parseFeed(data: Data, now: Date) throws -> ParsedEventsFeed {
        let items = try JSONDecoder().decode([CampusGroupsEventItem].self, from: data)
        var rejectedCount = 0
        var seen = Set<String>()
        let events: [Event] = items.compactMap { item in
            guard item.value(for: "displayType") == "event" else { return nil }
            guard let title = item.value(for: "eventName")?.decodedCampusGroupsText, !title.isEmpty,
                  let dateHTML = item.value(for: "eventDates"), let dates = parseDates(from: dateHTML),
                  let rawURL = item.value(for: "eventUrl"), !rawURL.isEmpty,
                  let link = URL(string: rawURL, relativeTo: baseURL)?.absoluteURL,
                  link.scheme == "https", link.host == baseURL.host, link.path != "/" else {
                rejectedCount += 1
                return nil
            }
            let zoneText = item.value(for: "eventTimezone")?.decodedCampusGroupsText.nilIfEmpty
            // A supplied zone must agree with the campus calendar; never silently reinterpret it.
            if let zoneText, !validTimeZone(zoneText, at: dates.startDate) {
                rejectedCount += 1
                return nil
            }
            guard dates.endDate > now else { return nil }
            let event = Event(
                title: title,
                description: "",
                link: link,
                pubDate: now,
                endDate: dates.endDate,
                hostingBody: item.value(for: "clubName")?.decodedCampusGroupsText ?? "",
                startDate: dates.startDate,
                location: item.value(for: "eventLocation")?.decodedCampusGroupsText ?? "",
                imageURL: item.value(for: "eventPicture").flatMap { URL(string: $0, relativeTo: baseURL)?.absoluteURL },
                priceText: item.value(for: "eventPriceRange")?.decodedCampusGroupsText ?? "",
                actionText: item.value(for: "eventButtonLabel")?.decodedCampusGroupsText.nilIfEmpty ?? "View",
                attendeeCount: item.value(for: "eventAttendees").flatMap(Int.init),
                sourceID: item.value(for: "eventId")?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                sourceTimeZoneText: zoneText
            )
            guard seen.insert(event.stableIdentifier).inserted else { return nil }
            return event
        }
        if events.isEmpty && rejectedCount > 0 { throw EventsServiceError.invalidFeed }
        return ParsedEventsFeed(events: events, rejectedCount: rejectedCount)
    }

    private func validTimeZone(_ text: String, at date: Date) -> Bool {
        let zone = TimeZone(identifier: Constants.eventsTimeZoneIdentifier)
        let offset = zone?.secondsFromGMT(for: date)
        return (offset == -4 * 3600 && text == "EDT (GMT-4)")
            || (offset == -5 * 3600 && text == "EST (GMT-5)")
            || text == Constants.eventsTimeZoneIdentifier
    }

    private var campusCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: Constants.eventsTimeZoneIdentifier) ?? .gmt
        return calendar
    }

    private func parseDates(from html: String) -> (startDate: Date, endDate: Date)? {
        let parts = html.paragraphContents
        guard parts.count == 2 else { return nil }

        let dateText = parts[0].decodedCampusGroupsText
        let timeRange = parts[1].decodedCampusGroupsText
        let times = timeRange.components(separatedBy: "–").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard times.count == 2, let rawStartTime = times.first, !rawStartTime.isEmpty, !times[1].isEmpty else { return nil }

        let startMeridiem = rawStartTime.meridiemSuffix
        var rawEndTime = times.dropFirst().first ?? rawStartTime
        if rawEndTime.meridiemSuffix == nil, let startMeridiem {
            rawEndTime += " \(startMeridiem)"
        }

        let startTime = rawStartTime.normalizedClockTime
        let endTime = rawEndTime.normalizedClockTime
        guard let startDate = dateFormatter.date(from: "\(dateText) \(startTime)") else { return nil }
        guard var endDate = dateFormatter.date(from: "\(dateText) \(endTime)") else { return nil }

        if endDate < startDate, let nextDay = campusCalendar.date(byAdding: .day, value: 1, to: endDate) {
            endDate = nextDay
        }

        guard endDate > startDate else { return nil }
        return (startDate, endDate)
    }
}

// MARK: - CampusGroups String Helpers

private extension String {
    var decodedCampusGroupsText: String {
        replacingOccurrences(of: "&ndash;", with: "–")
            .replacingOccurrences(of: "&mdash;", with: "—")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .strippingHTMLTags
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var paragraphContents: [String] {
        do {
            let regex = try NSRegularExpression(pattern: "<p[^>]*>(.*?)</p>", options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(startIndex..<endIndex, in: self)
            return regex.matches(in: self, range: range).compactMap { match in
                guard let contentRange = Range(match.range(at: 1), in: self) else { return nil }
                return String(self[contentRange])
            }
        } catch {
            return []
        }
    }

    var strippingHTMLTags: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    var meridiemSuffix: String? {
        let uppercasedText = uppercased()
        if uppercasedText.hasSuffix("AM") { return "AM" }
        if uppercasedText.hasSuffix("PM") { return "PM" }
        return nil
    }

    var normalizedClockTime: String {
        replacingOccurrences(
            of: "^(\\d{1,2})\\s+(AM|PM)$",
            with: "$1:00 $2",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

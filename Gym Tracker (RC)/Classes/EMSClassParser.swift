import Foundation

enum EMSClassParserError: Error { case invalidResponse }

/// Reads EMS `CustomBrowseEvents` responses: `{"d": "<JSON string>"}` whose inner object lists
/// bookings under `DailyBookingResults` or `MonthlyBookingResults`. Keeps Rec Sports' own class-room bookings only.
enum EMSClassParser {
    static func parse(_ data: Data, roomKeywords: [String] = Constants.classRoomKeywords) throws -> [GymClass] {
        guard let outer = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EMSClassParserError.invalidResponse
        }
        let inner: [String: Any]?
        if let text = outer["d"] as? String {
            inner = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]
        } else {
            inner = outer["d"] as? [String: Any]
        }
        guard let inner else { throw EMSClassParserError.invalidResponse }
        let lists = ["DailyBookingResults", "MonthlyBookingResults"].compactMap { inner[$0] as? [[String: Any]] }
        guard !lists.isEmpty else { throw EMSClassParserError.invalidResponse }

        var seen = Set<String>()
        return lists.joined().compactMap { booking -> GymClass? in
            guard let id = string(booking["Id"] ?? booking["ReservationId"]),
                  let title = (booking["EventName"] as? String).map(decoded), !title.isEmpty,
                  let room = (booking["Room"] as? String).map(decoded),
                  let start = date(booking["GmtStart"]), let end = date(booking["GmtEnd"]), end > start,
                  roomKeywords.contains(where: { room.localizedCaseInsensitiveContains($0) }),
                  booking["GroupName"] as? String == Constants.classGroupName,
                  !Constants.classTitleExclusions.contains(where: { title.localizedCaseInsensitiveContains($0) }),
                  seen.insert(id).inserted else { return nil }
            return GymClass(id: id, title: title, room: room, start: start, end: end)
        }
        .sorted { ($0.start, $0.title) < ($1.start, $1.title) }
    }

    // MARK: - Field Helpers

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let text as String: return text.isEmpty ? nil : text
        case let number as NSNumber: return number.stringValue
        default: return nil
        }
    }

    /// GMT times arrive as `2026-10-20T14:00:00` (optionally with fraction or zone) or `/Date(ms)/`.
    private static func date(_ value: Any?) -> Date? {
        guard let text = value as? String else { return nil }
        if text.hasPrefix("/Date("), let ms = Double(text.dropFirst(6).prefix { $0.isNumber || $0 == "-" }) {
            return Date(timeIntervalSince1970: ms / 1000)
        }
        let trimmed = String(text.prefix(19))
        return gmtFormatter.date(from: trimmed)
    }

    private static let gmtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static func decoded(_ text: String) -> String {
        var result = text
        while result.contains("&amp;") { result = result.replacingOccurrences(of: "&amp;", with: "&") }
        for (entity, character) in [("&#39;", "'"), ("&quot;", "\""), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " ")] {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

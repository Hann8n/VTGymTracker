import Foundation

/// RecSports returns identical desktop/mobile canvas readings, rather than JSON.
enum OccupancyHTMLParser {
    static func parse(_ html: String, capacity: Int? = nil, facilityID: String? = nil) -> (occupancy: Int, remaining: Int)? {
        guard let regex = try? NSRegularExpression(pattern: "<canvas\\b[^>]*>", options: .caseInsensitive) else { return nil }
        // Error-page comments and script templates are not rendered occupancy readings.
        let html = html.replacingOccurrences(of: "(?s)<!--.*?-->|<script\\b[^>]*>.*?</script\\s*>", with: "",
                                             options: [.regularExpression, .caseInsensitive])
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..<html.endIndex, in: html))
        var reading: (occupancy: Int, remaining: Int)?
        for match in matches {
            guard let range = Range(match.range, in: html) else { return nil }
            let tag = String(html[range])
            guard tag.lowercased().contains("data-occupancy") || tag.lowercased().contains("data-remaining") else { continue }
            if let facilityID {
                let expected = "occupancyChart-" + facilityID
                guard let id = attributeValue(tag, attribute: "id"), id == expected || id == expected + "-sm" else { return nil }
            }
            guard var occupancy = extractInt(tag, attribute: "data-occupancy"),
                  let remaining = extractInt(tag, attribute: "data-remaining") else { return nil }
            if let capacity {
                // Swipes can push the count past capacity; RecSports then reports 0 remaining and shows 100%.
                if remaining == 0, occupancy > capacity { occupancy = capacity }
                guard capacity > 0, occupancy <= capacity, remaining <= capacity,
                      occupancy == capacity - remaining else { return nil }
            }
            if let reading, reading.occupancy != occupancy || reading.remaining != remaining { return nil }
            reading = (occupancy, remaining)
        }
        return reading
    }

    private static func extractInt(_ tag: String, attribute: String) -> Int? {
        guard let value = attributeValue(tag, attribute: attribute), !value.isEmpty,
              value.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
        return Int(value)
    }

    private static func attributeValue(_ tag: String, attribute: String) -> String? {
        let prefix = "(?<![\\w-])" + attribute + "\\s*=\\s*"
        guard let names = try? NSRegularExpression(pattern: prefix, options: .caseInsensitive),
              names.numberOfMatches(in: tag, range: NSRange(tag.startIndex..<tag.endIndex, in: tag)) == 1,
              let regex = try? NSRegularExpression(pattern: prefix + "([\"'])(.*?)\\1", options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: tag, range: NSRange(tag.startIndex..<tag.endIndex, in: tag)),
              let range = Range(match.range(at: 2), in: tag) else { return nil }
        return String(tag[range])
    }
}

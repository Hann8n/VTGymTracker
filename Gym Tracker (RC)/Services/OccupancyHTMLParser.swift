import Foundation

// Extracts occupancy data from HTML response; API returns HTML with data-occupancy attributes, not JSON
enum OccupancyHTMLParser {

    /// Occupancy is required; remaining is optional because callers can derive it from capacity.
    /// A missing or unexpected `data-remaining` (e.g. negative when a facility is over capacity)
    /// must never discard a valid occupancy count.
    static func parse(_ html: String) -> (occupancy: Int, remaining: Int?)? {
        guard let o = extractInt(html, attribute: "data-occupancy") else { return nil }
        let r = extractInt(html, attribute: "data-remaining")
        return (max(0, o), r.map { max(0, $0) })
    }

    // Regex parsing avoids external HTML parser dependency; simple attribute extraction is sufficient.
    // Tolerates single/double/no quotes, surrounding whitespace, a leading sign and thousands separators.
    private static func extractInt(_ html: String, attribute: String) -> Int? {
        let pattern = attribute + #"\s*=\s*["']?\s*(-?[0-9][0-9,]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let captureRange = Range(match.range(at: 1), in: html)
        else { return nil }
        return Int(html[captureRange].replacingOccurrences(of: ",", with: ""))
    }
}

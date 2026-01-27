import Foundation

// Extracts occupancy data from HTML response; API returns HTML with data-occupancy attributes, not JSON
enum OccupancyHTMLParser {

    static func parse(_ html: String) -> (occupancy: Int, remaining: Int)? {
        guard let o = extractInt(html, attribute: "data-occupancy"),
              let r = extractInt(html, attribute: "data-remaining")
        else { return nil }
        return (o, r)
    }

    // Regex parsing avoids external HTML parser dependency; simple attribute extraction is sufficient
    private static func extractInt(_ html: String, attribute: String) -> Int? {
        let pattern = attribute + "=\"([0-9]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let captureRange = Range(match.range(at: 1), in: html)
        else { return nil }
        return Int(html[captureRange])
    }
}

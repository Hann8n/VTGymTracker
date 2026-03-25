//
//  AdConfig.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import Foundation

struct AdConfig: Codable, Equatable {
    let id: String
    let active: Bool
    let sponsor: String
    let headline: String
    let subline: String?
    let cta: String
    let destinationURL: URL
    let imageURL: URL?
    let logoURL: URL?
    let creativeVersion: String
    let placement: String
    let startAt: Date
    let endAt: Date
    let tier: String

    enum CodingKeys: String, CodingKey {
        case id
        case active
        case sponsor
        case headline
        case subline
        case cta
        case destinationURL = "destination_url"
        case imageURL = "image_url"
        case logoURL = "logo_url"
        case creativeVersion = "creative_version"
        case placement
        case startAt = "start_at"
        case endAt = "end_at"
        case tier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        active = try container.decode(Bool.self, forKey: .active)
        sponsor = try container.decode(String.self, forKey: .sponsor)
        headline = try container.decode(String.self, forKey: .headline)
        subline = try container.decodeIfPresent(String.self, forKey: .subline)
        cta = try container.decode(String.self, forKey: .cta)
        destinationURL = try container.decode(URL.self, forKey: .destinationURL)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
        creativeVersion = try container.decodeIfPresent(String.self, forKey: .creativeVersion) ?? ""
        placement = try container.decodeIfPresent(String.self, forKey: .placement) ?? Constants.adPlacementHomeFeed

        // Handle partial dates: API may send only start_at, only end_at, or both.
        let startAtRaw = try container.decodeIfPresent(String.self, forKey: .startAt)
        let endAtRaw = try container.decodeIfPresent(String.self, forKey: .endAt)
        startAt = (startAtRaw.flatMap(AdConfig.parseISO8601)) ?? .distantPast
        endAt = (endAtRaw.flatMap(AdConfig.parseISO8601)) ?? .distantFuture

        tier = (try container.decodeIfPresent(String.self, forKey: .tier) ?? "banner").lowercased()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(active, forKey: .active)
        try container.encode(sponsor, forKey: .sponsor)
        try container.encode(headline, forKey: .headline)
        try container.encodeIfPresent(subline, forKey: .subline)
        try container.encode(cta, forKey: .cta)
        try container.encode(destinationURL, forKey: .destinationURL)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
        try container.encode(creativeVersion, forKey: .creativeVersion)
        try container.encode(placement, forKey: .placement)
        try container.encode(AdConfig.dateFormatter.string(from: startAt), forKey: .startAt)
        try container.encode(AdConfig.dateFormatter.string(from: endAt), forKey: .endAt)
        try container.encode(tier, forKey: .tier)
    }

    /// Mock ads from `devConfig(tier:)` use `dev_*` ids; they must not persist when switching to a live API fetch.
    var isDevelopmentPreview: Bool {
        id.hasPrefix("dev_")
    }

    var isCurrentlyActive: Bool {
        let now = Date()
        guard active
            && placement == Constants.adPlacementHomeFeed
            && startAt <= now
            && now <= endAt
            && destinationURL.scheme?.lowercased() == "https"
        else { return false }
        if tier.lowercased() == "text" {
            return true
        }
        guard let url = imageURL else { return false }
        return url.scheme?.lowercased() == "https"
    }

    var usesImageLayout: Bool {
        guard imageURL != nil else { return false }
        return tier.lowercased() != "text"
    }

    var destinationHost: String {
        destinationURL.host ?? "unknown"
    }

    // MARK: - Development preview configs

    static func devConfig(tier: String) -> AdConfig? {
        let json: String
        switch tier.lowercased() {
        case "text":
            json = """
            {"id":"dev_text","tier":"text","sponsor":"Benny's Coffee Co.","logo_url":"https://picsum.photos/64","headline":"Study fuel. 10% off with your student ID.","subline":"127 N Main St · Open 7am–10pm","cta":"Get the deal","destination_url":"https://bennyscoffee.com/vt","active":true}
            """
        case "banner":
            json = """
            {"id":"dev_banner","tier":"banner","sponsor":"Off Campus Bookstore","image_url":"https://picsum.photos/400/140","logo_url":"https://picsum.photos/65","headline":"Textbooks, gear & more. Free pickup in Blacksburg.","subline":"Save on textbooks, VT gear & more.","cta":"Shop now","destination_url":"https://example.com","active":true}
            """
        case "feature":
            json = """
            {"id":"dev_feature","tier":"feature","sponsor":"Sharkey's Billiards","image_url":"https://picsum.photos/400/220","logo_url":"https://picsum.photos/66","headline":"Post-workout happy hour. $3 drafts 4–7pm every weekday.","subline":"123 N Main St · Pool, darts & more.","cta":"See menu","destination_url":"https://example.com","active":true}
            """
        default:
            return nil
        }
        return try? JSONDecoder().decode(AdConfig.self, from: Data(json.utf8))
    }

    private static func parseISO8601(_ value: String) -> Date? {
        if let date = dateFormatterWithFractionalSeconds.date(from: value) {
            return date
        }
        return dateFormatter.date(from: value)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

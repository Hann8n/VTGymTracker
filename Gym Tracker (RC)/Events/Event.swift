//
//  Event.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import Foundation

struct Event: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let link: URL
    let pubDate: Date
    let endDate: Date
    let hostingBody: String
    let startDate: Date
    let location: String
    let imageURL: URL?
    let priceText: String
    let actionText: String
    let attendeeCount: Int?

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        link: URL,
        pubDate: Date,
        endDate: Date,
        hostingBody: String,
        startDate: Date,
        location: String,
        imageURL: URL? = nil,
        priceText: String = "",
        actionText: String = "View",
        attendeeCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.link = link
        self.pubDate = pubDate
        self.endDate = endDate
        self.hostingBody = hostingBody
        self.startDate = startDate
        self.location = location
        self.imageURL = imageURL
        self.priceText = priceText
        self.actionText = actionText
        self.attendeeCount = attendeeCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        link = try container.decode(URL.self, forKey: .link)
        pubDate = try container.decode(Date.self, forKey: .pubDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        hostingBody = try container.decode(String.self, forKey: .hostingBody)
        startDate = try container.decode(Date.self, forKey: .startDate)
        location = try container.decode(String.self, forKey: .location)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        priceText = try container.decodeIfPresent(String.self, forKey: .priceText) ?? ""
        actionText = try container.decodeIfPresent(String.self, forKey: .actionText) ?? "View"
        attendeeCount = try container.decodeIfPresent(Int.self, forKey: .attendeeCount)
    }
}

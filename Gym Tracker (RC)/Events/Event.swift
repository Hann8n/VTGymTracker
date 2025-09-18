//
//  Event.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import Foundation

struct Event: Identifiable, Codable { // Added Codable conformance
    let id: UUID
    let title: String
    let description: String
    let link: URL
    let pubDate: Date
    let endDate: Date
    let hostingBody: String
    let startDate: Date
    let location: String
    
    // Initializer with default id
    init(id: UUID = UUID(), title: String, description: String, link: URL, pubDate: Date, endDate: Date, hostingBody: String, startDate: Date, location: String) {
        self.id = id
        self.title = title
        self.description = description
        self.link = link
        self.pubDate = pubDate
        self.endDate = endDate
        self.hostingBody = hostingBody
        self.startDate = startDate
        self.location = location
    }
}

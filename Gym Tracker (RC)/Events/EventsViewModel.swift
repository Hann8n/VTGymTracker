//
//  EventsViewModel.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import Foundation
import Combine
import PostHog

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case noInternet
    case fetchFailed(description: String)
    case noData
    case parseFailed
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "Please check your internet connection"
        case .fetchFailed(_):
            return "Unable to load events right now"
        case .noData:
            return "No events available at the moment"
        case .parseFailed:
            return "Unable to load events right now"
        }
    }
}

// MARK: - EventsViewModel

class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor: NetworkMonitor
    
    // Cache directory allows system to clear temporary data when storage is low
    private var cacheFileURL: URL {
        let fm = FileManager.default
        let cachesDir = try? fm.url(for: .cachesDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        return cachesDir?.appendingPathComponent("cachedEvents.json") ?? URL(fileURLWithPath: "cachedEvents.json")
    }
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        setupNetworkMonitor()
        
        // Load cache immediately to display events without network delay
        let cachedEvents = loadCache()
        if !cachedEvents.isEmpty {
            self.events = cachedEvents
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitor() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if !isConnected {
                    if self.events.isEmpty {
                        let cachedEvents = self.loadCache()
                        if cachedEvents.isEmpty {
                            self.errorMessage = NetworkError.noInternet.errorDescription
                        } else {
                            self.events = cachedEvents
                            self.errorMessage = nil
                        }
                    }
                } else {
                    // Refetch on reconnect to ensure data freshness after network outage
                    if self.errorMessage == NetworkError.noInternet.errorDescription {
                        self.errorMessage = nil
                        self.fetchEvents()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents() {
        guard networkMonitor.isConnected else {
            DispatchQueue.main.async {
                let cachedEvents = self.loadCache()
                if cachedEvents.isEmpty {
                    self.errorMessage = NetworkError.noInternet.errorDescription
                } else {
                    self.events = cachedEvents
                    self.errorMessage = nil
                }
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        let task = URLSession.shared.dataTask(with: Constants.recreationalSportsEventsURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.useCachedEventsOrShowError(NetworkError.fetchFailed(description: error.localizedDescription))
                    PostHogSDK.shared.capture("events_fetch_failed", properties: [
                        "reason": "network_error",
                        "error": error.localizedDescription,
                    ])
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    self.useCachedEventsOrShowError(NetworkError.fetchFailed(description: "HTTP \(httpResponse.statusCode)"))
                    PostHogSDK.shared.capture("events_fetch_failed", properties: [
                        "reason": "bad_status",
                        "status_code": httpResponse.statusCode,
                    ])
                    return
                }

                guard let data = data else {
                    self.useCachedEventsOrShowError(NetworkError.noData)
                    PostHogSDK.shared.capture("events_fetch_failed", properties: ["reason": "no_data"])
                    return
                }

                do {
                    let parsedEvents = try CampusGroupsEventsParser().parse(data: data)
                    self.events = parsedEvents
                    self.errorMessage = nil
                    self.saveCache(with: parsedEvents)
                } catch {
                    self.useCachedEventsOrShowError(NetworkError.parseFailed)
                    PostHogSDK.shared.capture("events_fetch_failed", properties: [
                        "reason": "parse_failed",
                        "error": error.localizedDescription,
                    ])
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Caching Methods
    
    private func saveCache(with events: [Event]) {
        // Only cache future events; expired events are irrelevant
        let upcomingEvents = events.filter { $0.endDate > Date() }
        do {
            let data = try JSONEncoder().encode(upcomingEvents)
            try data.write(to: cacheFileURL, options: .atomic)
        } catch {
            print("Error saving cache: \(error)")
        }
    }
    
    private func loadCache() -> [Event] {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let events = try JSONDecoder().decode([Event].self, from: data)
            // Filter again in case cache contains stale events from previous sessions
            return events.filter { $0.endDate > Date() }
        } catch {
            print("Error loading cache: \(error)")
            return []
        }
    }

    private func useCachedEventsOrShowError(_ error: NetworkError) {
        let cachedEvents = loadCache()
        if cachedEvents.isEmpty {
            errorMessage = error.errorDescription
        } else {
            events = cachedEvents
            errorMessage = nil
        }
    }
}

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

private struct CampusGroupsEventsParser {
    private let baseURL = URL(string: "https://virginiatech.campusgroups.com")!

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "E, MMM d, yyyy h:mm a"
        return formatter
    }()

    func parse(data: Data) throws -> [Event] {
        let items = try JSONDecoder().decode([CampusGroupsEventItem].self, from: data)
        let now = Date()

        return items.compactMap { item in
            guard item.value(for: "displayType") == "event" else { return nil }
            guard let title = item.value(for: "eventName")?.decodedCampusGroupsText, !title.isEmpty else { return nil }
            guard let dateHTML = item.value(for: "eventDates"), let dates = parseDates(from: dateHTML) else { return nil }
            guard dates.endDate > now else { return nil }

            let location = item.value(for: "eventLocation")?.decodedCampusGroupsText.nilIfEmpty ?? ""
            let hostingBody = item.value(for: "clubName")?.decodedCampusGroupsText.nilIfEmpty ?? "Recreational Sports"
            let link = item.value(for: "eventUrl").flatMap { URL(string: $0, relativeTo: baseURL) }?.absoluteURL ?? baseURL
            let imageURL = item.value(for: "eventPicture").flatMap { URL(string: $0, relativeTo: baseURL) }?.absoluteURL
            let priceText = item.value(for: "eventPriceRange")?.decodedCampusGroupsText.nilIfEmpty ?? ""
            let actionText = item.value(for: "eventButtonLabel")?.decodedCampusGroupsText.nilIfEmpty ?? "View"
            let attendeeCount = item.value(for: "eventAttendees").flatMap(Int.init)

            return Event(
                title: title,
                description: "",
                link: link,
                pubDate: now,
                endDate: dates.endDate,
                hostingBody: hostingBody,
                startDate: dates.startDate,
                location: location,
                imageURL: imageURL,
                priceText: priceText,
                actionText: actionText,
                attendeeCount: attendeeCount
            )
        }
    }

    private func parseDates(from html: String) -> (startDate: Date, endDate: Date)? {
        let parts = html.paragraphContents
        guard parts.count >= 2 else { return nil }

        let dateText = parts[0].decodedCampusGroupsText
        let timeRange = parts[1].decodedCampusGroupsText
        let times = timeRange.components(separatedBy: "–").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let rawStartTime = times.first, !rawStartTime.isEmpty else { return nil }

        let startMeridiem = rawStartTime.meridiemSuffix
        var rawEndTime = times.dropFirst().first ?? rawStartTime
        if rawEndTime.meridiemSuffix == nil, let startMeridiem {
            rawEndTime += " \(startMeridiem)"
        }

        let startTime = rawStartTime.normalizedClockTime
        let endTime = rawEndTime.normalizedClockTime
        guard let startDate = dateFormatter.date(from: "\(dateText) \(startTime)") else { return nil }
        guard var endDate = dateFormatter.date(from: "\(dateText) \(endTime)") else { return nil }

        if endDate < startDate, let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) {
            endDate = nextDay
        }

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

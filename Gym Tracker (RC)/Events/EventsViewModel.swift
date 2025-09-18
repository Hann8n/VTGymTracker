//
//  EventsViewModel.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//
//  This file defines the EventsViewModel which is responsible for
//  fetching events from an RSS feed, monitoring network connectivity,
//  and caching upcoming events (those whose endDate is in the future).
//

import Foundation
import Combine

// MARK: - NetworkError
// Define possible network errors that can occur while fetching events.
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
// This view model fetches events from an RSS feed, updates the UI,
// and manages caching of upcoming events.
class EventsViewModel: ObservableObject {
    // Published properties to update the UI.
    @Published var events: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Private properties.
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor: NetworkMonitor
    
    // RSS Feed URL (unchanged).
    private let rssURL = URL(string: "https://gobblerconnect.vt.edu/organization/www_recsports_vt_edu/events.rss")!
    
    // Cache file location: stored in the app's caches directory.
    private var cacheFileURL: URL {
        let fm = FileManager.default
        // Get the caches directory URL for the user domain.
        let cachesDir = try? fm.url(for: .cachesDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        // Append the filename for cached events.
        return cachesDir?.appendingPathComponent("cachedEvents.json") ?? URL(fileURLWithPath: "cachedEvents.json")
    }
    
    // Initializer with dependency injection for NetworkMonitor.
    // Loads cached events immediately if available.
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        setupNetworkMonitor()
        
        // Attempt to load cached events (if available) so the UI displays them immediately.
        let cachedEvents = loadCache()
        if !cachedEvents.isEmpty {
            self.events = cachedEvents
        }
    }
    
    // MARK: - Network Monitoring
    // Sets up network connectivity monitoring to handle changes in connection state.
    private func setupNetworkMonitor() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if !isConnected {
                    // Set error message if no internet.
                    self.errorMessage = NetworkError.noInternet.errorDescription
                } else {
                    // When connection is restored, clear the error message and optionally refetch events.
                    if self.errorMessage == NetworkError.noInternet.errorDescription {
                        self.errorMessage = nil
                        self.fetchEvents()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Events
    // Fetches events from the RSS feed without performing a Google connectivity check.
    func fetchEvents() {
        // Check network connectivity before attempting to fetch.
        guard networkMonitor.isConnected else {
            DispatchQueue.main.async {
                self.errorMessage = NetworkError.noInternet.errorDescription
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Directly fetch the RSS feed.
        let task = URLSession.shared.dataTask(with: self.rssURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Handle errors during fetch.
                if let error = error {
                    self?.errorMessage = NetworkError.fetchFailed(description: error.localizedDescription).errorDescription
                    return
                }
                
                // Check that data was received.
                guard let data = data else {
                    self?.errorMessage = NetworkError.noData.errorDescription
                    return
                }
                
                // Parse the fetched RSS feed.
                let parser = RSSParser()
                if let parsedEvents = parser.parse(data: data) {
                    // Update the in-memory events.
                    self?.events = parsedEvents
                    // Save only upcoming events (those with an endDate in the future) to cache.
                    self?.saveCache(with: parsedEvents)
                } else {
                    self?.errorMessage = NetworkError.parseFailed.errorDescription
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Caching Methods
    
    /// Saves upcoming events to a local JSON cache file.
    /// - Parameter events: The full list of fetched events.
    private func saveCache(with events: [Event]) {
        // Filter events to include only those that have not ended.
        let upcomingEvents = events.filter { $0.endDate > Date() }
        do {
            // Encode the upcoming events into JSON.
            let data = try JSONEncoder().encode(upcomingEvents)
            // Write the JSON data to the cache file atomically.
            try data.write(to: cacheFileURL, options: .atomic)
        } catch {
            print("Error saving cache: \(error)")
        }
    }
    
    /// Loads cached events from the local JSON cache file.
    /// - Returns: An array of upcoming events, or an empty array if loading fails.
    private func loadCache() -> [Event] {
        do {
            // Read the data from the cache file.
            let data = try Data(contentsOf: cacheFileURL)
            // Decode the JSON data into an array of Event objects.
            let events = try JSONDecoder().decode([Event].self, from: data)
            // Return only events that are still upcoming.
            return events.filter { $0.endDate > Date() }
        } catch {
            print("Error loading cache: \(error)")
            return []
        }
    }
}

// MARK: - RSSParser
// RSSParser is provided here so that no other files need to change.
// It parses the RSS XML feed into an array of Event objects.
class RSSParser: NSObject, XMLParserDelegate {
    private var events: [Event] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentStartDate = ""
    private var currentEndDate = ""
    private var currentLocation = ""
    private var currentHostingBody = ""
    
    // DateFormatter to parse dates in the RSS feed.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Expected format: "Tue, 14 Jan 2025 22:15:11 GMT"
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    /// Parses XML data and returns an array of Event objects.
    /// - Parameter data: The XML data to parse.
    /// - Returns: An array of Event objects if parsing succeeds, otherwise nil.
    func parse(data: Data) -> [Event]? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        return parser.parse() ? events : nil
    }
    
    // MARK: - XMLParserDelegate Methods
    
    // Called when the parser starts a new element.
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        // When a new "item" element starts, reset the current event properties.
        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentStartDate = ""
            currentEndDate = ""
            currentLocation = ""
            currentHostingBody = ""
        }
    }
    
    // Called when the parser finds characters within an element.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Remove unnecessary whitespace.
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Append the trimmed string to the appropriate property based on the current element.
        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "description":
            currentDescription += trimmed
        case "link":
            currentLink += trimmed
        case "pubDate":
            currentPubDate += trimmed
        case "start":
            currentStartDate += trimmed
        case "end":
            currentEndDate += trimmed
        case "location":
            currentLocation += trimmed
        case "host":
            // Concatenate multiple host values if needed.
            if currentHostingBody.isEmpty {
                currentHostingBody = trimmed
            } else {
                currentHostingBody += ", \(trimmed)"
            }
        default:
            break
        }
    }
    
    // Called when the parser ends an element.
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // Validate and create an Event object.
            guard
                let linkURL = URL(string: currentLink),
                let pubDate = dateFormatter.date(from: currentPubDate),
                let startDate = dateFormatter.date(from: currentStartDate),
                let endDate = dateFormatter.date(from: currentEndDate)
            else { return }
            
            let event = Event(
                title: currentTitle,
                description: currentDescription,
                link: linkURL,
                pubDate: pubDate,
                endDate: endDate,
                hostingBody: currentHostingBody,
                startDate: startDate,
                location: currentLocation
            )
            events.append(event)
        }
    }
}

//
//  EventsViewModel.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import Foundation
import Combine

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
    
    private let rssURL = URL(string: "https://gobblerconnect.vt.edu/organization/www_recsports_vt_edu/events.rss")!
    
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
                    self.errorMessage = NetworkError.noInternet.errorDescription
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
                self.errorMessage = NetworkError.noInternet.errorDescription
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        let task = URLSession.shared.dataTask(with: self.rssURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = NetworkError.fetchFailed(description: error.localizedDescription).errorDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = NetworkError.noData.errorDescription
                    return
                }
                
                let parser = RSSParser()
                if let parsedEvents = parser.parse(data: data) {
                    self?.events = parsedEvents
                    self?.saveCache(with: parsedEvents)
                } else {
                    self?.errorMessage = NetworkError.parseFailed.errorDescription
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
}

// MARK: - RSSParser

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
    
    // RSS feed uses RFC 822 date format with timezone (e.g., "Tue, 14 Jan 2025 22:15:11 GMT")
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    func parse(data: Data) -> [Event]? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        return parser.parse() ? events : nil
    }
    
    // MARK: - XMLParserDelegate Methods
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        // Each RSS item represents a separate event; reset properties for new event
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
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
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
            // RSS feed may contain multiple host elements per event; concatenate them
            if currentHostingBody.isEmpty {
                currentHostingBody = trimmed
            } else {
                currentHostingBody += ", \(trimmed)"
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
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

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
            return "No internet connection"
        case .fetchFailed(let description):
            return "Failed to fetch events: \(description)"
        case .noData:
            return "No data received."
        case .parseFailed:
            return "Failed to parse events."
        }
    }
}

// MARK: - EventsViewModel

class EventsViewModel: ObservableObject {
    // Published properties to update the UI
    @Published var events: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor: NetworkMonitor
    
    // RSS Feed URL
    private let rssURL = URL(string: "https://gobblerconnect.vt.edu/organization/www_recsports_vt_edu/events.rss")!
    
    // Initializer with dependency injection for NetworkMonitor
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        setupNetworkMonitor()
    }
    
    // Setup network monitoring to handle connectivity changes
    private func setupNetworkMonitor() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if !isConnected {
                    self.errorMessage = NetworkError.noInternet.errorDescription
                } else {
                    // Clear the no-internet error message when connection is restored
                    if self.errorMessage == NetworkError.noInternet.errorDescription {
                        self.errorMessage = nil
                        // Optionally, refetch events when connection is restored
                        self.fetchEvents()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Function to fetch events from the RSS feed
    func fetchEvents() {
        // Check network connectivity before attempting to fetch
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
        
        let task = URLSession.shared.dataTask(with: rssURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    // Corrected assignment using errorDescription
                    self?.errorMessage = NetworkError.fetchFailed(description: error.localizedDescription).errorDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = NetworkError.noData.errorDescription
                    return
                }
                
                // Parse the RSS feed data
                let parser = RSSParser()
                if let parsedEvents = parser.parse(data: data) {
                    self?.events = parsedEvents
                } else {
                    self?.errorMessage = NetworkError.parseFailed.errorDescription
                }
            }
        }
        task.resume()
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z" // Example: "Tue, 14 Jan 2025 22:15:11 GMT"
        return formatter
    }()
    
    // Function to parse XML data and return an array of Event objects
    func parse(data: Data) -> [Event]? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        return parser.parse() ? events : nil
    }
    
    // MARK: - XMLParserDelegate Methods
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            // Reset current event properties
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
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        
        switch currentElement {
        case "title":
            currentTitle += trimmedString
        case "description":
            currentDescription += trimmedString
        case "link":
            currentLink += trimmedString
        case "pubDate":
            currentPubDate += trimmedString
        case "start":
            currentStartDate += trimmedString
        case "end":
            currentEndDate += trimmedString
        case "location":
            currentLocation += trimmedString
        case "host":
            if currentHostingBody.isEmpty {
                currentHostingBody = trimmedString
            } else {
                currentHostingBody += ", \(trimmedString)"
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "item" {
            // Validate and create an Event object
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

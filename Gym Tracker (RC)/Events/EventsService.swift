import Foundation

enum EventsServiceError: LocalizedError {
    case invalidFeed, invalidDateRange, invalidLimit, unavailableFeed

    var errorDescription: String? {
        switch self {
        case .unavailableFeed: return "Recreation events are unavailable from CampusGroups right now."
        case .invalidFeed: return "CampusGroups returned no valid event records."
        case .invalidDateRange: return "The end of the date range must be after its start."
        case .invalidLimit: return "Choose between 1 and 20 results."
        }
    }
}

/// A UI-independent service shared by the existing view model and App Intents.
struct EventsService {
    var session: URLSession = Self.liveSession
    var cache: EventsCacheStore = .shared

    static let liveSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    func fetch(now: @Sendable () -> Date = { Date() }) async -> EventsSnapshot {
        var failure = "Unable to reach CampusGroups."
        do {
            var request = URLRequest(url: Constants.recreationalSportsEventsURL)
            request.timeoutInterval = 12
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let date = now()
            let feed = try CampusGroupsEventsParser().parseFeed(data: data, now: date)
            let snapshot = EventsSnapshot(events: feed.events, status: .live, fetchedAt: date, checkedAt: date,
                                          rejectedRecordCount: feed.rejectedCount, availabilityDetail: nil)
            cache.write(snapshot)
            return snapshot
        } catch is DecodingError {
            failure = "CampusGroups returned an invalid event feed."
        } catch let error as EventsServiceError {
            failure = error.localizedDescription
        } catch {
            if (error as? URLError)?.code == .timedOut { failure = "CampusGroups request timed out." }
        }
        // Evaluate age after the request, and never advance the original successful retrieval time.
        return cache.read(at: now(), failure: failure)
    }
}

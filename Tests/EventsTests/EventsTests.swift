import XCTest
import AppIntents
@testable import GymCrowds

final class EventsTests: XCTestCase {
    private let now = ISO8601DateFormatter().date(from: "2026-10-08T20:00:00Z")!

    private func item(id: String? = "123", title: String = "Climbing &amp; Skills",
                      day: String = "Mon, Oct 12, 2026", times: String = "3 PM &ndash; 5 PM",
                      zone: String? = "EDT (GMT-4)", location: String? = nil,
                      organizer: String? = nil, price: String? = nil, url: String? = "/rsvp_boot?id=123") -> [String: Any] {
        let fields = ["displayType", "eventId", "eventName", "eventDates", "eventTimezone", "eventLocation", "clubName", "eventPriceRange", "eventUrl"]
        let values: [String?] = ["event", id, title, "<p>\(day)</p><p>\(times)</p>", zone, location, organizer, price, url]
        var result: [String: Any] = ["fields": fields.joined(separator: ",") + ","]
        for (index, value) in values.enumerated() { result["p\(index)"] = value.map { $0 as Any } ?? NSNull() }
        return result
    }

    private func data(_ items: [[String: Any]]) throws -> Data { try JSONSerialization.data(withJSONObject: items) }
    private func feed(_ items: [[String: Any]]) throws -> ParsedEventsFeed {
        try CampusGroupsEventsParser().parseFeed(data: data(items), now: now)
    }
    private func snapshot(_ events: [Event], status: EventsDataStatus = .live, at date: Date? = nil) -> EventsSnapshot {
        EventsSnapshot(events: events, status: status, fetchedAt: status == .unavailable ? nil : now,
                       checkedAt: date ?? now, rejectedRecordCount: status == .unavailable ? nil : 0,
                       availabilityDetail: status == .live ? nil : "Live feed unavailable")
    }

    func testEasternTimeInSummerWinterAndOvernight() throws {
        let summer = try XCTUnwrap(feed([item()]).events.first)
        XCTAssertEqual(summer.startDate, ISO8601DateFormatter().date(from: "2026-10-12T19:00:00Z"))
        XCTAssertEqual(summer.endDate, ISO8601DateFormatter().date(from: "2026-10-12T21:00:00Z"))
        let winter = try XCTUnwrap(feed([item(day: "Tue, Nov 10, 2026", times: "11 PM &ndash; 1 AM", zone: "EST (GMT-5)")]).events.first)
        XCTAssertEqual(winter.startDate, ISO8601DateFormatter().date(from: "2026-11-11T04:00:00Z"))
        XCTAssertEqual(winter.endDate, ISO8601DateFormatter().date(from: "2026-11-11T06:00:00Z"))
        let afterDST = try XCTUnwrap(feed([item(day: "Sun, Nov 1, 2026", zone: "EST (GMT-5)")]).events.first)
        XCTAssertEqual(afterDST.startDate, ISO8601DateFormatter().date(from: "2026-11-01T20:00:00Z"))
        XCTAssertThrowsError(try feed([item(zone: "PDT (GMT-7)")]))
        XCTAssertThrowsError(try feed([item(times: "unknown")]))
        XCTAssertThrowsError(try feed([item(times: "3 PM &ndash; 5 PM &ndash; 7 PM")]))
        XCTAssertThrowsError(try feed([item(times: "3 PM")]))
    }

    func testUnknownsStayAbsentAndMissingPriceIsNotFree() throws {
        let event = try XCTUnwrap(feed([item()]).events.first)
        let entity = CampusEventEntity(event, snapshot: snapshot([event]))
        XCTAssertEqual(entity.title, "Climbing & Skills")
        XCTAssertNil(entity.organizer)
        XCTAssertNil(entity.location)
        XCTAssertNil(entity.priceText)
        XCTAssertEqual(entity.timeZoneIdentifier, "America/New_York")
        XCTAssertEqual(entity.sourceTimeZoneText, "EDT (GMT-4)")
        XCTAssertEqual(entity.eventURL?.absoluteString, "https://virginiatech.campusgroups.com/rsvp_boot?id=123")
        let text = EventsDialog.details(event, snapshot: snapshot([event]))
        XCTAssertTrue(text.contains("Price not provided"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("free"))
        XCTAssertFalse(text.contains("Recreational Sports"))
        let explicit = try XCTUnwrap(feed([item(location: "Private Location (sign in to display)", organizer: "Rec Sports", price: "$5 – $10")]).events.first)
        let rich = CampusEventEntity(explicit, snapshot: snapshot([explicit]))
        XCTAssertEqual(rich.location, "Private Location (sign in to display)")
        XCTAssertEqual(rich.organizer, "Rec Sports")
        XCTAssertEqual(rich.priceText, "$5 – $10")
        XCTAssertTrue(EventsDialog.details(explicit, snapshot: snapshot([explicit])).contains("Price: $5 – $10"))
        let free = try XCTUnwrap(feed([item(price: "FREE")]).events.first)
        XCTAssertEqual(CampusEventEntity(free, snapshot: snapshot([free])).priceText, "FREE")
    }

    func testStableIdentityAndPredictableTitleDisambiguation() throws {
        let first = try XCTUnwrap(feed([item()]).events.first)
        let refreshed = try XCTUnwrap(feed([item(title: "Renamed event")]).events.first)
        XCTAssertEqual(first.stableIdentifier, "campusgroups:123")
        XCTAssertEqual(first.stableIdentifier, refreshed.stableIdentifier)
        let fallback = try XCTUnwrap(feed([item(id: nil)]).events.first)
        XCTAssertEqual(fallback.stableIdentifier, "campusgroups-url:https://virginiatech.campusgroups.com/rsvp_boot?id=123")
        let sameTitle = try feed([item(id: "124"), item(id: "123")]).events
        let current = snapshot(sameTitle)
        XCTAssertEqual(CampusEventQuery.match("climbing", snapshot: current).map(\.id), ["campusgroups:123", "campusgroups:124"])
        XCTAssertEqual(CampusEventQuery.resolve(["campusgroups:124", "missing"], snapshot: current).map(\.id), ["campusgroups:124"])
        XCTAssertTrue(CampusEventQuery.match(" ", snapshot: current).isEmpty)
        XCTAssertEqual(try feed([item(), item()]).events.count, 1)
    }

    func testDateIntervalOverlapBoundaryOrderingAndLimit() throws {
        func event(_ id: String, _ start: TimeInterval, _ end: TimeInterval) -> Event {
            Event(title: id, description: "", link: Constants.eventsBaseURL, pubDate: now,
                  endDate: now.addingTimeInterval(end), hostingBody: "", startDate: now.addingTimeInterval(start),
                  location: "", sourceID: id)
        }
        let current = snapshot([event("ended", -100, 0), event("ongoing", -100, 50), event("b", 20, 40), event("a", 20, 40), event("boundary", 100, 120)])
        let selected = try EventsSelection(snapshot: current, from: now.addingTimeInterval(-500), before: now.addingTimeInterval(100), limit: 2)
        XCTAssertEqual(selected.events.map(\.title), ["ongoing", "a"])
        XCTAssertEqual(selected.matchingCount, 3)
        XCTAssertEqual(selected.from, now)
        XCTAssertThrowsError(try EventsSelection(snapshot: current, from: now, before: now, limit: 5))
        XCTAssertThrowsError(try EventsSelection(snapshot: current, from: now.addingTimeInterval(200), before: now.addingTimeInterval(100), limit: 5))
        for limit in [0, 21] { XCTAssertThrowsError(try EventsSelection(snapshot: current, from: nil, before: nil, limit: limit)) }
        XCTAssertEqual(try EventsSelection(snapshot: current, from: nil, before: nil, limit: 20).events.count, 4)
    }

    func testMalformedRowsAreDisclosedAndBadFeedsNeverMeanNoEvents() throws {
        let parsed = try feed([item(), item(id: "bad", times: "nonsense")])
        XCTAssertEqual(parsed.events.count, 1)
        XCTAssertEqual(parsed.rejectedCount, 1)
        XCTAssertThrowsError(try feed([item(url: nil)]))
        XCTAssertThrowsError(try feed([item(times: "3 PM &ndash; 3 PM")]))
        XCTAssertThrowsError(try CampusGroupsEventsParser().parseFeed(data: Data("<html>Error</html>".utf8), now: now))
        let partial = EventsSnapshot(events: parsed.events, status: .live, fetchedAt: now, checkedAt: now,
                                     rejectedRecordCount: 1, availabilityDetail: nil)
        let selection = try EventsSelection(snapshot: partial, from: nil, before: nil, limit: 5)
        XCTAssertTrue(EventsDialog.search(selection, snapshot: partial).contains("Some source records could not be read"))
        XCTAssertTrue(try feed([]).events.isEmpty)
    }

    func testCacheBoundaryFutureDateLegacyAndOriginalFetchTime() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = EventsCacheStore(url: directory.appendingPathComponent("cachedEvents.json"))
        let event = try XCTUnwrap(feed([item(day: "Tue, Nov 10, 2026", zone: "EST (GMT-5)")]).events.first)
        cache.write(snapshot([event]))
        let boundary = cache.read(at: now.addingTimeInterval(86400), failure: "Offline")
        XCTAssertEqual(boundary.status, .cached)
        XCTAssertEqual(boundary.fetchedAt, now)
        XCTAssertEqual(boundary.cacheAgeSeconds, 86400)
        XCTAssertEqual(cache.read(at: now.addingTimeInterval(86401), failure: "Offline").status, .unavailable)
        XCTAssertEqual(cache.read(at: now.addingTimeInterval(-1), failure: "Offline").status, .unavailable)
        cache.write(boundary)
        XCTAssertEqual(cache.read(at: now.addingTimeInterval(86401), failure: "Offline").status, .unavailable)
        try JSONEncoder().encode([event]).write(to: cache.url!)
        XCTAssertEqual(cache.loadForDisplay(at: now).count, 1)
        XCTAssertEqual(cache.read(at: now, failure: "Offline").status, .unavailable)
    }

    private func session(_ response: EventStubProtocol.Response) -> URLSession {
        EventStubProtocol.configure(response)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EventStubProtocol.self]
        return URLSession(configuration: configuration)
    }

    func testServiceTimeoutCacheExpiryOfflineAndEmptySuccess() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = EventsCacheStore(url: directory.appendingPathComponent("cachedEvents.json"))
        let fixed = now
        let online = session(.data(try data([item()]), 200))
        let live = await EventsService(session: online, cache: cache).fetch(now: { fixed })
        online.invalidateAndCancel()
        XCTAssertEqual(live.status, .live)
        XCTAssertEqual(live.events.count, 1)
        XCTAssertEqual(EventStubProtocol.lastRequest?.timeoutInterval, 12)
        XCTAssertEqual(EventStubProtocol.lastRequest?.url, Constants.recreationalSportsEventsURL)
        let timeout = session(.error(.timedOut))
        let later = now.addingTimeInterval(60)
        let cached = await EventsService(session: timeout, cache: cache).fetch(now: { later })
        XCTAssertEqual(cached.status, .cached)
        XCTAssertEqual(cached.fetchedAt, now)
        XCTAssertEqual(cached.checkedAt, later)
        XCTAssertEqual(cached.cacheAgeSeconds, 60)
        XCTAssertTrue(EventsDialog.details(cached.events.first, snapshot: cached).contains("Cached 1 minute ago"))
        let expiredDate = now.addingTimeInterval(86401)
        let expired = await EventsService(session: timeout, cache: cache).fetch(now: { expiredDate })
        timeout.invalidateAndCancel()
        XCTAssertEqual(expired.status, .unavailable)
        XCTAssertNil(expired.fetchedAt)
        XCTAssertTrue(expired.events.isEmpty)
        let offline = session(.error(.notConnectedToInternet))
        let unavailable = await EventsService(session: offline, cache: .init(url: nil)).fetch(now: { fixed })
        XCTAssertEqual(unavailable.status, .unavailable)
        offline.invalidateAndCancel()
        let empty = session(.data(try data([]), 200))
        let zero = await EventsService(session: empty, cache: cache).fetch(now: { fixed })
        empty.invalidateAndCancel()
        XCTAssertEqual(zero.status, .live)
        XCTAssertEqual(zero.events.count, 0)
        let result = try EventsSelection(snapshot: zero, from: nil, before: nil, limit: 5)
        XCTAssertTrue(EventsDialog.search(result, snapshot: zero).contains("No matching upcoming events"))
        let httpError = session(.data(Data(), 500))
        let fallback = await EventsService(session: httpError, cache: cache).fetch(now: { later })
        httpError.invalidateAndCancel()
        XCTAssertEqual(fallback.status, .cached)
        XCTAssertTrue(fallback.events.isEmpty)
    }

    func testRichResultStructureDetailsRefreshAndDialogLimits() throws {
        let events = try feed([item()]).events
        let current = snapshot(events)
        let intent = FindUpcomingEventsIntent()
        intent.limit = 1
        let result = try XCTUnwrap(intent.response(snapshot: current).value)
        XCTAssertEqual(result.returnedCount, 1)
        XCTAssertEqual(result.matchingCount, 1)
        XCTAssertEqual(result.status, .live)
        XCTAssertEqual(result.fetchedAt, now)
        XCTAssertEqual(result.events.first?.id, "campusgroups:123")
        XCTAssertNil(result.events.first?.priceText)
        XCTAssertTrue(result.sourceLimitation.contains("40"))
        let failed = snapshot([], status: .unavailable)
        let unknown = try XCTUnwrap(intent.response(snapshot: failed).value)
        XCTAssertNil(unknown.matchingCount)
        XCTAssertEqual(unknown.status, .unavailable)
        XCTAssertFalse(EventsDialog.search(try EventsSelection(snapshot: failed, from: nil, before: nil, limit: 5), snapshot: failed).contains("No matching"))
        let details = try XCTUnwrap(GetEventDetailsIntent().response(id: "campusgroups:123", snapshot: current).value)
        XCTAssertEqual(details.title, "Climbing & Skills")
        let removed = try XCTUnwrap(GetEventDetailsIntent().response(id: details.id, snapshot: snapshot([])).value)
        XCTAssertEqual(removed.id, details.id)
        XCTAssertEqual(removed.status, .unavailable)
        XCTAssertNil(removed.title)
        XCTAssertNil(removed.startDate)
        XCTAssertNil(removed.priceText)
        XCTAssertFalse(FindUpcomingEventsIntent.openAppWhenRun)
        XCTAssertFalse(GetEventDetailsIntent.openAppWhenRun)
        XCTAssertEqual(GymCrowdsShortcuts.appShortcuts.count, 4)
    }

    func testLiveEventsIntentWithoutUI() async throws {
        guard ProcessInfo.processInfo.environment["VTGYM_LIVE_CHECK"] == "1" else { throw XCTSkip("Explicit live-network lane only") }
        let response = try await FindUpcomingEventsIntent().perform()
        let result = try XCTUnwrap(response.value)
        XCTAssertEqual(result.status, .live)
        XCTAssertNotNil(result.fetchedAt)
        XCTAssertEqual(Set(result.events.map(\.id)).count, result.events.count)
        for event in result.events {
            XCTAssertNotNil(event.title)
            XCTAssertNotNil(event.startDate)
            XCTAssertNotNil(event.endDate)
            XCTAssertNotNil(event.eventURL)
            XCTAssertEqual(event.timeZoneIdentifier, "America/New_York")
        }
        if let first = result.events.first {
            let details = GetEventDetailsIntent()
            details.event = first
            let detailsResponse = try await details.perform()
            let refreshed = try XCTUnwrap(detailsResponse.value)
            XCTAssertEqual(refreshed.id, first.id)
            XCTAssertEqual(refreshed.status, .live)
        }
        print("LIVE EVENTS: returned=\(result.returnedCount), matching=\(String(describing: result.matchingCount)), status=\(result.status.rawValue)")
    }
}

private final class EventStubProtocol: URLProtocol, @unchecked Sendable {
    enum Response { case data(Data, Int), error(URLError.Code) }
    private static let lock = NSLock()
    private static var response: Response = .error(.badServerResponse)
    private static var request: URLRequest?
    static var lastRequest: URLRequest? { lock.withLock { request } }
    static func configure(_ value: Response) { lock.withLock { response = value; request = nil } }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = Self.lock.withLock { Self.request = request; return Self.response }
        switch response {
        case .error(let code): client?.urlProtocol(self, didFailWithError: URLError(code))
        case .data(let data, let status):
            let http = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {}
}

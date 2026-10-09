import XCTest
import AppIntents
@testable import GymCrowds

final class CrowdsTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func html(_ count: Int, _ remaining: Int) -> String {
        "<canvas data-occupancy=\"\(count)\" data-remaining=\"\(remaining)\"></canvas>"
    }

    private func live(_ facility: TrackedFacility, _ count: Int) -> OccupancySnapshot {
        OccupancySnapshot(facility: facility, count: count, fetchedAt: date, checkedAt: date,
                          lastSuccessfulFetchAt: date, status: .live, unavailableReason: nil)
    }

    func testParserAcceptsZeroAndRepeatedIdenticalResponsiveCharts() {
        let zero = OccupancyHTMLParser.parse(html(0, 600), capacity: 600)
        XCTAssertEqual(zero?.occupancy, 0)
        XCTAssertEqual(zero?.remaining, 600)
        XCTAssertEqual(OccupancyHTMLParser.parse(html(230, 370) + html(230, 370), capacity: 600)?.occupancy, 230)
        XCTAssertEqual(OccupancyHTMLParser.parse("<canvas data-remaining = '4' data-occupancy = '4'>", capacity: 8)?.occupancy, 4)
        XCTAssertEqual(OccupancyHTMLParser.parse(html(600, 0), capacity: 600)?.remaining, 0)
    }

    func testParserRejectsMissingMalformedOutOfRangeAndConflictingData() {
        let bad = ["", "<h1>Error</h1>", "<canvas data-remaining=\"600\">",
                   "<canvas data-occupancy=\"0\">", html(-1, 601), html(601, 0), html(0, 601), html(200, 200),
                   "<canvas data-occupancy=\"1.2\" data-remaining=\"598\">",
                   "<canvas data-occupancy=\"unknown\" data-remaining=\"600\">",
                   "<canvas data-occupancy=\"999999999999999999999999\" data-remaining=\"0\">",
                   html(100, 500) + html(200, 400),
                   "<!--" + html(0, 600) + "-->", "<script>" + html(0, 600) + "</script>",
                   "<canvas data-occupancy=\"1' data-remaining=\"599\">",
                   "<canvas data-occupancy=\"0\" data-occupancy=\"bad\" data-remaining=\"600\">",
                   "<canvas data-occupancy=\"0\"><canvas data-remaining=\"600\">",
                   "<canvas data-occupancy=\"0\" data-occupancy=\"5\" data-remaining=\"600\">"]
        for value in bad { XCTAssertNil(OccupancyHTMLParser.parse(value, capacity: 600), value) }
    }

    func testAliasesAreExactAndAllChoiceExpandsInPredictableOrder() {
        for facility in TrackedFacility.allCases {
            let representation = TrackedFacility.caseDisplayRepresentations[facility]
            XCTAssertEqual(representation.map { String(localized: $0.title) }, facility.name)
        }
        let warAliases = TrackedFacility.caseDisplayRepresentations[.warMemorial]?.synonyms.map { String(localized: $0) } ?? []
        XCTAssertTrue(warAliases.contains("War"))
        XCTAssertTrue(warAliases.contains("WMH"))
        XCTAssertTrue(warAliases.contains("WMH Service Desk"))
        let wallAliases = TrackedFacility.caseDisplayRepresentations[.boulderingWall]?.synonyms.map { String(localized: $0) } ?? []
        XCTAssertTrue(wallAliases.contains("Climbing wall"))
        // No ambiguous single-gym alias shared by two cases.
        let aliases = TrackedFacility.caseDisplayRepresentations.values.flatMap { $0.synonyms.map { String(localized: $0).lowercased() } }
        XCTAssertEqual(Set(aliases).count, aliases.count)
        XCTAssertEqual(TrackedFacility.allFacilities.facilities, [.mcComas, .warMemorial, .boulderingWall])
        XCTAssertEqual(TrackedFacility.warMemorial.facilities, [.warMemorial])
        XCTAssertEqual(TrackedFacility.caseDisplayRepresentations.count, 4)
        XCTAssertEqual(TrackedFacility.caseDisplayRepresentations[.warMemorial]?.synonyms.count, 5)
    }

    func testStoreRejectsLegacyGlobalDateAndPreservesPerFacilitySuccess() {
        let suite = "GymCrowdsTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = OccupancySnapshotStore(defaults: defaults)
        defaults.set(0, forKey: TrackedFacility.mcComas.occupancyKey)
        defaults.set(date, forKey: "lastFetchDate")
        XCTAssertNil(store.read(.mcComas, at: date).count)
        store.write(live(.mcComas, 0))
        XCTAssertEqual(store.read(.mcComas, at: date.addingTimeInterval(90)).count, 0)
        XCTAssertEqual(store.read(.mcComas, at: date.addingTimeInterval(90)).cacheAgeSeconds, 90)
        let expired = store.read(.mcComas, at: date.addingTimeInterval(91))
        XCTAssertNil(expired.count)
        XCTAssertNil(expired.fetchedAt)
        XCTAssertEqual(expired.lastSuccessfulFetchAt, date)
        XCTAssertNil(store.read(.mcComas, at: date.addingTimeInterval(-1)).count)
        store.write(expired)
        XCTAssertNil(defaults.object(forKey: TrackedFacility.mcComas.occupancyKey))
        XCTAssertEqual(defaults.object(forKey: TrackedFacility.mcComas.fetchDateKey) as? Date, date)
        // A different facility's success cannot refresh this facility.
        store.write(live(.warMemorial, 600))
        XCTAssertNil(store.read(.mcComas, at: date).count)
    }

    func testResultHasFactualTypedPropertiesAndUnknownsStayNil() {
        let snapshot = live(.boulderingWall, 0)
        let entity = FacilityCrowdsEntity(snapshot)
        XCTAssertEqual(entity.facilityID, Constants.boulderingWallFacilityId)
        XCTAssertEqual(entity.facility, .boulderingWall)
        XCTAssertEqual(entity.name, "Bouldering Wall")
        XCTAssertTrue(entity.isClimbingFacility)
        XCTAssertEqual(entity.count, 0)
        XCTAssertEqual(entity.capacity, 8)
        XCTAssertEqual(entity.fullnessPercent, 0)
        XCTAssertEqual(entity.fetchedAt, date)
        XCTAssertEqual(entity.status, .live)
        XCTAssertNil(entity.sourceMeasuredAt)
        XCTAssertNil(entity.cacheAgeSeconds)
        XCTAssertEqual(entity.sourceURL, Constants.facilityDataAPIURL)
        let unknown = FacilityCrowdsEntity()
        XCTAssertNil(unknown.count)
        XCTAssertNil(unknown.fullnessPercent)
        XCTAssertNil(unknown.fetchedAt)
        XCTAssertEqual(unknown.status, .unavailable)
        XCTAssertFalse(CurrentCrowdsIntent.openAppWhenRun)
        XCTAssertTrue(CurrentCrowdsIntent.isDiscoverable)
        let result = CurrentCrowdsIntent().response(for: [snapshot])
        XCTAssertEqual(result.value?.first?.count, 0)
        XCTAssertEqual(GymCrowdsShortcuts.appShortcuts.count, 1)
    }

    func testDialogUsesPercentagesAndSeparatesClimbingWall() {
        // Raw count is lower at McComas, but percentage is higher.
        let readings = [live(.mcComas, 300), live(.warMemorial, 400), live(.boulderingWall, 0)]
        let dialog = CrowdsDialog.describe(readings)
        XCTAssertTrue(dialog.contains("300 of 600, 50% full"))
        XCTAssertTrue(dialog.contains("400 of 1200, 33% full"))
        XCTAssertTrue(dialog.contains("War Memorial Hall has lower reported fullness"))
        XCTAssertTrue(dialog.contains("Bouldering Wall: 0 of 8, 0% full"))
        XCTAssertTrue(dialog.contains("separate climbing facility"))
        XCTAssertTrue(CrowdsDialog.describe([live(.mcComas, 300), live(.warMemorial, 600), live(.boulderingWall, 1)]).contains("same reported fullness"))
    }

    func testLiveIntentWithoutUI() async throws {
        guard ProcessInfo.processInfo.environment["VTGYM_LIVE_CHECK"] == "1" else {
            throw XCTSkip("Explicit live network verification lane only")
        }
        let result = try await CurrentCrowdsIntent().perform()
        let values = try XCTUnwrap(result.value)
        XCTAssertEqual(values.map(\.facility), TrackedFacility.individualFacilities)
        XCTAssertEqual(values.count, 3)
        for value in values {
            XCTAssertNil(value.sourceMeasuredAt)
            if value.status == .live {
                XCTAssertNotNil(value.fetchedAt)
                XCTAssertNotNil(value.count)
                XCTAssertNotNil(value.fullnessPercent)
            }
            print("LIVE INTENT: \(value.name), count=\(String(describing: value.count)), capacity=\(value.capacity), percent=\(String(describing: value.fullnessPercent)), status=\(value.status.rawValue), fetched=\(String(describing: value.fetchedAt))")
        }
        XCTAssertTrue(values.allSatisfy { $0.status == .live }, "Source must independently verify all three facilities in this lane")
    }

    func testParserRejectsWrongFacilityIdentity() {
        let wrong = "<canvas id=\"occupancyChart-wrong\" data-occupancy=\"0\" data-remaining=\"600\">"
        XCTAssertNil(OccupancyHTMLParser.parse(wrong, capacity: 600, facilityID: Constants.mcComasFacilityId))
    }

    private func session(_ responses: [String: StubResponse]) -> URLSession {
        StubProtocol.configure(responses)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: config)
    }

    func testAllFacilitiesPartialFailureAndHTTPError() async {
        let urlSession = session([
            Constants.mcComasFacilityId: .html(html(0, 600)),
            Constants.warMemorialFacilityId: .html("<h1>Bad data</h1>"),
            Constants.boulderingWallFacilityId: .http(500)
        ])
        defer { urlSession.invalidateAndCancel() }
        let fixed = date
        let results = await GymOccupancyFetcher.fetchSnapshots(session: urlSession, now: { fixed })
        XCTAssertEqual(results.map(\.facility), TrackedFacility.individualFacilities)
        XCTAssertEqual(results.map(\.status), [.live, .unavailable, .unavailable])
        XCTAssertEqual(results[0].count, 0)
        XCTAssertEqual(results[0].fetchedAt, date)
        XCTAssertNil(results[1].count)
        XCTAssertNil(results[2].fetchedAt)
        let dialog = CrowdsDialog.describe(results)
        XCTAssertTrue(dialog.contains("War Memorial Hall: occupancy unavailable"))
        XCTAssertTrue(dialog.contains("live comparison of the two gyms is unavailable"))
        XCTAssertFalse(dialog.contains("lower reported fullness"))
        XCTAssertEqual(StubProtocol.requestedIDs.sorted(), TrackedFacility.individualFacilities.map(\.id).sorted())
    }

    func testOfflineAndTimeoutReuseOnlyRecentVerifiedCount() async {
        let urlSession = session([Constants.mcComasFacilityId: .error(.timedOut)])
        defer { urlSession.invalidateAndCancel() }
        let old = live(.mcComas, 10)
        let fixed = date.addingTimeInterval(60)
        let results = await GymOccupancyFetcher.fetchSnapshots(facilities: [.mcComas], session: urlSession,
                                                             previous: [old], now: { fixed })
        XCTAssertEqual(results[0].status, .cached)
        XCTAssertEqual(results[0].fetchedAt, date)
        XCTAssertEqual(results[0].cacheAgeSeconds, 60)
        XCTAssertEqual(results[0].unavailableReason, "RecSports request timed out")
        XCTAssertTrue(CrowdsDialog.describe(results).contains("Cached 60 seconds ago; live data unavailable"))
        XCTAssertEqual(FacilityCrowdsEntity(results[0]).cacheAgeSeconds, 60)
        XCTAssertEqual(StubProtocol.requestTimeout, 12)
    }

    func testExpiredDuringRequestAndOfflineNeverInventZero() async {
        let urlSession = session([Constants.mcComasFacilityId: .error(.notConnectedToInternet)])
        defer { urlSession.invalidateAndCancel() }
        let fixed = date.addingTimeInterval(91)
        let results = await GymOccupancyFetcher.fetchSnapshots(facilities: [.mcComas], session: urlSession,
                                                             previous: [live(.mcComas, 10)], now: { fixed })
        XCTAssertEqual(results[0].status, .unavailable)
        XCTAssertNil(results[0].count)
        XCTAssertNil(results[0].fullnessPercent)
        XCTAssertNil(results[0].fetchedAt)
        XCTAssertEqual(results[0].lastSuccessfulFetchAt, date)
        let noCache = await GymOccupancyFetcher.fetchSnapshots(facilities: [.mcComas], session: urlSession, now: { fixed })
        XCTAssertNil(noCache[0].count)
        XCTAssertNil(noCache[0].lastSuccessfulFetchAt)
    }

    func testSingleFacilityAndSiriPathIgnoresDebugMocks() async {
        let urlSession = session([Constants.mcComasFacilityId: .html(html(1, 599))])
        defer { urlSession.invalidateAndCancel() }
        let results = await GymOccupancyFetcher.fetchSnapshots(facilities: [.mcComas], session: urlSession)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].count, 1)
        XCTAssertNotEqual(results[0].count, Constants.mockMcComasOccupancy)
        XCTAssertEqual(StubProtocol.requestedIDs, [Constants.mcComasFacilityId])
    }
}

private enum StubResponse {
    case html(String), http(Int), error(URLError.Code)
}

private final class StubProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var responses: [String: StubResponse] = [:]
    private static var ids: [String] = []
    private static var timeout: TimeInterval = 0

    static var requestedIDs: [String] { lock.withLock { ids } }
    static var requestTimeout: TimeInterval { lock.withLock { timeout } }
    static func configure(_ value: [String: StubResponse]) {
        lock.withLock { responses = value; ids = []; timeout = 0 }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var body = request.httpBody ?? Data()
        if body.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let length = stream.read(&buffer, maxLength: buffer.count)
                if length <= 0 { break }
                body.append(contentsOf: buffer.prefix(length))
            }
        }
        let text = String(decoding: body, as: UTF8.self)
        let id = text.components(separatedBy: "&").first?.replacingOccurrences(of: "facilityId=", with: "") ?? ""
        let response: StubResponse = Self.lock.withLock {
            Self.ids.append(id); Self.timeout = request.timeoutInterval
            return Self.responses[id] ?? .error(.badServerResponse)
        }
        switch response {
        case .error(let code): client?.urlProtocol(self, didFailWithError: URLError(code))
        case .html(let html):
            let identified = html.replacingOccurrences(of: "<canvas ", with: "<canvas id=\"occupancyChart-\(id)\" ")
            complete(status: 200, data: Data(identified.utf8))
        case .http(let status): complete(status: status, data: Data())
        }
    }
    private func complete(status: Int, data: Data) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

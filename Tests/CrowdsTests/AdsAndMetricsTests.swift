import XCTest
@testable import GymCrowds

private actor RecordedRequests {
    var bodies: [[String: Any]] = []
    func send(_ request: URLRequest) -> Bool {
        if let data = request.httpBody, let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { bodies.append(body) }
        return true
    }
    func snapshot() -> [[String: Any]] { bodies }
}

final class AdsAndMetricsTests: XCTestCase {
    private func ad(label: Any? = nil) throws -> AdConfig {
        var value: [String: Any] = ["id": "test", "active": true, "sponsor": "Campus Club", "headline": "Join us", "cta": "Learn more", "destination_url": "https://example.com", "tier": "text"]
        if let label { value["sponsored_label"] = label }
        return try JSONDecoder().decode(AdConfig.self, from: JSONSerialization.data(withJSONObject: value))
    }

    func testLegacyAndExplicitLabelsSurviveRoundTrip() throws {
        XCTAssertEqual(try ad().sponsoredLabel, "Sponsored")
        XCTAssertEqual(try ad(label: NSNull()).sponsoredLabel, "Sponsored")
        for label in ["Sponsored", "Partner", "Student Organization", "", "  "] {
            let config = try ad(label: label)
            XCTAssertEqual(config.sponsoredLabel, label.trimmingCharacters(in: .whitespaces))
            XCTAssertEqual(try JSONDecoder().decode(AdConfig.self, from: JSONEncoder().encode(config)), config)
        }
    }

    func testNoActiveCampaignClearsButServerFailureRemainsUnavailable() async throws {
        let suite = "AdServiceTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AdStatusProtocol.self]
        let service = AdService(session: URLSession(configuration: config), userDefaults: defaults)
        AdStatusProtocol.status = 404
        let absent = await service.fetchActiveAdOutcome()
        XCTAssertEqual(absent, .inactive)
        AdStatusProtocol.status = 503
        let unavailable = await service.fetchActiveAdOutcome()
        XCTAssertEqual(unavailable, .unavailable)
    }

    func testSessionsImpressionsAndOptOut() async throws {
        let suite = "MetricsTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let recorder = RecordedRequests()
        let metrics = AppMetrics(defaults: defaults, enabledForBuild: true, send: { await recorder.send($0) })
        let now = Date()
        await metrics.activate(at: now)
        await metrics.activate(at: now)
        let props = ["ad_id": "campaign", "creative_version": "v1", "placement": "home_feed"]
        await metrics.track(.adImpression, properties: props)
        await metrics.track(.adImpression, properties: props)
        await metrics.track(.adTap, properties: props)
        var bodies = await recorder.snapshot()
        XCTAssertEqual(bodies.map { $0["event"] as? String }, ["app_session", "ad_impression", "ad_tap"])
        let firstID = bodies[0]["distinct_id"] as? String
        await metrics.enterBackground(at: now)
        await metrics.activate(at: now.addingTimeInterval(60))
        await metrics.track(.adImpression, properties: props)
        bodies = await recorder.snapshot()
        XCTAssertEqual(bodies.count, 3)
        await metrics.enterBackground(at: now)
        await metrics.activate(at: now.addingTimeInterval(1800))
        await metrics.track(.adImpression, properties: props)
        bodies = await recorder.snapshot()
        XCTAssertEqual(bodies.count, 5)
        XCTAssertEqual(bodies.last?["distinct_id"] as? String, firstID)
        let sessions = bodies.compactMap { ($0["properties"] as? [String: String])?["session_id"] }
        XCTAssertNotEqual(sessions[0], sessions[3])
        await metrics.setEnabled(false)
        await metrics.track(.eventOpen)
        XCTAssertNil(defaults.string(forKey: AppMetrics.installationKey))
        bodies = await recorder.snapshot()
        XCTAssertEqual(bodies.count, 5)
        await metrics.setEnabled(true)
        await metrics.activate()
        bodies = await recorder.snapshot()
        XCTAssertEqual(bodies.count, 6)
        XCTAssertNotEqual(bodies.last?["distinct_id"] as? String, firstID)
    }

    func testDevelopmentBuildAndPreviewAdsNeverSend() async throws {
        let suite = "MetricsTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let recorder = RecordedRequests()
        let debug = AppMetrics(defaults: defaults, enabledForBuild: false, send: { await recorder.send($0) })
        await debug.activate()
        await debug.track(.siriCrowds, properties: ["status": "live"])
        let release = AppMetrics(defaults: defaults, enabledForBuild: true, send: { await recorder.send($0) })
        await release.track(.adImpression, properties: ["ad_id": "dev_text"])
        await release.track(.adTap, properties: ["ad_id": "dev_text"])
        let bodies = await recorder.snapshot()
        XCTAssertTrue(bodies.isEmpty)
        XCTAssertNil(defaults.string(forKey: AppMetrics.installationKey))
    }
}

private final class AdStatusProtocol: URLProtocol {
    static var status = 404
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

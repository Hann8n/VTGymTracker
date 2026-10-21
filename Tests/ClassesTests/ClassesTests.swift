import XCTest
@testable import GymCrowds

final class ClassesTests: XCTestCase {
    /// Shared with the Android parser tests: same EMS response in, same classes out.
    private let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../Fixtures/ems").standardizedFileURL

    private struct Expected: Decodable, Equatable { let id, title, room, start, end: String }

    func testParsesClassRoomsFromSharedFixture() throws {
        let data = try Data(contentsOf: fixtures.appendingPathComponent("mccomas-response.json"))
        let expected = try JSONDecoder().decode([Expected].self,
                                                from: Data(contentsOf: fixtures.appendingPathComponent("mccomas-expected.json")))
        let iso = ISO8601DateFormatter()
        let parsed = try EMSClassParser.parse(data).map {
            Expected(id: $0.id, title: $0.title, room: $0.room, start: iso.string(from: $0.start), end: iso.string(from: $0.end))
        }
        XCTAssertEqual(parsed, expected)
    }

    func testRejectsResponsesWithoutBookings() {
        XCTAssertThrowsError(try EMSClassParser.parse(Data(#"{"d":"{\"Success\":false}"}"#.utf8)))
        XCTAssertThrowsError(try EMSClassParser.parse(Data("<html></html>".utf8)))
    }

    func testRequestCarriesBuildingAndBrowsePage() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-21T03:00:00Z")) // Oct 20, 11 PM Eastern
        let body = ClassScheduleService.requestBody(buildingID: 156, page: Constants.mcComasEMSPage, now: now)
        XCTAssertEqual(body["date"] as? String, "2026-10-20 00:00:00")
        let data = try XCTUnwrap(body["data"] as? [String: Any])
        XCTAssertEqual(data["BuildingId"] as? Int, 156)
        XCTAssertEqual(data["EncryptD"] as? String, Constants.mcComasEMSPage)
    }

    func testFailedGymKeepsItsCachedClasses() async throws {
        let cacheURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: cacheURL) }
        let old = GymClass(id: "1", title: "Spin", room: "Spin Studio 131", start: .distantFuture, end: .distantFuture)
        let cached = ClassScheduleService.Schedule(classes: ["warMemorial": [old]], fetchedAt: nil)
        try JSONEncoder().encode(cached).write(to: cacheURL)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OfflineProtocol.self]
        let service = ClassScheduleService(session: URLSession(configuration: configuration), cacheURL: cacheURL)
        let schedule = await service.refresh()
        XCTAssertEqual(schedule, cached)
    }
}

/// Fails every request, standing in for an unreachable EMS.
private final class OfflineProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
    override func stopLoading() {}
}

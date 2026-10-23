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

    func testUpcomingMergesGymsInStartOrderAndHonorsTheFilter() throws {
        let now = try date("2026-10-23T18:00:00Z") // 2 PM Eastern
        let schedule = ClassScheduleService.Schedule(classes: [
            "warMemorial": [gymClass("w-ended", "2026-10-23T16:00:00Z", minutes: 45), gymClass("w1", "2026-10-23T19:30:00Z")],
            "mcComas": [gymClass("m1", "2026-10-23T17:45:00Z"), gymClass("m2", "2026-10-23T19:30:00Z")]
        ])
        XCTAssertEqual(schedule.upcoming(.all, after: now).map(\.gymClass.id), ["m1", "m2", "w1"])
        XCTAssertEqual(schedule.upcoming(.warMemorial, after: now).map(\.gymClass.id), ["w1"])
        XCTAssertEqual(schedule.upcoming(.all, after: now).first?.status(at: now), .underway)
        XCTAssertEqual(schedule.upcoming(.warMemorial, after: now).first?.status(at: now), nil)
        XCTAssertEqual(schedule.upcoming(.all, after: try date("2026-10-23T19:10:00Z")).last?.status(at: try date("2026-10-23T19:10:00Z")),
                       .startingIn(minutes: 20))
    }

    func testNextDayMovesToTomorrowOnceTodaysClassesEnd() throws {
        var eastern = Calendar(identifier: .gregorian)
        eastern.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let schedule = ClassScheduleService.Schedule(classes: [
            "mcComas": [gymClass("today", "2026-10-23T22:00:00Z"), gymClass("tomorrow-1", "2026-10-24T14:30:00Z"),
                        gymClass("tomorrow-2", "2026-10-24T16:00:00Z"), gymClass("sunday", "2026-10-25T14:30:00Z")]
        ])
        let afternoon = try date("2026-10-23T18:00:00Z")
        XCTAssertEqual(schedule.nextDay(.all, after: afternoon, calendar: eastern)?.classes.map(\.gymClass.id), ["today"])
        let lateEvening = try date("2026-10-24T01:00:00Z") // 9 PM Eastern, after the last class
        XCTAssertEqual(schedule.nextDay(.all, after: lateEvening, calendar: eastern)?.classes.map(\.gymClass.id), ["tomorrow-1", "tomorrow-2"])
        XCTAssertEqual(schedule.days(.all, after: lateEvening, calendar: eastern).map { $0.classes.count }, [2, 1])
        XCTAssertNil(schedule.nextDay(.warMemorial, after: afternoon, calendar: eastern))
    }

    private func date(_ text: String) throws -> Date { try XCTUnwrap(ISO8601DateFormatter().date(from: text)) }

    private func gymClass(_ id: String, _ start: String, minutes: Double = 45) -> GymClass {
        let start = ISO8601DateFormatter().date(from: start)!
        return GymClass(id: id, title: id, room: "Studio 117", start: start, end: start.addingTimeInterval(minutes * 60))
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

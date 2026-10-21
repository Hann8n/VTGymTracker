import Foundation

/// Fetches each gym's class schedule straight from EMS on the device and keeps the last good copy.
struct ClassScheduleService {
    struct Schedule: Codable, Equatable {
        var classes: [String: [GymClass]] = [:] // keyed by TrackedFacility.rawValue
        var fetchedAt: Date?

        func classes(for facility: TrackedFacility, after now: Date) -> [GymClass] {
            (classes[facility.rawValue] ?? []).filter { $0.end > now }
        }
    }

    /// Schedules rarely change within a day; refreshing on open past this age keeps requests to a few a day.
    static let refreshAge: TimeInterval = 6 * 60 * 60

    var session: URLSession = EventsService.liveSession
    var cacheURL: URL? = try? FileManager.default
        .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("classSchedule.json")

    func cached() -> Schedule {
        guard let cacheURL, let data = try? Data(contentsOf: cacheURL),
              let schedule = try? JSONDecoder().decode(Schedule.self, from: data) else { return Schedule() }
        return schedule
    }

    /// Fetches every gym; a gym that fails keeps its cached classes so one bad response never empties the list.
    func refresh(now: Date = Date()) async -> Schedule {
        var schedule = cached()
        let results = await withTaskGroup(of: (TrackedFacility, [GymClass]?).self) { group in
            for facility in TrackedFacility.classScheduleFacilities {
                group.addTask { (facility, try? await fetch(facility, now: now)) }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
        guard results.contains(where: { $0.1 != nil }) else { return schedule }
        for case let (facility, classes?) in results { schedule.classes[facility.rawValue] = classes }
        schedule.fetchedAt = now
        if let cacheURL, let data = try? JSONEncoder().encode(schedule) { try? data.write(to: cacheURL, options: .atomic) }
        return schedule
    }

    func fetch(_ facility: TrackedFacility, now: Date) async throws -> [GymClass] {
        guard let buildingID = facility.emsBuildingID, let page = facility.emsPage else { return [] }
        var request = URLRequest(url: Constants.emsBrowseEventsURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: Self.requestBody(buildingID: buildingID, page: page, now: now))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try EMSClassParser.parse(data)
    }

    /// Mirrors what the EMS browse page sends; `Format: 1` returns about two weeks starting this week.
    static func requestBody(buildingID: Int, page: String, now: Date) -> [String: Any] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: Constants.eventsTimeZoneIdentifier)
        formatter.dateFormat = "yyyy-MM-dd 00:00:00"
        return [
            "date": formatter.string(from: now),
            "data": [
                "BuildingId": buildingID, "GroupTypeId": -1, "GroupId": -1, "EventTypeId": -1, "RoomId": -1,
                "StatusId": -1, "ZeroDisplayOnWeb": 1, "HeaderUrl": "", "Title": "", "Format": 1, "Rollup": 0,
                "PageSize": 250, "DropEventsInPast": true, "EncryptD": page
            ] as [String: Any]
        ]
    }
}

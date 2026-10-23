import Foundation

/// Fetches each gym's class schedule straight from EMS on the device and keeps the last good copy.
struct ClassScheduleService {
    struct Schedule: Codable, Equatable {
        var classes: [String: [GymClass]] = [:] // keyed by TrackedFacility.rawValue
        var fetchedAt: Date?

        func classes(for facility: TrackedFacility, after now: Date) -> [GymClass] {
            (classes[facility.rawValue] ?? []).filter { $0.end > now }
        }

        /// Classes not yet over in the filtered gyms, earliest first.
        func upcoming(_ filter: ClassGymFilter, after now: Date) -> [ScheduledClass] {
            filter.facilities
                .flatMap { facility in classes(for: facility, after: now).map { ScheduledClass(facility: facility, gymClass: $0) } }
                .sorted { ($0.gymClass.start, $0.gymClass.title, $0.facility.rawValue) < ($1.gymClass.start, $1.gymClass.title, $1.facility.rawValue) }
        }

        /// The remaining classes on the next day that has any: today until the last one ends, then tomorrow.
        func nextDay(_ filter: ClassGymFilter, after now: Date, calendar: Calendar = .current) -> (day: Date, classes: [ScheduledClass])? {
            let upcoming = upcoming(filter, after: now)
            guard let first = upcoming.first else { return nil }
            // A class already underway belongs to today even if it began before midnight.
            let day = calendar.startOfDay(for: max(first.gymClass.start, now))
            return (day, upcoming.filter { calendar.startOfDay(for: max($0.gymClass.start, now)) == day })
        }

        /// Upcoming classes grouped by day, earliest day first.
        func days(_ filter: ClassGymFilter, after now: Date, calendar: Calendar = .current) -> [(day: Date, classes: [ScheduledClass])] {
            Dictionary(grouping: upcoming(filter, after: now)) { calendar.startOfDay(for: max($0.gymClass.start, now)) }
                .sorted { $0.key < $1.key }
                .map { (day: $0.key, classes: $0.value) }
        }
    }

    /// Schedules rarely change within a day; refreshing on open past this age keeps requests to a few a day.
    static let refreshAge: TimeInterval = 6 * 60 * 60

    static let liveSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        return URLSession(configuration: configuration)
    }()

    /// In the App Group container, so the Classes widgets read the copy the app keeps fresh (and the other way round).
    static let sharedCacheURL: URL? = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)?
        .appendingPathComponent("classSchedule.json")

    var session: URLSession = Self.liveSession
    var cacheURL: URL? = Self.sharedCacheURL

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
        // Only a complete refresh resets the clock, so a gym that failed is tried again on the next open.
        if results.allSatisfy({ $0.1 != nil }) { schedule.fetchedAt = now }
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

    /// Mirrors what the EMS browse page sends. `Format: 1` returns the week either side of `date`, so asking
    /// for a week from today returns today through two weeks out.
    static func requestBody(buildingID: Int, page: String, now: Date) -> [String: Any] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: Constants.eventsTimeZoneIdentifier)
        formatter.dateFormat = "yyyy-MM-dd 00:00:00"
        let center = now.addingTimeInterval(7 * 24 * 60 * 60)
        return [
            "date": formatter.string(from: center),
            "data": [
                "BuildingId": buildingID, "GroupTypeId": -1, "GroupId": -1, "EventTypeId": -1, "RoomId": -1,
                "StatusId": -1, "ZeroDisplayOnWeb": 1, "HeaderUrl": "", "Title": "", "Format": 1, "Rollup": 0,
                "PageSize": 250, "DropEventsInPast": true, "EncryptD": page
            ] as [String: Any]
        ]
    }
}

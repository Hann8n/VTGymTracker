import AppIntents

struct CampusEventQuery: EntityStringQuery {
    func entities(for identifiers: [CampusEventEntity.ID]) async throws -> [CampusEventEntity] {
        let snapshot = await EventsService().fetch()
        guard snapshot.status != .unavailable else { throw EventsServiceError.unavailableFeed }
        return Self.resolve(identifiers, snapshot: snapshot)
    }

    func suggestedEntities() async throws -> [CampusEventEntity] {
        let snapshot = await EventsService().fetch()
        guard snapshot.status != .unavailable else { throw EventsServiceError.unavailableFeed }
        let selection = try EventsSelection(snapshot: snapshot, from: nil, before: nil, limit: 20)
        return selection.events.map { CampusEventEntity($0, snapshot: snapshot) }
    }

    func entities(matching string: String) async throws -> [CampusEventEntity] {
        let snapshot = await EventsService().fetch()
        guard snapshot.status != .unavailable else { throw EventsServiceError.unavailableFeed }
        return Self.match(string, snapshot: snapshot)
    }

    static func resolve(_ identifiers: [String], snapshot: EventsSnapshot) -> [CampusEventEntity] {
        identifiers.compactMap { id in
            snapshot.events.first { $0.stableIdentifier == id && $0.endDate > snapshot.checkedAt }
                .map { CampusEventEntity($0, snapshot: snapshot) }
        }
    }

    static func match(_ string: String, snapshot: EventsSnapshot) -> [CampusEventEntity] {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return snapshot.events.filter { $0.endDate > snapshot.checkedAt && $0.title.localizedStandardContains(string) }
            .sorted { $0.startDate == $1.startDate ? $0.stableIdentifier < $1.stableIdentifier : $0.startDate < $1.startDate }
            .prefix(20).map { CampusEventEntity($0, snapshot: snapshot) }
    }
}

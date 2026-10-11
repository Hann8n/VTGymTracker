import AppIntents

struct FindUpcomingEventsIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Upcoming Recreation Events"
    static var description = IntentDescription("Find ongoing or upcoming events in Virginia Tech's available Recreational Sports CampusGroups feed. Filter by a date interval and return factual event details with data freshness. Times are Eastern; results are limited to this feed, not all campus events.")
    static var openAppWhenRun = false

    @Parameter(title: "From") var from: Date?
    @Parameter(title: "Before") var before: Date?
    @Parameter(title: "Maximum Results", default: 5, inclusiveRange: (1, 20)) var limit: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Find upcoming recreation events") { \.$from; \.$before; \.$limit }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<EventSearchResultEntity> & ProvidesDialog {
        let snapshot = await EventsService().fetch()
        return try response(snapshot: snapshot)
    }

    func response(snapshot: EventsSnapshot) throws -> some IntentResult & ReturnsValue<EventSearchResultEntity> & ProvidesDialog {
        let selection = try EventsSelection(snapshot: snapshot, from: from, before: before, limit: limit)
        return .result(value: EventSearchResultEntity(selection: selection, snapshot: snapshot),
                       dialog: IntentDialog(stringLiteral: EventsDialog.search(selection, snapshot: snapshot)))
    }
}

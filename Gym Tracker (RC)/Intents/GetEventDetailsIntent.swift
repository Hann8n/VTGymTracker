import AppIntents

struct GetEventDetailsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Recreation Event Details"
    static var description = IntentDescription("Retrieve a selected event's dates, location, organizer, raw price text, link and data freshness from the available Recreational Sports feed. Missing prices are unknown, and locations may require sign-in.")
    static var openAppWhenRun = false

    @Parameter(title: "Event") var event: CampusEventEntity

    static var parameterSummary: some ParameterSummary { Summary("Get details for \(\.$event)") }

    func perform() async throws -> some IntentResult & ReturnsValue<CampusEventEntity> & ProvidesDialog {
        response(id: event.id, snapshot: await EventsService().fetch())
    }

    func response(id: String, snapshot: EventsSnapshot) -> some IntentResult & ReturnsValue<CampusEventEntity> & ProvidesDialog {
        let current = snapshot.events.first { $0.stableIdentifier == id && $0.endDate > snapshot.checkedAt }
        return .result(value: CampusEventEntity(id: id, event: current, snapshot: snapshot),
                       dialog: IntentDialog(stringLiteral: EventsDialog.details(current, snapshot: snapshot)))
    }
}

import AppIntents

extension EventsDataStatus: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Events Data Status"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .live: "Live", .cached: "Cached", .unavailable: "Unavailable"
    ]
}

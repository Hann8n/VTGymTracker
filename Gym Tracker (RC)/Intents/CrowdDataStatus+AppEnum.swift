import AppIntents

extension CrowdDataStatus: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Crowd Data Status"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .live: "Live", .cached: "Cached", .unavailable: "Unavailable"
    ]
}

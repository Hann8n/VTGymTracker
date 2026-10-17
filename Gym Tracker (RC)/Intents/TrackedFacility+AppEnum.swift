import AppIntents

extension TrackedFacility: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Recreation Facility"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .allFacilities: DisplayRepresentation(title: "All Facilities", synonyms: ["All", "Everything"]),
        .bothGyms: DisplayRepresentation(title: "Both Gyms", synonyms: ["All gyms", "Gyms", "Compare gyms", "McComas and War Memorial"]),
        .mcComas: DisplayRepresentation(title: "McComas Hall", synonyms: ["McComas", "McComas gym", "MC"]),
        .warMemorial: DisplayRepresentation(title: "War Memorial Hall", synonyms: ["War Memorial", "War Memorial gym", "War", "WMH", "WMH Service Desk"]),
        .boulderingWall: DisplayRepresentation(title: "Bouldering Wall", synonyms: ["Bouldering", "Climbing wall", "Climbing", "Wall"])
    ]
}

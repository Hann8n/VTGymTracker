import AppIntents

struct CampusEventEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Recreation Event"
    static var defaultQuery = CampusEventQuery()
    let id: String

    @Property(title: "Event ID") var eventID: String
    @Property(title: "Title") var title: String?
    @Property(title: "Starts At") var startDate: Date?
    @Property(title: "Ends At") var endDate: Date?
    @Property(title: "Time Zone") var timeZoneIdentifier: String
    @Property(title: "Source Time Zone Text") var sourceTimeZoneText: String?
    @Property(title: "Location") var location: String?
    @Property(title: "Organizer") var organizer: String?
    @Property(title: "Price Text") var priceText: String?
    @Property(title: "Event URL") var eventURL: URL?
    @Property(title: "Data Status") var status: EventsDataStatus
    @Property(title: "Fetched At") var fetchedAt: Date?
    @Property(title: "Checked At") var checkedAt: Date
    @Property(title: "Cache Age in Seconds") var cacheAgeSeconds: Double?
    @Property(title: "Availability Detail") var availabilityDetail: String?
    @Property(title: "Source Feed URL") var sourceFeedURL: URL

    var displayRepresentation: DisplayRepresentation {
        let date = startDate.map(EventsDialog.dateText) ?? "Date unavailable"
        return DisplayRepresentation(title: "\(title ?? "Unavailable event")", subtitle: "\(date), \(status.rawValue)")
    }

    init(id: String, event: Event?, snapshot: EventsSnapshot) {
        self.id = id
        eventID = id
        title = event?.title
        startDate = event?.startDate
        endDate = event?.endDate
        timeZoneIdentifier = Constants.eventsTimeZoneIdentifier
        sourceTimeZoneText = event?.sourceTimeZoneText
        location = event?.location.nilIfBlank
        organizer = event?.hostingBody.nilIfBlank
        priceText = event?.priceText.nilIfBlank
        eventURL = event?.link
        status = event == nil ? .unavailable : snapshot.status
        fetchedAt = snapshot.fetchedAt
        checkedAt = snapshot.checkedAt
        cacheAgeSeconds = snapshot.cacheAgeSeconds
        availabilityDetail = event == nil ? (snapshot.availabilityDetail ?? "Event absent from the available upcoming feed") : snapshot.availabilityDetail
        sourceFeedURL = Constants.recreationalSportsEventsURL
    }

    init(_ event: Event, snapshot: EventsSnapshot) {
        self.init(id: event.stableIdentifier, event: event, snapshot: snapshot)
    }
}

private extension String {
    var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}

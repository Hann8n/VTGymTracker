import AppIntents

/// An empty array still carries availability, retrieval time, and search/feed limits.
struct EventSearchResultEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Upcoming Events Result"
    @Property(title: "Events") var events: [CampusEventEntity]
    @Property(title: "Returned Count") var returnedCount: Int
    @Property(title: "Matching Count in Feed") var matchingCount: Int?
    @Property(title: "From") var from: Date
    @Property(title: "Before") var before: Date?
    @Property(title: "Maximum Results") var limit: Int
    @Property(title: "Data Status") var status: EventsDataStatus
    @Property(title: "Fetched At") var fetchedAt: Date?
    @Property(title: "Checked At") var checkedAt: Date
    @Property(title: "Cache Age in Seconds") var cacheAgeSeconds: Double?
    @Property(title: "Unreadable Source Records") var rejectedRecordCount: Int?
    @Property(title: "Availability Detail") var availabilityDetail: String?
    @Property(title: "Source Feed URL") var sourceFeedURL: URL
    @Property(title: "Source Limitation") var sourceLimitation: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(returnedCount) events", subtitle: "\(status.rawValue)")
    }

    init() {
        events = []
        returnedCount = 0
        matchingCount = nil
        from = Date()
        before = nil
        limit = 5
        status = .unavailable
        fetchedAt = nil
        checkedAt = from
        cacheAgeSeconds = nil
        rejectedRecordCount = nil
        availabilityDetail = "No events fetched"
        sourceFeedURL = Constants.recreationalSportsEventsURL
        sourceLimitation = Self.sourceLimitationText
    }

    private static let sourceLimitationText = "Recreational Sports feed only, limited by the source request to 40 records. Missing price does not mean free. Times use America/New_York."

    init(selection: EventsSelection, snapshot: EventsSnapshot) {
        events = selection.events.map { CampusEventEntity($0, snapshot: snapshot) }
        returnedCount = events.count
        matchingCount = snapshot.status == .unavailable ? nil : selection.matchingCount
        from = selection.from
        before = selection.before
        limit = selection.limit
        status = snapshot.status
        fetchedAt = snapshot.fetchedAt
        checkedAt = snapshot.checkedAt
        cacheAgeSeconds = snapshot.cacheAgeSeconds
        rejectedRecordCount = snapshot.rejectedRecordCount
        availabilityDetail = snapshot.availabilityDetail
        sourceFeedURL = Constants.recreationalSportsEventsURL
        sourceLimitation = Self.sourceLimitationText
    }
}

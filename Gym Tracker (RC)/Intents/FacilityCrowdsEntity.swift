import AppIntents

/// A result at one retrieval time, not a persisted facility whose count might silently change.
struct FacilityCrowdsEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Facility Crowds"

    @Property(title: "Facility") var facility: TrackedFacility
    @Property(title: "Facility ID") var facilityID: String
    @Property(title: "Facility Name") var name: String
    @Property(title: "Climbing Facility") var isClimbingFacility: Bool
    @Property(title: "Reported People") var count: Int?
    @Property(title: "Capacity") var capacity: Int
    @Property(title: "Fullness Percent") var fullnessPercent: Double?
    @Property(title: "Data Status") var status: CrowdDataStatus
    @Property(title: "Fetched At") var fetchedAt: Date?
    @Property(title: "Checked At") var checkedAt: Date
    @Property(title: "Last Successful Fetch") var lastSuccessfulFetchAt: Date?
    @Property(title: "Source Measurement Time") var sourceMeasuredAt: Date?
    @Property(title: "Cache Age in Seconds") var cacheAgeSeconds: Double?
    @Property(title: "Availability Detail") var availabilityDetail: String?
    @Property(title: "Source") var source: String
    @Property(title: "Source URL") var sourceURL: URL
    @Property(title: "Source Limitation") var sourceLimitation: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(status.rawValue)")
    }

    init() {
        facility = .mcComas
        facilityID = Constants.mcComasFacilityId
        name = TrackedFacility.mcComas.name
        isClimbingFacility = false
        count = nil
        capacity = Constants.mcComasMaxCapacity
        fullnessPercent = nil
        status = .unavailable
        fetchedAt = nil
        checkedAt = Date()
        lastSuccessfulFetchAt = nil
        sourceMeasuredAt = nil
        cacheAgeSeconds = nil
        availabilityDetail = "No reading fetched"
        source = "Virginia Tech RecSports"
        sourceURL = Constants.facilityDataAPIURL
        sourceLimitation = "Reported occupancy depends on swipe-in and swipe-out data. The source does not provide a measurement timestamp."
    }

    init(_ snapshot: OccupancySnapshot) {
        self.init()
        facility = snapshot.facility
        facilityID = snapshot.facility.id
        name = snapshot.facility.name
        isClimbingFacility = snapshot.facility == .boulderingWall
        count = snapshot.count
        capacity = snapshot.capacity
        fullnessPercent = snapshot.fullnessPercent
        status = snapshot.status
        fetchedAt = snapshot.fetchedAt
        checkedAt = snapshot.checkedAt
        lastSuccessfulFetchAt = snapshot.lastSuccessfulFetchAt
        sourceMeasuredAt = snapshot.sourceMeasuredAt
        cacheAgeSeconds = snapshot.cacheAgeSeconds
        availabilityDetail = snapshot.unavailableReason
    }
}

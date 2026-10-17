import AppIntents

struct CurrentCrowdsIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Current Crowds"
    static var description = IntentDescription("Get reported occupancy, capacity, fullness and data freshness for Virginia Tech recreation facilities. Compare McComas Hall and War Memorial Hall; report the Bouldering Wall separately. Counts depend on RecSports swipe data, not a forecast.")
    static var openAppWhenRun = false
    static var isDiscoverable = true

    @Parameter(title: "Facility", default: .allFacilities)
    var facility: TrackedFacility

    static var parameterSummary: some ParameterSummary {
        Summary("Check current crowds at \(\.$facility)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[FacilityCrowdsEntity]> & ProvidesDialog {
        let snapshots = await CrowdsService.currentCrowds(for: facility)
        let status = snapshots.contains { $0.status == .unavailable } ? "unavailable"
            : snapshots.contains { $0.status == .cached } ? "cached" : "live"
        await AppMetrics.shared.track(.siriCrowds, properties: ["status": status])
        return response(for: snapshots)
    }

    // Shared by perform() and the deterministic result-contract tests.
    func response(for snapshots: [OccupancySnapshot]) -> some IntentResult & ReturnsValue<[FacilityCrowdsEntity]> & ProvidesDialog {
        .result(value: snapshots.map(FacilityCrowdsEntity.init), dialog: IntentDialog(stringLiteral: CrowdsDialog.describe(snapshots)))
    }
}

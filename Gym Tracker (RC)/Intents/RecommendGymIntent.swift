import AppIntents

struct RecommendGymIntent: AppIntent {
    static var title: LocalizedStringResource = "Choose a Less Crowded Gym"
    static var description = IntentDescription("Compare current reported fullness at McComas and War Memorial and suggest the less crowded gym. Based only on occupancy, not equipment, travel time or opening hours. Requires a fresh count for both gyms; similar readings do not produce a forced winner.")
    static var openAppWhenRun = false
    @available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { .background }
    static var isDiscoverable = true

    static var parameterSummary: some ParameterSummary {
        Summary("Choose a less crowded gym")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[FacilityCrowdsEntity]> & ProvidesDialog {
        let snapshots = await CrowdsService.currentCrowds(facilities: TrackedFacility.gyms)
        let status = snapshots.contains { $0.status == .unavailable } ? "unavailable"
            : snapshots.contains { $0.status == .cached } ? "cached" : "live"
        // This is another crowd query; keep the existing privacy-preserving analytics contract.
        await AppMetrics.shared.track(.siriCrowds, properties: ["status": status])
        return response(for: snapshots)
    }

    func response(for snapshots: [OccupancySnapshot]) -> some IntentResult & ReturnsValue<[FacilityCrowdsEntity]> & ProvidesDialog {
        .result(value: snapshots.map(FacilityCrowdsEntity.init), dialog: IntentDialog(stringLiteral: CrowdsDialog.recommend(snapshots)))
    }
}

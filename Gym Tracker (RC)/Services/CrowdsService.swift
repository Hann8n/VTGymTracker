import Foundation

enum CrowdsService {
    static func currentCrowds(for selection: TrackedFacility) async -> [OccupancySnapshot] {
        await currentCrowds(facilities: selection.facilities)
    }

    static func currentCrowds(facilities: [TrackedFacility]) async -> [OccupancySnapshot] {
        let store = OccupancySnapshotStore(defaults: UserDefaults(suiteName: Constants.appGroupID))
        let previous = facilities.map { store.read($0, at: Date()) }
        let results = await GymOccupancyFetcher.fetchSnapshots(facilities: facilities, previous: previous)
        results.forEach { store.write($0) }
        // Do not update the global widget date: a single-facility action cannot make other readings fresh.
        return results
    }
}

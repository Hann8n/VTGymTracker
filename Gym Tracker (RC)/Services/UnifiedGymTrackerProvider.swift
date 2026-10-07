import WidgetKit
import SwiftUI

struct UnifiedGymTrackerEntry: TimelineEntry {
    let date: Date
    let mcComasOccupancy: Int
    let warMemorialOccupancy: Int
    let boulderingWallOccupancy: Int
    let maxMcComasCapacity: Int
    let maxWarMemorialCapacity: Int
    let maxBoulderingWallCapacity: Int
}

struct UnifiedGymTrackerProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> UnifiedGymTrackerEntry {
        UnifiedGymTrackerEntry(
            date: Date(),
            mcComasOccupancy: 300,
            warMemorialOccupancy: 600,
            boulderingWallOccupancy: 4,
            maxMcComasCapacity: Constants.mcComasMaxCapacity,
            maxWarMemorialCapacity: Constants.warMemorialMaxCapacity,
            maxBoulderingWallCapacity: Constants.boulderingWallMaxCapacity
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (UnifiedGymTrackerEntry) -> Void) {
        completion(createEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<UnifiedGymTrackerEntry>) -> Void) {
        let shared = UserDefaults(suiteName: Constants.appGroupID)
        // Prefer data the app just fetched; avoids a redundant network call
        // right after the app stored fresh values and reloaded timelines.
        if let last = shared?.object(forKey: "lastFetchDate") as? Date,
           Date().timeIntervalSince(last) < 90 {
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [createEntry()], policy: .after(next)))
            return
        }
        Task {
            let (mc, wm, bw) = await GymOccupancyFetcher.fetchForWidget()
            // A failed fetch reuses the last good value only while it is recent (see SharedOccupancyStore);
            // otherwise it shows 0 (empty state), never a fossilized count.
            let mcFinal = mc ?? SharedOccupancyStore.fresh(.mcComas) ?? 0
            let wmFinal = wm ?? SharedOccupancyStore.fresh(.warMemorial) ?? 0
            let bwFinal = bw ?? SharedOccupancyStore.fresh(.boulderingWall) ?? 0

            SharedOccupancyStore.record(mc, for: .mcComas)
            SharedOccupancyStore.record(wm, for: .warMemorial)
            SharedOccupancyStore.record(bw, for: .boulderingWall)
            if mc != nil || wm != nil || bw != nil { shared?.set(Date(), forKey: "lastFetchDate") }

            let entry = UnifiedGymTrackerEntry(
                date: Date(),
                mcComasOccupancy: mcFinal,
                warMemorialOccupancy: wmFinal,
                boulderingWallOccupancy: bwFinal,
                maxMcComasCapacity: Constants.mcComasMaxCapacity,
                maxWarMemorialCapacity: Constants.warMemorialMaxCapacity,
                maxBoulderingWallCapacity: Constants.boulderingWallMaxCapacity
            )
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func createEntry() -> UnifiedGymTrackerEntry {
        let sharedDefaults = UserDefaults(suiteName: Constants.appGroupID)
        let mcOccupancy = sharedDefaults?.integer(forKey: "mcComasOccupancy") ?? 0
        let wmOccupancy = sharedDefaults?.integer(forKey: "warMemorialOccupancy") ?? 0
        let bwOccupancy = sharedDefaults?.integer(forKey: "boulderingWallOccupancy") ?? 0

        return UnifiedGymTrackerEntry(
            date: Date(),
            mcComasOccupancy: mcOccupancy,
            warMemorialOccupancy: wmOccupancy,
            boulderingWallOccupancy: bwOccupancy,
            maxMcComasCapacity: Constants.mcComasMaxCapacity,
            maxWarMemorialCapacity: Constants.warMemorialMaxCapacity,
            maxBoulderingWallCapacity: Constants.boulderingWallMaxCapacity
        )
    }
}

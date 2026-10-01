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
            let last = shared?.object(forKey: "lastFetchDate") as? Date
            // Only reuse stored values when they are recent; never fossilize stale counts.
            let sharedFresh = last.map { Date().timeIntervalSince($0) < 15 * 60 } ?? false
            let mcFinal = mc ?? (sharedFresh ? shared?.integer(forKey: "mcComasOccupancy") ?? 0 : 0)
            let wmFinal = wm ?? (sharedFresh ? shared?.integer(forKey: "warMemorialOccupancy") ?? 0 : 0)
            let bwFinal = bw ?? (sharedFresh ? shared?.integer(forKey: "boulderingWallOccupancy") ?? 0 : 0)

            if mc != nil { shared?.set(mc!, forKey: "mcComasOccupancy") }
            if wm != nil { shared?.set(wm!, forKey: "warMemorialOccupancy") }
            if bw != nil { shared?.set(bw!, forKey: "boulderingWallOccupancy") }
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

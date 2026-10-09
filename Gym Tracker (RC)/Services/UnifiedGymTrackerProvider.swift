import WidgetKit
import SwiftUI

struct UnifiedGymTrackerEntry: TimelineEntry {
    let date: Date
    let mcComasOccupancy: Int?
    let warMemorialOccupancy: Int?
    let boulderingWallOccupancy: Int?
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
            // Unknown stays nil; a valid zero is an available, empty facility.
            let mcFinal = mc
            let wmFinal = wm
            let bwFinal = bw

            if let mc { shared?.set(mc, forKey: "mcComasOccupancy") } else { shared?.removeObject(forKey: "mcComasOccupancy") }
            if let wm { shared?.set(wm, forKey: "warMemorialOccupancy") } else { shared?.removeObject(forKey: "warMemorialOccupancy") }
            if let bw { shared?.set(bw, forKey: "boulderingWallOccupancy") } else { shared?.removeObject(forKey: "boulderingWallOccupancy") }
            if Constants.forceMockOccupancy {
                TrackedFacility.individualFacilities.forEach { shared?.removeObject(forKey: $0.fetchDateKey) }
            }
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
        let recent = (sharedDefaults?.object(forKey: "lastFetchDate") as? Date).map {
            (0..<90).contains(Date().timeIntervalSince($0))
        } ?? false
        let mcOccupancy = sharedDefaults?.object(forKey: "mcComasOccupancy") as? Int
        let wmOccupancy = sharedDefaults?.object(forKey: "warMemorialOccupancy") as? Int
        let bwOccupancy = sharedDefaults?.object(forKey: "boulderingWallOccupancy") as? Int

        return UnifiedGymTrackerEntry(
            date: Date(),
            mcComasOccupancy: recent ? mcOccupancy : nil,
            warMemorialOccupancy: recent ? wmOccupancy : nil,
            boulderingWallOccupancy: recent ? bwOccupancy : nil,
            maxMcComasCapacity: Constants.mcComasMaxCapacity,
            maxWarMemorialCapacity: Constants.warMemorialMaxCapacity,
            maxBoulderingWallCapacity: Constants.boulderingWallMaxCapacity
        )
    }
}

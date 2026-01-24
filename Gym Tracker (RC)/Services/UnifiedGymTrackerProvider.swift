import WidgetKit
import SwiftUI

struct UnifiedGymTrackerEntry: TimelineEntry {
    let date: Date
    let mcComasOccupancy: Int
    let warMemorialOccupancy: Int
    let maxMcComasCapacity: Int
    let maxWarMemorialCapacity: Int
}

struct UnifiedGymTrackerProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> UnifiedGymTrackerEntry {
        UnifiedGymTrackerEntry(
            date: Date(),
            mcComasOccupancy: 300,
            warMemorialOccupancy: 600,
            maxMcComasCapacity: Constants.mcComasMaxCapacity,
            maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (UnifiedGymTrackerEntry) -> Void) {
        completion(createEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<UnifiedGymTrackerEntry>) -> Void) {
        Task {
            let (mc, wm) = await GymOccupancyFetcher.fetchForWidget()
            let shared = UserDefaults(suiteName: Constants.appGroupID)
            let mcFinal = mc ?? shared?.integer(forKey: "mcComasOccupancy") ?? 0
            let wmFinal = wm ?? shared?.integer(forKey: "warMemorialOccupancy") ?? 0

            if mc != nil { shared?.set(mc!, forKey: "mcComasOccupancy") }
            if wm != nil { shared?.set(wm!, forKey: "warMemorialOccupancy") }
            if mc != nil || wm != nil { shared?.set(Date(), forKey: "lastFetchDate") }

            let entry = UnifiedGymTrackerEntry(
                date: Date(),
                mcComasOccupancy: mcFinal,
                warMemorialOccupancy: wmFinal,
                maxMcComasCapacity: Constants.mcComasMaxCapacity,
                maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
            )
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func createEntry() -> UnifiedGymTrackerEntry {
        let sharedDefaults = UserDefaults(suiteName: Constants.appGroupID)
        let mcOccupancy = sharedDefaults?.integer(forKey: "mcComasOccupancy") ?? 0
        let wmOccupancy = sharedDefaults?.integer(forKey: "warMemorialOccupancy") ?? 0
        
        return UnifiedGymTrackerEntry(
            date: Date(),
            mcComasOccupancy: mcOccupancy,
            warMemorialOccupancy: wmOccupancy,
            maxMcComasCapacity: Constants.mcComasMaxCapacity,
            maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
        )
    }
}

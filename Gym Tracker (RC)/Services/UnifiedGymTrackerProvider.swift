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
        let entry = createEntry()
        let timeline = createTimeline(from: entry)
        completion(timeline)
    }
    
    private func createEntry() -> UnifiedGymTrackerEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.VTGymApp.D8VXFBV8SJ")
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
    
    private func createTimeline(from entry: UnifiedGymTrackerEntry) -> Timeline<UnifiedGymTrackerEntry> {
        let currentDate = Date()
        let calendar = Calendar.current
        
        var entries = [entry]
        
        for i in 1...12 {
            if let futureDate = calendar.date(byAdding: .minute, value: i * 30, to: currentDate) {
                let futureEntry = UnifiedGymTrackerEntry(
                    date: futureDate,
                    mcComasOccupancy: entry.mcComasOccupancy,
                    warMemorialOccupancy: entry.warMemorialOccupancy,
                    maxMcComasCapacity: entry.maxMcComasCapacity,
                    maxWarMemorialCapacity: entry.maxWarMemorialCapacity
                )
                entries.append(futureEntry)
            }
        }
        
        let nextUpdate = calendar.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate.addingTimeInterval(30 * 60)
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }
}

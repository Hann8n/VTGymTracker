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
    
    private let appGroupID = "group.VTGymApp.D8VXFBV8SJ"
    
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
        let entry = loadLatestData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<UnifiedGymTrackerEntry>) -> Void) {
        let currentDate = Date()
        let estTimeZone = TimeZone(identifier: "America/New_York")! // EST Timezone
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: estTimeZone, from: currentDate)
        
        // Define disabled window start and end times
        let disabledStartHour = 23
        let disabledStartMinute = 15
        let disabledEndHour = 4
        let disabledEndMinute = 45
        
        // Create DateComponents for disabled start and end times
        var disabledStartComponents = components
        disabledStartComponents.hour = disabledStartHour
        disabledStartComponents.minute = disabledStartMinute
        disabledStartComponents.second = 0
        
        var disabledEndComponents = components
        disabledEndComponents.hour = disabledEndHour
        disabledEndComponents.minute = disabledEndMinute
        disabledEndComponents.second = 0
        
        // If current time is after disabled start but before midnight, end time is next day
        if components.hour! >= disabledStartHour {
            disabledEndComponents.day! += 1
        }
        
        // Get actual Date objects for start and end
        guard let disabledStartDate = calendar.date(from: disabledStartComponents),
              let disabledEndDate = calendar.date(from: disabledEndComponents) else {
            // Fallback to regular 15-minute updates if date creation fails
            scheduleRegularUpdates(from: currentDate, completion: completion)
            return
        }
        
        if currentDate >= disabledStartDate && currentDate < disabledEndDate {
            // Currently within disabled window
            // Schedule next update at disabledEndDate (4:45 AM EST)
            let nextUpdateDate = disabledEndDate
            let entry = loadLatestData()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        } else {
            // Outside disabled window
            // Schedule next update in 15 minutes
            let nextUpdateDate = calendar.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(15 * 60)
            let entry = loadLatestData()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
    
    private func loadLatestData() -> UnifiedGymTrackerEntry {
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        
        let mcOccupancy   = sharedDefaults?.integer(forKey: "mcComasOccupancy")     ?? 0
        let wmOccupancy   = sharedDefaults?.integer(forKey: "warMemorialOccupancy") ?? 0
        return UnifiedGymTrackerEntry(
            date: Date(),
            mcComasOccupancy: mcOccupancy,
            warMemorialOccupancy: wmOccupancy,
            maxMcComasCapacity: Constants.mcComasMaxCapacity,
            maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
        )
    }
    
    private func scheduleRegularUpdates(from currentDate: Date, completion: @escaping (Timeline<UnifiedGymTrackerEntry>) -> Void) {
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(15 * 60)
        let entry = loadLatestData()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

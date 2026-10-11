import Foundation

enum CrowdsDialog {
    static func describe(_ readings: [OccupancySnapshot]) -> String {
        let details = readings.map { reading -> String in
            guard let count = reading.count, let percent = reading.fullnessPercent else {
                return "\(reading.facility.name): occupancy unavailable."
            }
            let fullness = OccupancyMath.wholePercent(fromPercent: percent)
            let prefix = reading.status == .cached ? "Last fetched" : "RecSports reports"
            let age = reading.cacheAgeSeconds.map { " Cached \(Int(ceil($0))) seconds ago; live data unavailable." } ?? ""
            return "\(prefix) \(reading.facility.name): \(count) of \(reading.capacity), \(fullness)% full.\(age)"
        }.joined(separator: " ")
        guard readings.count > 1 else { return details }
        let gyms = readings.filter { $0.facility == .mcComas || $0.facility == .warMemorial }
        guard gyms.count == 2, gyms.allSatisfy({ $0.status == .live }),
              let first = gyms[0].fullnessPercent, let second = gyms[1].fullnessPercent else {
            return details + " A live comparison of the two gyms is unavailable."
        }
        let comparison: String
        if first == second {
            comparison = "Both gyms have the same reported fullness."
        } else {
            comparison = "\(gyms[first < second ? 0 : 1].facility.name) has lower reported fullness."
        }
        return details + " " + comparison + " The bouldering wall is a separate climbing facility."
    }
}

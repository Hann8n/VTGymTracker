import Foundation

enum CrowdsDialog {
    static func describe(_ readings: [OccupancySnapshot]) -> String {
        guard !readings.isEmpty else { return "Crowd counts aren't available right now. Try again in a moment." }
        let gyms = readings.filter { TrackedFacility.gyms.contains($0.facility) }
        let walls = readings.filter { $0.facility == .boulderingWall }
        let gymResponse = gyms.map(describeReading).joined(separator: " ")
        let wallResponse = walls.map(describeReading).joined(separator: " ")
        return [gymResponse, wallResponse.isEmpty ? "" : (gyms.isEmpty ? wallResponse : "For bouldering: " + wallResponse)].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// A recommendation is based only on two fresh gym readings, never raw headcounts or the climbing wall.
    static func recommend(_ readings: [OccupancySnapshot]) -> String {
        let gyms = readings.filter { TrackedFacility.gyms.contains($0.facility) }
        guard let mcComas = gyms.first(where: { $0.facility == .mcComas }),
              let war = gyms.first(where: { $0.facility == .warMemorial }),
              mcComas.status == .live, war.status == .live,
              let mcPercent = mcComas.fullnessPercent, let warPercent = war.fullnessPercent else {
            let detail = gyms.isEmpty ? "" : " " + describe(gyms)
            return "There isn't a fresh count for both gyms, so it's hard to say which is less crowded.\(detail)"
        }
        // Sub-percentage-point differences don't justify steering someone to a different gym.
        if abs(mcPercent - warPercent) < 1 {
            if mcPercent == 100 && warPercent == 100 { return "Both gyms are reporting 100% occupancy right now—they're at capacity." }
            return "Crowds are about the same right now: McComas is \(fullness(mcPercent)) full and War Memorial is \(fullness(warPercent)) full."
        }
        let winner = mcPercent < warPercent ? mcComas : war
        let other = mcPercent < warPercent ? war : mcComas
        let bothBusy = min(mcPercent, warPercent) >= 75 ? " Both gyms are busy, though." : ""
        return "\(name(winner.facility)) is the better pick for fewer crowds right now: \(fullness(min(mcPercent, warPercent))) full, compared with \(name(other.facility)) at \(fullness(max(mcPercent, warPercent))).\(bothBusy)"
    }

    private static func describeReading(_ reading: OccupancySnapshot) -> String {
        let facility = name(reading.facility)
        guard reading.status != .unavailable, let percent = reading.fullnessPercent else {
            return "A current crowd count for \(facility) isn't available."
        }
        if reading.status == .cached {
            let age = reading.cacheAgeSeconds.map { ", about \(Int(ceil($0))) seconds ago" } ?? ""
            return "The last reading had \(facility) at \(fullness(percent)) full\(age). A fresh count isn't available."
        }
        let description = percent >= 100 ? "it's at capacity" : percent >= 75 ? "it's busy" : percent >= 50 ? "it's getting busy" : "it's quiet"
        return "\(facility) is \(fullness(percent)) full right now—\(description)."
    }

    private static func fullness(_ percent: Double) -> String {
        if percent > 0 && percent < 1 { return "less than 1%" }
        return "\(OccupancyMath.wholePercent(fromPercent: percent))%"
    }

    private static func name(_ facility: TrackedFacility) -> String {
        switch facility {
        case .mcComas: return "McComas"
        case .warMemorial: return "War Memorial"
        case .boulderingWall: return "The bouldering wall"
        case .allFacilities, .bothGyms: return "The gyms"
        }
    }
}

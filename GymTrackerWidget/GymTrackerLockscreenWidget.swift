//GymTrackerLockScreenWidget.swift
//

import WidgetKit
import SwiftUI
import Combine

// Use the existing Constants.swift file
let gymService = GymService.shared

// MARK: - GymTrackerEntry
struct GymTrackerEntry: TimelineEntry {
    let date: Date
    let mcComasOccupancy: Int
    let warMemorialOccupancy: Int
    let maxMcComasCapacity: Int
    let maxWarMemorialCapacity: Int
}

// MARK: - GymTrackerProvider
struct GymTrackerProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> GymTrackerEntry {
        GymTrackerEntry(date: Date(), mcComasOccupancy: 300, warMemorialOccupancy: 600, maxMcComasCapacity: Constants.mcComasMaxCapacity, maxWarMemorialCapacity: Constants.warMemorialMaxCapacity)
    }

    func getSnapshot(in context: Context, completion: @escaping (GymTrackerEntry) -> Void) {
        Task {
            let mcComasData = await gymService.fetchGymOccupancy(for: Constants.mcComasFacilityId)
            let warMemorialData = await gymService.fetchGymOccupancy(for: Constants.warMemorialFacilityId)

            let entry = GymTrackerEntry(
                date: Date(),
                mcComasOccupancy: mcComasData?.occupancy ?? 0,
                warMemorialOccupancy: warMemorialData?.occupancy ?? 0,
                maxMcComasCapacity: Constants.mcComasMaxCapacity,
                maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GymTrackerEntry>) -> Void) {
        Task {
            let mcComasData = await gymService.fetchGymOccupancy(for: Constants.mcComasFacilityId)
            let warMemorialData = await gymService.fetchGymOccupancy(for: Constants.warMemorialFacilityId)

            let entry = GymTrackerEntry(
                date: Date(),
                mcComasOccupancy: mcComasData?.occupancy ?? 0,
                warMemorialOccupancy: warMemorialData?.occupancy ?? 0,
                maxMcComasCapacity: Constants.mcComasMaxCapacity,
                maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
            )

            // Update the timeline policy to refresh every 15 minutes
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
            completion(timeline)
        }
    }
}

// MARK: - CompactCircularProgressViewLSW (with customizable line thickness and optional inner text)
struct CompactCircularProgressViewLSW: View {
    let percentage: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let fontScale: CGFloat
    let totalSegments: Int
    var showPercentageText: Bool   // New parameter to control text display
    var segmentSpacing: Double = 2.0
    let minimumBrightness: Double = 0.3

    private var segmentAngle: Double {
        (360.0 / Double(totalSegments)) - segmentSpacing
    }

    var body: some View {
        ZStack {
            // Background segments (lighter, for unfilled segments)
            ForEach(0..<totalSegments, id: \.self) { index in
                let startAngle = segmentStartAngle(for: index)
                let endAngle = startAngle + segmentAngle

                CircularSegmentShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(self.segmentColor(for: index).opacity(0.2))
                .frame(width: size, height: size)
            }

            // Foreground segments (filled based on progress)
            ForEach(0..<totalSegments, id: \.self) { index in
                let startAngle = segmentStartAngle(for: index)
                let endAngle = startAngle + segmentAngle

                CircularSegmentShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(self.segmentColor(for: index))
                .opacity(self.opacityForSegment(index: index, adjustedPercentage: percentage / 100.0))
                .frame(width: size, height: size)
            }

            // Center text (optional)
            if showPercentageText {
                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: size * fontScale, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }

    private func segmentStartAngle(for index: Int) -> Double {
        (Double(index) * (segmentAngle + segmentSpacing)) - 90
    }

    private func segmentColor(for index: Int) -> Color {
        if index < totalSegments / 2 {
            return Color.green
        } else if index < (totalSegments * 3) / 4 {
            return Color.orange
        } else {
            return Color.red
        }
    }

    private func opacityForSegment(index: Int, adjustedPercentage: Double) -> Double {
        let segmentProgress = Double(index) / Double(totalSegments)
        let nextSegmentProgress = Double(index + 1) / Double(totalSegments)

        if adjustedPercentage >= nextSegmentProgress {
            return 1.0
        } else if adjustedPercentage > segmentProgress {
            let segmentFraction = (adjustedPercentage - segmentProgress) / (nextSegmentProgress - segmentProgress)
            return max(segmentFraction, minimumBrightness)
        } else {
            return 0.0
        }
    }
}

// Shape for the circular segments
struct CircularSegmentShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - (lineWidth / 2)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: endAngle),
            clockwise: false
        )

        return path
    }
}

// MARK: - McComas Circular Widget View
struct McComasCircularWidgetView: View {
    let entry: GymTrackerEntry

    var body: some View {
        let percentage = (Double(entry.mcComasOccupancy) / Double(entry.maxMcComasCapacity)) * 100.0
        
        CompactCircularProgressViewLSW(
            percentage: percentage,
            size: 55,
            lineWidth: 6,
            fontScale: 0.25,    // Smaller font scale for circular widget
            totalSegments: 12,
            showPercentageText: true // Display text for small circular widget
        )
        .containerBackground(.background, for: .widget)
        .tint(Color.blue)
    }
}

// MARK: - War Memorial Circular Widget View
struct WarMemorialCircularWidgetView: View {
    let entry: GymTrackerEntry

    var body: some View {
        let percentage = (Double(entry.warMemorialOccupancy) / Double(entry.maxWarMemorialCapacity)) * 100.0
        
        CompactCircularProgressViewLSW(
            percentage: percentage,
            size: 55,
            lineWidth: 6,
            fontScale: 0.25,   // Smaller font scale for circular widget
            totalSegments: 12,
            showPercentageText: true // Display text for small circular widget
        )
        .containerBackground(.background, for: .widget)
        .tint(Color.green)
    }
}

// MARK: - Rectangular LockScreen Widget View
struct RectangularLockScreenWidget: View {
    let entry: GymTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("McComas")
                        .font(.caption)
                    HStack(spacing: 0) {
                        Text("\(entry.mcComasOccupancy)")
                            .font(.caption2)
                            .bold()
                        Text(" / \(entry.maxMcComasCapacity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("\(Int((Double(entry.mcComasOccupancy) / Double(entry.maxMcComasCapacity)) * 100))%")
                    .font(.caption)
                    .bold()
                
                CompactCircularProgressViewLSW(
                    percentage: (Double(entry.mcComasOccupancy) / Double(entry.maxMcComasCapacity)) * 100.0,
                    size: 20,
                    lineWidth: 4,
                    fontScale: 0.3, // Smaller font scale for smaller circular widget
                    totalSegments: 12,
                    showPercentageText: false // Hide text in smaller view
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("War Memorial")
                        .font(.caption)
                    HStack(spacing: 0) {
                        Text("\(entry.warMemorialOccupancy)")
                            .font(.caption2)
                            .bold()
                        Text(" / \(entry.maxWarMemorialCapacity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("\(Int((Double(entry.warMemorialOccupancy) / Double(entry.maxWarMemorialCapacity)) * 100))%")
                    .font(.caption)
                    .bold()
                
                CompactCircularProgressViewLSW(
                    percentage: (Double(entry.warMemorialOccupancy) / Double(entry.maxWarMemorialCapacity)) * 100.0,
                    size: 20,
                    lineWidth: 4,
                    fontScale: 0.3, // Smaller font scale for smaller circular widget
                    totalSegments: 12,
                    showPercentageText: false // Hide text in smaller view
                )
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 4)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - GymLockScreenWidgetEntryView
struct GymLockScreenWidgetEntryView: View {
    var entry: GymTrackerProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            RectangularLockScreenWidget(entry: entry)
        case .accessoryCircular:
            McComasCircularWidgetView(entry: entry)
        case .accessoryInline:
            WarMemorialCircularWidgetView(entry: entry)
        default:
            Text("Gym Tracker")
        }
    }
}

// MARK: - GymLockScreenWidgetBundle
struct GymLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        McComasCircularWidget()
        WarMemorialCircularWidget()
        GymTrackerRectangularWidget()
    }
}

// MARK: - McComasCircularWidget
struct McComasCircularWidget: Widget {
    let kind: String = "McComasCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerProvider()) { entry in
            McComasCircularWidgetView(entry: entry)
        }
        .configurationDisplayName("McComas Gym")
        .description("Shows occupancy for McComas Gym.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - WarMemorialCircularWidget
struct WarMemorialCircularWidget: Widget {
    let kind: String = "WarMemorialCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerProvider()) { entry in
            WarMemorialCircularWidgetView(entry: entry)
        }
        .configurationDisplayName("War Memorial Gym")
        .description("Shows occupancy for War Memorial Gym.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - GymTrackerRectangularWidget
struct GymTrackerRectangularWidget: Widget {
    let kind: String = "GymTrackerRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerProvider()) { entry in
            RectangularLockScreenWidget(entry: entry)
        }
        .configurationDisplayName("Gym Tracker")
        .description("Shows gym occupancy for McComas and War Memorial.")
        .supportedFamilies([.accessoryRectangular])
    }
}

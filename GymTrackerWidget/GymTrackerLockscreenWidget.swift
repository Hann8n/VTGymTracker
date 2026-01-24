// GymLockScreenWidget.swift

import WidgetKit
import SwiftUI

// MARK: - McComas Circular Widget View
struct McComasCircularWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        let percentage = (Double(entry.mcComasOccupancy) / Double(entry.maxMcComasCapacity)) * 100.0

        CompactCircularProgressViewLSW(
            percentage: percentage,
            size: 55,
            lineWidth: 6,
            fontScale: 0.25,
            totalSegments: 12,
            showPercentageText: true
        )
        .containerBackground(.background, for: .widget)
        .tint(Color.blue)
    }
}

// MARK: - War Memorial Circular Widget View
struct WarMemorialCircularWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        let percentage = (Double(entry.warMemorialOccupancy) / Double(entry.maxWarMemorialCapacity)) * 100.0

        CompactCircularProgressViewLSW(
            percentage: percentage,
            size: 55,
            lineWidth: 6,
            fontScale: 0.25,
            totalSegments: 12,
            showPercentageText: true
        )
        .containerBackground(.background, for: .widget)
        .tint(Color.green)
    }
}

// MARK: - Rectangular LockScreen Widget View
struct RectangularLockScreenWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Increased spacing for better readability
            // War Memorial Section (Moved to the top)
            HStack(alignment: .center, spacing: 8) { // Added spacing between progress and text
                // Circular Progress Bar moved to the left
                CompactCircularProgressViewLSW(
                    percentage: calculatePercentage(occupancy: entry.warMemorialOccupancy, maxCapacity: entry.maxWarMemorialCapacity),
                    size: 25, // Increased size
                    lineWidth: 4, // Increased line width
                    fontScale: 0.35, // Adjusted font scale
                    totalSegments: 6,
                    showPercentageText: true, // Enable percentage inside circle
                    showPercentageSymbol: false // Disable the % symbol
                )
                
                // Gym Texts
                VStack(alignment: .leading, spacing: 0) {
                    Text("War Memorial")
                        .font(.caption)
                        .lineLimit(1)
                    HStack(spacing: 0) {
                        Text("\(entry.warMemorialOccupancy)")
                            .font(.caption2)
                            .bold()
                            .lineLimit(1)
                        Text(" / \(entry.maxWarMemorialCapacity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            // McComas Section (Moved below War Memorial)
            HStack(alignment: .center, spacing: 8) { // Added spacing between progress and text
                // Circular Progress Bar moved to the left
                CompactCircularProgressViewLSW(
                    percentage: calculatePercentage(occupancy: entry.mcComasOccupancy, maxCapacity: entry.maxMcComasCapacity),
                    size: 25, // Increased size
                    lineWidth: 4, // Increased line width
                    fontScale: 0.35, // Adjusted font scale
                    totalSegments: 6,
                    showPercentageText: true, // Enable percentage inside circle
                    showPercentageSymbol: false // Disable the % symbol
                )
                
                // Gym Texts
                VStack(alignment: .leading, spacing: 0) {
                    Text("McComas")
                        .font(.caption)
                        .lineLimit(1)
                    HStack(spacing: 0) {
                        Text("\(entry.mcComasOccupancy)")
                            .font(.caption2)
                            .bold()
                            .lineLimit(1)
                        Text(" / \(entry.maxMcComasCapacity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Align VStack to the leading edge
        .padding(.vertical, 4) // Adjusted vertical padding for better spacing
        .padding(.leading, 2) // Increased leading padding for left alignment
        .padding(.trailing, 4) // Reduced trailing padding
        .containerBackground(.background, for: .widget)
    }

    private func calculatePercentage(occupancy: Int, maxCapacity: Int) -> Double {
        guard maxCapacity > 0 else { return 0 }
        return (Double(occupancy) / Double(maxCapacity)) * 100
    }
}

// MARK: - McComasCircularWidget
struct McComasCircularWidget: Widget {
    let kind: String = "McComasCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
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
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
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
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
            RectangularLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Gym Tracker")
        .description("Shows gym occupancy for McComas and War Memorial.")
        .supportedFamilies([.accessoryRectangular])
    }
}
// MARK: - CompactCircularProgressViewLSW (with customizable line thickness and optional inner text)
struct CompactCircularProgressViewLSW: View {
    let percentage: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let fontScale: CGFloat
    let totalSegments: Int
    var showPercentageText: Bool   // Existing parameter to control text display
    var showPercentageSymbol: Bool = true // New parameter to control % symbol display
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
                Text(showPercentageSymbol ? String(format: "%.0f%%", percentage) : String(format: "%.0f", percentage))
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

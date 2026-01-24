// GymTrackerLockscreenWidget.swift
// Lock screen accessory widgets: circular (per gym) and rectangular (all three).
// Circular uses the branded segmented progress ring.

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Segmented Circular (branded segment style, compact for accessory)
struct LockScreenSegmentedCircularView: View {
    let percentage: Double
    let isEmpty: Bool
    let totalSegments: Int
    var label: String? = nil  // e.g. "WM", "MC", "BW" – shown below the number
    var size: CGFloat = 50
    var lineWidth: CGFloat = 6
    var fontScale: CGFloat = 0.28
    var segmentSpacing: Double = 1.5

    private var segmentAngle: Double {
        (360.0 / Double(totalSegments)) - segmentSpacing
    }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Background segments (tinted track: segment color 0.28, empty 0.22)
                ForEach(0..<totalSegments, id: \.self) { index in
                    SegmentShape(
                        startAngle: segmentStartAngle(for: index),
                        endAngle: segmentStartAngle(for: index) + segmentAngle,
                        lineWidth: lineWidth
                    )
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(isEmpty ? Color.gray.opacity(0.20) : segmentColor(index).opacity(0.20))
                }

                // Foreground segments (filled by percentage)
                ForEach(0..<totalSegments, id: \.self) { index in
                    SegmentShape(
                        startAngle: segmentStartAngle(for: index),
                        endAngle: segmentStartAngle(for: index) + segmentAngle,
                        lineWidth: lineWidth
                    )
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(isEmpty ? Color.gray : segmentColor(index))
                    .opacity(opacityForSegment(index: index, adjustedPercentage: percentage / 100.0))
                }

                // Center: number and optional gym label
                VStack(spacing: 1) {
                    Group {
                        if isEmpty {
                            Text("—")
                                .font(.system(size: s * fontScale, weight: .bold))
                                .foregroundColor(.secondary)
                        } else {
                            (Text("\(Int(percentage))")
                                .font(.system(size: s * fontScale, weight: .bold))
                                .foregroundColor(.primary)
                                + Text("%")
                                .font(.system(size: s * fontScale * 0.6, weight: .bold))
                                .foregroundColor(.primary))
                        }
                    }
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    if let label {
                        Text(label)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: s, height: s)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func segmentStartAngle(for index: Int) -> Double {
        (Double(index) * (segmentAngle + segmentSpacing)) - 90
    }

    private func segmentColor(_ index: Int) -> Color {
        index < totalSegments / 2 ? Color("WidgetCustomGreen") :
        index < (totalSegments * 3) / 4 ? Color("WidgetCustomOrange") : Color("WidgetCustomMaroon")
    }

    private func opacityForSegment(index: Int, adjustedPercentage: Double) -> Double {
        let segmentProgress = Double(index) / Double(totalSegments)
        let nextSegmentProgress = Double(index + 1) / Double(totalSegments)
        if adjustedPercentage >= nextSegmentProgress { return 1.0 }
        if adjustedPercentage > segmentProgress {
            return max((adjustedPercentage - segmentProgress) / (nextSegmentProgress - segmentProgress), 0.3)
        }
        return 0.0
    }
}

// MARK: - Circular Widget Views (one per gym)
struct McComasCircularWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        let pct = entry.maxMcComasCapacity > 0
            ? (Double(entry.mcComasOccupancy) / Double(entry.maxMcComasCapacity)) * 100
            : 0
        LockScreenSegmentedCircularView(percentage: pct, isEmpty: entry.mcComasOccupancy == 0, totalSegments: 12, label: "MC")
    }
}

struct WarMemorialCircularWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        let pct = entry.maxWarMemorialCapacity > 0
            ? (Double(entry.warMemorialOccupancy) / Double(entry.maxWarMemorialCapacity)) * 100
            : 0
        LockScreenSegmentedCircularView(percentage: pct, isEmpty: entry.warMemorialOccupancy == 0, totalSegments: 12, label: "WM")
    }
}

struct BoulderingWallCircularWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        let pct = entry.maxBoulderingWallCapacity > 0
            ? (Double(entry.boulderingWallOccupancy) / Double(entry.maxBoulderingWallCapacity)) * 100
            : 0
        LockScreenSegmentedCircularView(percentage: pct, isEmpty: entry.boulderingWallOccupancy == 0, totalSegments: 8, label: "BW")
    }
}

// MARK: - Rectangular Lock Screen Widget (all three gyms)
struct RectangularLockScreenWidgetView: View {
    let entry: UnifiedGymTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            row(label: "War Memorial", occupancy: entry.warMemorialOccupancy, max: entry.maxWarMemorialCapacity)
            row(label: "McComas", occupancy: entry.mcComasOccupancy, max: entry.maxMcComasCapacity)
            row(label: "Bouldering Wall", occupancy: entry.boulderingWallOccupancy, max: entry.maxBoulderingWallCapacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }

    private func row(label: String, occupancy: Int, max: Int) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer(minLength: 2)
            (Text("\(occupancy.abbreviatedCount)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                + Text("/\(max.abbreviatedCount)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary))
                .lineLimit(1)
        }
    }
}

// MARK: - Widgets

struct McComasCircularWidget: Widget {
    let kind: String = "McComasCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
            McComasCircularWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("McComas")
        .description("McComas gym occupancy")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct WarMemorialCircularWidget: Widget {
    let kind: String = "WarMemorialCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
            WarMemorialCircularWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("War Memorial")
        .description("War Memorial gym occupancy")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct BoulderingWallCircularWidget: Widget {
    let kind: String = "BoulderingWallCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
            BoulderingWallCircularWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Bouldering Wall")
        .description("Bouldering wall occupancy")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct GymTrackerRectangularWidget: Widget {
    let kind: String = "GymTrackerRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
            RectangularLockScreenWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("VT Gyms")
        .description("War Memorial, McComas, and Bouldering occupancy")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}

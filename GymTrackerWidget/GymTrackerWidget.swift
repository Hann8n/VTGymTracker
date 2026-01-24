import WidgetKit
import SwiftUI

// Ensure UnifiedTimelineProvider.swift is part of the same target/module

struct GymTrackerWidgetEntryView: View {
    var entry: UnifiedGymTrackerEntry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
            case .systemMedium:
                MediumWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
            default:
                EmptyView()
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Occupancy Row (app-consistent: circular segmented progress + n/max like OccupancyCard)
struct OccupancyRowView: View {
    let title: String
    let occupancy: Int
    let maxCapacity: Int
    let totalSegments: Int
    let circleSize: CGFloat
    let lineWidth: CGFloat
    let fontScale: CGFloat
    let titleFont: CGFloat
    let countFont: CGFloat
    let showPercentageInCircle: Bool
    let widgetRenderingMode: WidgetRenderingMode

    private var percentage: Double {
        guard maxCapacity > 0 else { return 0 }
        return (Double(occupancy) / Double(maxCapacity)) * 100
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            CircularProgressView(
                percentage: percentage,
                size: circleSize,
                lineWidth: lineWidth,
                fontScale: fontScale,
                widgetRenderingMode: widgetRenderingMode,
                totalSegments: totalSegments,
                isEmpty: occupancy == 0,
                showPercentageSymbol: showPercentageInCircle
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: titleFont, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                // Same size for occupancy and max; keep occupancy primary, max secondary
                (Text("\(occupancy.abbreviatedCount)")
                    .font(.system(size: countFont))
                    .foregroundColor(.primary)
                    + Text(" / \(maxCapacity.abbreviatedCount)")
                    .font(.system(size: countFont))
                    .foregroundColor(.secondary))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Small Widget (stacked rows, app-consistent; circular segmented progress)
struct SmallWidgetView: View {
    let entry: UnifiedGymTrackerEntry
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OccupancyRowView(
                title: "War Memorial",
                occupancy: entry.warMemorialOccupancy,
                maxCapacity: entry.maxWarMemorialCapacity,
                totalSegments: 20,
                circleSize: 36,
                lineWidth: 4,
                fontScale: 0.32,
                titleFont: 11,
                countFont: 12,
                showPercentageInCircle: false,
                widgetRenderingMode: widgetRenderingMode
            )

            Divider()

            OccupancyRowView(
                title: "McComas",
                occupancy: entry.mcComasOccupancy,
                maxCapacity: entry.maxMcComasCapacity,
                totalSegments: 20,
                circleSize: 36,
                lineWidth: 4,
                fontScale: 0.32,
                titleFont: 11,
                countFont: 12,
                showPercentageInCircle: false,
                widgetRenderingMode: widgetRenderingMode
            )

            Divider()

            OccupancyRowView(
                title: "Bouldering Wall",
                occupancy: entry.boulderingWallOccupancy,
                maxCapacity: entry.maxBoulderingWallCapacity,
                totalSegments: 8,
                circleSize: 36,
                lineWidth: 4,
                fontScale: 0.32,
                titleFont: 11,
                countFont: 12,
                showPercentageInCircle: false,
                widgetRenderingMode: widgetRenderingMode
            )
        }
        .padding(12)
    }
}

// MARK: - Medium Widget Column (large circle on top, info beneath)
private struct MediumWidgetColumnView: View {
    let title: String
    let occupancy: Int
    let maxCapacity: Int
    let totalSegments: Int
    let widgetRenderingMode: WidgetRenderingMode

    private var percentage: Double {
        guard maxCapacity > 0 else { return 0 }
        return (Double(occupancy) / Double(maxCapacity)) * 100
    }

    var body: some View {
        VStack(spacing: 10) {
            CircularProgressView(
                percentage: percentage,
                size: 76,
                lineWidth: 8,
                fontScale: 0.26,
                widgetRenderingMode: widgetRenderingMode,
                totalSegments: totalSegments,
                isEmpty: occupancy == 0,
                showPercentageSymbol: true
            )
            .padding(.bottom, 5)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                (Text("\(occupancy.abbreviatedCount)")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    + Text(" / \(maxCapacity.abbreviatedCount)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Medium Widget (3 columns: large circle on top, info beneath each)
struct MediumWidgetView: View {
    let entry: UnifiedGymTrackerEntry
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            MediumWidgetColumnView(
                title: "War Memorial",
                occupancy: entry.warMemorialOccupancy,
                maxCapacity: entry.maxWarMemorialCapacity,
                totalSegments: 20,
                widgetRenderingMode: widgetRenderingMode
            )
            MediumWidgetColumnView(
                title: "McComas",
                occupancy: entry.mcComasOccupancy,
                maxCapacity: entry.maxMcComasCapacity,
                totalSegments: 20,
                widgetRenderingMode: widgetRenderingMode
            )
            MediumWidgetColumnView(
                title: "Bouldering Wall",
                occupancy: entry.boulderingWallOccupancy,
                maxCapacity: entry.maxBoulderingWallCapacity,
                totalSegments: 8,
                widgetRenderingMode: widgetRenderingMode
            )
        }
        .padding(12)
    }
}

// MARK: - Circular Progress Components
struct CircularProgressView: View {
    let percentage: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let fontScale: CGFloat
    let widgetRenderingMode: WidgetRenderingMode
    let totalSegments: Int
    var segmentSpacing: Double = 2.0
    let isEmpty: Bool // New parameter to indicate empty state
    let showPercentageSymbol: Bool // New parameter to control "%" display

    private var segmentAngle: Double {
        (360.0 / Double(totalSegments)) - segmentSpacing
    }

    var body: some View {
        ZStack {
            // Background segments (tinted track: segment color 0.28, empty 0.22)
            ForEach(0..<totalSegments, id: \.self) { index in
                SegmentShape(
                    startAngle: segmentStartAngle(for: index),
                    endAngle: segmentStartAngle(for: index) + segmentAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(isEmpty ? Color("WidgetCustomGreen").opacity(0.22) : segmentColor(index).opacity(0.28))
            }
            
            // Foreground segments
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

            // Percentage Text
            Text(String(format: "%.0f%@", percentage, showPercentageSymbol ? "%" : ""))
                .font(.system(size: size * fontScale, weight: .bold))
                .foregroundColor(widgetRenderingMode == .accented ? (isEmpty ? Color.gray : .accentColor) : (isEmpty ? Color.gray : .primary))
        }
        .frame(width: size, height: size)
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

        if adjustedPercentage >= nextSegmentProgress {
            return 1.0
        } else if adjustedPercentage > segmentProgress {
            return (adjustedPercentage - segmentProgress) / (nextSegmentProgress - segmentProgress)
        }
        return 0.0
    }
}

struct SegmentShape: Shape {
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

// MARK: - Widget Configuration
struct GymTrackerWidget: Widget {
    let kind: String = "GymTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnifiedGymTrackerProvider()) { entry in
            GymTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Gym Tracker")
        .description("Displays live occupancy for campus gyms")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled() // Avoid iOS 17+ system margins that can cause background/edge glitches on open/close
    }
}

// MARK: - Previews
struct GymTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GymTrackerWidgetEntryView(
                entry: UnifiedGymTrackerEntry(
                    date: Date(),
                    mcComasOccupancy: 450,
                    warMemorialOccupancy: 900,
                    boulderingWallOccupancy: 5,
                    maxMcComasCapacity: Constants.mcComasMaxCapacity,
                    maxWarMemorialCapacity: Constants.warMemorialMaxCapacity,
                    maxBoulderingWallCapacity: Constants.boulderingWallMaxCapacity
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            GymTrackerWidgetEntryView(
                entry: UnifiedGymTrackerEntry(
                    date: Date(),
                    mcComasOccupancy: 0, // Empty state
                    warMemorialOccupancy: 0, // Empty state
                    boulderingWallOccupancy: 0, // Empty state
                    maxMcComasCapacity: Constants.mcComasMaxCapacity,
                    maxWarMemorialCapacity: Constants.warMemorialMaxCapacity,
                    maxBoulderingWallCapacity: Constants.boulderingWallMaxCapacity
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

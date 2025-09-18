import WidgetKit
import SwiftUI

// Ensure UnifiedTimelineProvider.swift is part of the same target/module

struct GymTrackerWidgetEntryView: View {
    var entry: UnifiedGymTrackerEntry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
        case .systemMedium:
            MediumWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
        default:
            EmptyView()
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: UnifiedGymTrackerEntry
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Reduced spacing from 16 to 8
            // War Memorial Section
            HStack(spacing: 8) {
                CircularProgressView(
                    percentage: calculatePercentage(occupancy: entry.warMemorialOccupancy, maxCapacity: entry.maxWarMemorialCapacity),
                    size: 40,
                    lineWidth: 6,
                    fontScale: 0.30,
                    widgetRenderingMode: widgetRenderingMode,
                    totalSegments: 10,
                    isEmpty: entry.warMemorialOccupancy == 0,
                    showPercentageSymbol: false // Disable "%"
                )
                VStack(alignment: .leading, spacing: 4) { // Reduced spacing from 4 to 2
                    Text("War Memorial")
                        .font(.system(size: 11, weight: .bold))
                        .widgetAccentable()
                        .lineLimit(1) // Ensure single line
                    HStack(spacing: 0) {
                        Text("\(entry.warMemorialOccupancy)")
                            .font(.system(size: 13))
                            .widgetAccentable()
                            .layoutPriority(1) // Ensures this text gets priority
                        Text(" / \(entry.maxWarMemorialCapacity)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1) // Ensure single line
                    }
                }
            }

            // Divider with default appearance
            Divider()
                .padding(.vertical, 10) // Reduced vertical padding from 4 to 2

            // McComas Section
            HStack(spacing: 8) {
                CircularProgressView(
                    percentage: calculatePercentage(occupancy: entry.mcComasOccupancy, maxCapacity: entry.maxMcComasCapacity),
                    size: 40,
                    lineWidth: 6,
                    fontScale: 0.30,
                    widgetRenderingMode: widgetRenderingMode,
                    totalSegments: 10,
                    isEmpty: entry.mcComasOccupancy == 0,
                    showPercentageSymbol: false // Disable "%"
                )
                VStack(alignment: .leading, spacing: 4) { // Reduced spacing from 4 to 2
                    Text("McComas")
                        .font(.system(size: 11, weight: .bold))
                        .widgetAccentable()
                        .lineLimit(1) // Ensure single line
                    HStack(spacing: 0) {
                        Text("\(entry.mcComasOccupancy)")
                            .font(.system(size: 13))
                            .widgetAccentable()
                            .layoutPriority(1) // Ensures this text gets priority
                        Text(" / \(entry.maxMcComasCapacity)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1) // Ensure single line
                    }
                }
            }
        }
        .padding(.horizontal, 0) // Removed horizontal padding
        .padding(.vertical, 0)
        .containerBackground(Color(.systemBackground), for: .widget)
    }

    private func calculatePercentage(occupancy: Int, maxCapacity: Int) -> Double {
        guard maxCapacity > 0 else { return 0 }
        return (Double(occupancy) / Double(maxCapacity)) * 100
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: UnifiedGymTrackerEntry
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        HStack {
            Spacer()
            // War Memorial Section
            VStack(spacing: 4) {
                CircularProgressView(
                    percentage: calculatePercentage(occupancy: entry.warMemorialOccupancy, maxCapacity: entry.maxWarMemorialCapacity),
                    size: 70,
                    lineWidth: 8,
                    fontScale: 0.25,
                    widgetRenderingMode: widgetRenderingMode,
                    totalSegments: 20,
                    isEmpty: entry.warMemorialOccupancy == 0,
                    showPercentageSymbol: true
                )
                Text("War Memorial")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.top, 8)
                HStack(spacing: 0) {
                    Text("\(entry.warMemorialOccupancy)")
                        .font(.system(size: 14))
                    Text(" / \(entry.maxWarMemorialCapacity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Divider().frame(height: 90).padding(.horizontal)
            Spacer()
            // McComas Section
            VStack(spacing: 4) {
                CircularProgressView(
                    percentage: calculatePercentage(occupancy: entry.mcComasOccupancy, maxCapacity: entry.maxMcComasCapacity),
                    size: 70,
                    lineWidth: 8,
                    fontScale: 0.25,
                    widgetRenderingMode: widgetRenderingMode,
                    totalSegments: 20,
                    isEmpty: entry.mcComasOccupancy == 0,
                    showPercentageSymbol: true
                )
                Text("McComas")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.top, 8)
                HStack(spacing: 0) {
                    Text("\(entry.mcComasOccupancy)")
                        .font(.system(size: 14))
                    Text(" / \(entry.maxMcComasCapacity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .containerBackground(Color(.systemBackground), for: .widget)
    }

    private func calculatePercentage(occupancy: Int, maxCapacity: Int) -> Double {
        guard maxCapacity > 0 else { return 0 }
        return (Double(occupancy) / Double(maxCapacity)) * 100
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
            // Background segments
            ForEach(0..<totalSegments, id: \.self) { index in
                SegmentShape(
                    startAngle: segmentStartAngle(for: index),
                    endAngle: segmentStartAngle(for: index) + segmentAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(isEmpty ? Color.gray.opacity(0.2) : segmentColor(index).opacity(0.2))
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
                    maxMcComasCapacity: Constants.mcComasMaxCapacity,
                    maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            GymTrackerWidgetEntryView(
                entry: UnifiedGymTrackerEntry(
                    date: Date(),
                    mcComasOccupancy: 0, // Empty state
                    warMemorialOccupancy: 0, // Empty state
                    maxMcComasCapacity: Constants.mcComasMaxCapacity,
                    maxWarMemorialCapacity: Constants.warMemorialMaxCapacity
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

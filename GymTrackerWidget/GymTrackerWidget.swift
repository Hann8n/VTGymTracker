//GymTrackerWidget.swift
//
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            mcComasOccupancyData: "Loading...",
            warMemorialOccupancyData: "Loading...",
            mcComasOccupancy: 0,
            warMemorialOccupancy: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            mcComasOccupancyData: "300/600",
            warMemorialOccupancyData: "480/1200",
            mcComasOccupancy: 300,
            warMemorialOccupancy: 480
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!

        Task {
            let mcComasData = await GymService.shared.fetchGymOccupancy(for: Constants.mcComasFacilityId)
            let warMemorialData = await GymService.shared.fetchGymOccupancy(for: Constants.warMemorialFacilityId)

            let mcComasText = mcComasData != nil ? "\(mcComasData!.occupancy)/\(Constants.mcComasMaxCapacity)" : "N/A"
            let warMemorialText = warMemorialData != nil ? "\(warMemorialData!.occupancy)/\(Constants.warMemorialMaxCapacity)" : "N/A"

            let entry = SimpleEntry(
                date: currentDate,
                mcComasOccupancyData: mcComasText,
                warMemorialOccupancyData: warMemorialText,
                mcComasOccupancy: mcComasData?.occupancy ?? 0,
                warMemorialOccupancy: warMemorialData?.occupancy ?? 0
            )

            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let mcComasOccupancyData: String
    let warMemorialOccupancyData: String
    let mcComasOccupancy: Int
    let warMemorialOccupancy: Int
}

struct GymTrackerWidgetEntryView: View {
    var entry: Provider.Entry
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

struct SmallWidgetView: View {
    let entry: Provider.Entry
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                if entry.warMemorialOccupancyData == "Loading..." {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 6)
                            .opacity(0.3)
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    CircularProgressView(
                        percentage: (Double(entry.warMemorialOccupancy) / Double(Constants.warMemorialMaxCapacity)) * 100,
                        size: 40,
                        lineWidth: 6,
                        fontScale: 0.25, // Decreased from 0.3 to 0.25
                        widgetRenderingMode: widgetRenderingMode,
                        totalSegments: 10 // Set to 10 for small widget
                    )
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("War Memorial")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .widgetAccentable()

                    HStack(spacing: 0) {
                        Text("\(entry.warMemorialOccupancy)")
                            .font(.system(size: 14))
                            .widgetAccentable()
                        Text(" / \(Constants.warMemorialMaxCapacity)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().frame(maxWidth: 80)

            HStack(spacing: 8) {
                if entry.mcComasOccupancyData == "Loading..." {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 6)
                            .opacity(0.3)
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    CircularProgressView(
                        percentage: (Double(entry.mcComasOccupancy) / Double(Constants.mcComasMaxCapacity)) * 100,
                        size: 40,
                        lineWidth: 6,
                        fontScale: 0.25, // Decreased from 0.3 to 0.25
                        widgetRenderingMode: widgetRenderingMode,
                        totalSegments: 10 // Set to 10 for small widget
                    )
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("McComas")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .widgetAccentable()

                    HStack(spacing: 0) {
                        Text("\(entry.mcComasOccupancy)")
                            .font(.system(size: 14))
                            .widgetAccentable()
                        Text(" / \(Constants.mcComasMaxCapacity)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .widgetAccentable()
        .containerBackground(Color(.systemBackground), for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        HStack {
            Spacer()

            VStack(spacing: 4) {
                if entry.warMemorialOccupancyData == "Loading..." {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.3)
                            .foregroundColor(.secondary)
                            .frame(width: 70, height: 70)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .frame(width: 70, height: 70)
                    }
                } else {
                    CircularProgressView(
                        percentage: (Double(entry.warMemorialOccupancy) / Double(Constants.warMemorialMaxCapacity)) * 100,
                        size: 70,
                        lineWidth: 8,
                        fontScale: 0.25,
                        widgetRenderingMode: widgetRenderingMode,
                        totalSegments: 20 // Set to 20 for medium widget
                    )
                }

                Text("War Memorial")
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .widgetAccentable()
                    .padding(.top, 8)

                HStack(spacing: 0) {
                    Text("\(entry.warMemorialOccupancy)")
                        .font(.system(size: 14))
                        .widgetAccentable()
                    Text(" / \(Constants.warMemorialMaxCapacity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()

            Divider()
                .frame(height: 90)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 4) {
                if entry.mcComasOccupancyData == "Loading..." {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.3)
                            .foregroundColor(.secondary)
                            .frame(width: 70, height: 70)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .frame(width: 70, height: 70)
                    }
                } else {
                    CircularProgressView(
                        percentage: (Double(entry.mcComasOccupancy) / Double(Constants.mcComasMaxCapacity)) * 100,
                        size: 70,
                        lineWidth: 8,
                        fontScale: 0.25,
                        widgetRenderingMode: widgetRenderingMode,
                        totalSegments: 20 // Set to 20 for medium widget
                    )
                }

                Text("McComas")
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .widgetAccentable()
                    .padding(.top, 8)

                HStack(spacing: 0) {
                    Text("\(entry.mcComasOccupancy)")
                        .font(.system(size: 14))
                        .widgetAccentable()
                    Text(" / \(Constants.mcComasMaxCapacity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .widgetAccentable()
        .containerBackground(Color(.systemBackground), for: .widget)
    }
}

struct CircularProgressView: View {
    let percentage: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let fontScale: CGFloat
    let widgetRenderingMode: WidgetRenderingMode
    let totalSegments: Int           // Made configurable
    var segmentSpacing: Double = 2.0 // Adjusted spacing between segments
    let minimumBrightness: Double = 0.3   // Minimum opacity for partially filled segments

    private var segmentAngle: Double {
        (360.0 / Double(totalSegments)) - segmentSpacing
    }

    var body: some View {
        ZStack {
            // Background segments
            ForEach(0..<totalSegments, id: \.self) { index in
                let startAngle = segmentStartAngle(for: index)
                let endAngle = startAngle + segmentAngle

                SegmentShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(self.segmentColor(for: index).opacity(0.2))
                .frame(width: size, height: size)
            }

            // Foreground segments
            ForEach(0..<totalSegments, id: \.self) { index in
                let startAngle = segmentStartAngle(for: index)
                let endAngle = startAngle + segmentAngle

                SegmentShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(self.segmentColor(for: index))
                .opacity(self.opacityForSegment(index: index, adjustedPercentage: percentage / 100.0))
                .frame(width: size, height: size)
            }

            // Center text
            Text(String(format: "%.0f%%", percentage))
                .font(.system(size: size * fontScale, weight: .bold))
                .foregroundColor(widgetRenderingMode == .accented ? .accentColor : .primary)
        }
    }

    private func segmentStartAngle(for index: Int) -> Double {
        (Double(index) * (segmentAngle + segmentSpacing)) - 90
    }

    private func segmentColor(for index: Int) -> Color {
        if index < totalSegments / 2 {
            return Color.green
        } else if index < (totalSegments * 3) / 4 {
            return Color(red: 229/255, green: 117/255, blue: 31/255)
        } else {
            return Color(red: 134/255, green: 31/255, blue: 65/255)
        }
    }

    private func opacityForSegment(index: Int, adjustedPercentage: Double) -> Double {
        let segmentProgress = Double(index) / Double(totalSegments)
        let nextSegmentProgress = Double(index + 1) / Double(totalSegments)

        if adjustedPercentage >= nextSegmentProgress {
            // Fully filled segment
            return 1.0
        } else if adjustedPercentage > segmentProgress {
            // Partially filled segment with minimum brightness
            let segmentFraction = (adjustedPercentage - segmentProgress) / (nextSegmentProgress - segmentProgress)
            return max(segmentFraction, minimumBrightness)
        } else {
            // Not filled segment
            return 0.0
        }
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

struct GymTrackerWidget: Widget {
    let kind: String = "GymTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GymTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Gym Tracker Widget")
        .description("Shows gym occupancy for McComas and War Memorial Hall.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GymTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GymTrackerWidgetEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    mcComasOccupancyData: "200 / 600",
                    warMemorialOccupancyData: "680 / 1,200",
                    mcComasOccupancy: 200,
                    warMemorialOccupancy: 680
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            GymTrackerWidgetEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    mcComasOccupancyData: "200 / 600",
                    warMemorialOccupancyData: "680 / 1,200",
                    mcComasOccupancy: 200,
                    warMemorialOccupancy: 680
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

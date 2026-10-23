import WidgetKit
import SwiftUI

struct GymTrackerWidgetEntryView: View {
    var entry: UnifiedGymTrackerEntry
    /// The class schedule the app shares in the App Group; only the large size lists classes.
    var classes = ClassScheduleService.Schedule()
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
            case .systemMedium:
                MediumWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
            case .systemLarge:
                LargeWidgetView(entry: entry, classes: classes, widgetRenderingMode: widgetRenderingMode)
            default:
                EmptyView()
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Occupancy Row (widget layout; main app uses `FacilityOccupancyCard` + `SegmentedProgressBar`)
struct OccupancyRowView: View {
    let title: String
    let occupancy: Int?
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
        OccupancyMath.percent(occupancy: occupancy ?? 0, maxCapacity: maxCapacity)
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
                isEmpty: occupancy == nil,
                showPercentageSymbol: showPercentageInCircle
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: titleFont, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                // Same size for occupancy and max; keep occupancy primary, max secondary
                (Text("\(occupancy?.abbreviatedCount ?? "—")")
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

            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(height: 1)

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

            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(height: 1)

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
    let occupancy: Int?
    let maxCapacity: Int
    let totalSegments: Int
    let widgetRenderingMode: WidgetRenderingMode

    private var percentage: Double {
        OccupancyMath.percent(occupancy: occupancy ?? 0, maxCapacity: maxCapacity)
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
                isEmpty: occupancy == nil,
                showPercentageSymbol: true
            )
            .padding(.bottom, 5)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                (Text("\(occupancy?.abbreviatedCount ?? "—")")
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

// MARK: - Large Widget (the medium rings, then the next classes)
struct LargeWidgetView: View {
    let entry: UnifiedGymTrackerEntry
    let classes: ClassScheduleService.Schedule
    let widgetRenderingMode: WidgetRenderingMode

    var body: some View {
        let next = classes.nextDay(.all, after: entry.date)
        VStack(alignment: .leading, spacing: 0) {
            MediumWidgetView(entry: entry, widgetRenderingMode: widgetRenderingMode)
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 14)
            VStack(alignment: .leading, spacing: 8) {
                WidgetClassesHeader(subtitle: next.map { ClassRowText.dayTitle($0.day, now: entry.date) })
                if next != nil {
                    WidgetClassList(classes: Array(classes.upcoming(.all, after: entry.date).prefix(3)), now: entry.date)
                } else {
                    Text("No classes scheduled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Classes (shared with ClassesWidget)

/// "CLASSES" in the dashboard's section style, with the day on the right.
struct WidgetClassesHeader: View {
    let subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("CLASSES")
                .font(.caption.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.9)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Title first, then "10:30 AM · War Memorial" ("Now" in green while it runs), as on the dashboard.
struct WidgetClassList: View {
    let classes: [ScheduledClass]
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(classes) { scheduled in
                VStack(alignment: .leading, spacing: 1) {
                    Text(scheduled.gymClass.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    (WidgetClassTimeText(scheduled: scheduled, now: now, showsEnd: false).text + Text(" · \(scheduled.gymName)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// "10:30 AM" today, "Tomorrow 10:30 AM" or "Sun 10:30 AM" later, or "Now" (green on the Home Screen)
/// while the class runs.
struct WidgetClassTimeText: View {
    let scheduled: ScheduledClass
    let now: Date
    let showsEnd: Bool
    var tintsNow = true

    var text: Text {
        let gymClass = scheduled.gymClass
        guard gymClass.isUnderway(at: now) else {
            let time = gymClass.start.formatted(date: .omitted, time: .shortened)
            let calendar = Calendar.current
            if calendar.isDate(gymClass.start, inSameDayAs: now) { return Text(time) }
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(gymClass.start, inSameDayAs: tomorrow) {
                return Text("Tomorrow \(time)")
            }
            return Text("\(gymClass.start.formatted(.dateTime.weekday(.abbreviated))) \(time)")
        }
        let nowText = tintsNow ? Text("Now").fontWeight(.semibold).foregroundStyle(Color("CustomGreen")) : Text("Now").fontWeight(.semibold)
        return showsEnd ? nowText + Text(" · until \(gymClass.end.formatted(date: .omitted, time: .shortened))") : nowText
    }

    var body: some View { text }
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
    let isEmpty: Bool
    let showPercentageSymbol: Bool

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
                .foregroundColor(isEmpty ? Color.gray.opacity(0.20) : segmentColor(index).opacity(0.20))
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
            Text("\(OccupancyMath.wholePercent(fromPercent: percentage))\(showPercentageSymbol ? "%" : "")")
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
            GymTrackerWidgetEntryView(entry: entry, classes: ClassScheduleService().cached())
        }
        .configurationDisplayName("Gym Tracker")
        .description("Live occupancy for campus gyms, with the next classes at the large size.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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

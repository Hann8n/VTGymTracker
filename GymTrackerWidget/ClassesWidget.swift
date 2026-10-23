import WidgetKit
import SwiftUI

// MARK: - Timeline

struct ClassesEntry: TimelineEntry {
    let date: Date
    let schedule: ClassScheduleService.Schedule

    /// The rest of the next day with classes at both gyms, as the app's dashboard shows it.
    var nextDay: (day: Date, classes: [ScheduledClass])? { schedule.nextDay(.all, after: date) }
    var hasLoaded: Bool { schedule.fetchedAt != nil || !schedule.classes.isEmpty }
}

/// Reads the schedule the app keeps in the App Group, fetching it here only when it is stale. Entries
/// land on every class start and end over the next day, so "Now" and "next" turn over on time offline.
struct ClassesTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClassesEntry {
        ClassesEntry(date: Date(), schedule: .widgetSample(now: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassesEntry) -> Void) {
        let cached = ClassScheduleService().cached()
        let schedule = context.isPreview && cached.classes.isEmpty ? .widgetSample(now: Date()) : cached
        completion(ClassesEntry(date: Date(), schedule: schedule))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassesEntry>) -> Void) {
        Task {
            let service = ClassScheduleService()
            var schedule = service.cached()
            let isStale = schedule.fetchedAt.map { Date().timeIntervalSince($0) >= ClassScheduleService.refreshAge } ?? true
            if isStale { schedule = await service.refresh() }
            completion(Self.timeline(for: schedule, now: Date()))
        }
    }

    static func timeline(for schedule: ClassScheduleService.Schedule, now: Date) -> Timeline<ClassesEntry> {
        let horizon = now.addingTimeInterval(24 * 60 * 60)
        let changes = schedule.upcoming(.all, after: now)
            .flatMap { [$0.gymClass.start, $0.gymClass.end] }
            .filter { $0 > now && $0 < horizon }
        // Midnight too, so "Today" becomes the next day's label without waiting for a class to change.
        let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        let dates = [now] + Array(Set(changes + [midnight]).sorted().prefix(48))
        let refresh = min(now.addingTimeInterval(ClassScheduleService.refreshAge), dates.last ?? horizon)
        return Timeline(entries: dates.map { ClassesEntry(date: $0, schedule: schedule) }, policy: .after(refresh))
    }
}

extension ClassScheduleService.Schedule {
    /// Gallery preview before the app has loaded anything.
    static func widgetSample(now: Date) -> Self {
        let start = Calendar.current.nextDate(after: now, matching: DateComponents(minute: 30), matchingPolicy: .nextTime) ?? now
        func gymClass(_ id: String, _ title: String, _ room: String, _ offset: TimeInterval) -> GymClass {
            GymClass(id: id, title: title, room: room, start: start.addingTimeInterval(offset), end: start.addingTimeInterval(offset + 45 * 60))
        }
        return Self(classes: [
            TrackedFacility.warMemorial.rawValue: [gymClass("1", "Cycle", "Spin Studio 131", 0), gymClass("3", "Yoga", "Studio 117", 3600)],
            TrackedFacility.mcComas.rawValue: [gymClass("2", "Pilates", "Studio B", 1800), gymClass("4", "Cardio Dance", "Studio A", 5400)]
        ], fetchedAt: now)
    }
}

// MARK: - Views

struct ClassesWidgetEntryView: View {
    let entry: ClassesEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline: inline
            case .accessoryRectangular: rectangular
            case .systemSmall: small
            default: list(limit: family == .systemLarge ? 7 : 3)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            WidgetClassesHeader(subtitle: nil)
            Spacer(minLength: 0)
            if let next = entry.nextDay, let first = next.classes.first {
                Text(first.gymClass.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                WidgetClassTimeText(scheduled: first, now: entry.date, showsEnd: false)
                    .font(.subheadline)
                Text(first.gymName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(moreText(next))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                emptyText.font(.subheadline)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
    }

    /// The next classes whatever the day, like Calendar's Up Next; later days are named on their rows.
    private func list(limit: Int) -> some View {
        let upcoming = Array(entry.schedule.upcoming(.all, after: entry.date).prefix(limit))
        return VStack(alignment: .leading, spacing: 0) {
            WidgetClassesHeader(subtitle: entry.nextDay.map { ClassRowText.dayTitle($0.day, now: entry.date) })
                .padding(.bottom, 8)
            if !upcoming.isEmpty {
                WidgetClassList(classes: upcoming, now: entry.date)
                Spacer(minLength: 0)
            } else {
                emptyText.font(.subheadline)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
    }

    // MARK: Lock Screen

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let first = entry.nextDay?.classes.first {
                Text(first.gymClass.title)
                    .font(.headline)
                    .widgetAccentable()
                    .lineLimit(1)
                WidgetClassTimeText(scheduled: first, now: entry.date, showsEnd: false, tintsNow: false)
                    .lineLimit(1)
                Text(first.gymName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("Classes").font(.headline).widgetAccentable()
                emptyText
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var inline: some View {
        if let first = entry.nextDay?.classes.first {
            Text(first.gymClass.isUnderway(at: entry.date)
                 ? "\(first.gymClass.title) now"
                 : "\(first.gymClass.title) \(first.gymClass.start.formatted(date: .omitted, time: .shortened))")
        } else {
            Text("No classes scheduled")
        }
    }

    // MARK: Helpers

    private var emptyText: Text {
        entry.hasLoaded
            ? Text("No classes scheduled").foregroundStyle(.secondary)
            : Text("Open Gym Tracker to load classes").foregroundStyle(.secondary)
    }

    private func moreText(_ next: (day: Date, classes: [ScheduledClass])) -> String {
        let day = ClassRowText.dayTitle(next.day, now: entry.date)
        let more = next.classes.count - 1
        return more > 0 ? "\(more) more \(day == "Today" || day == "Tomorrow" ? day.lowercased() : "on \(day)")" : day
    }
}

// MARK: - Configuration

struct ClassesWidget: Widget {
    let kind = "ClassesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClassesTimelineProvider()) { entry in
            ClassesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Classes")
        .description("The next group fitness classes at War Memorial and McComas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemMedium) {
    ClassesWidget()
} timeline: {
    ClassesEntry(date: .now, schedule: .widgetSample(now: .now))
}

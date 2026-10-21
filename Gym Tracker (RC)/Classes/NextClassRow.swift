import SwiftUI

/// The gym card's one-line pointer to the class underway or up next; taps open the full schedule.
struct NextClassRow: View {
    let classes: [GymClass]
    let action: () -> Void

    var body: some View {
        TimelineView(.everyMinute) { context in
            if let gymClass = classes.first(where: { $0.end > context.date }) {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(gymClass.isUnderway(at: context.date) ? "NOW" : "NEXT")
                            .font(.caption.weight(.bold))
                            .fontWidth(.condensed)
                            .tracking(0.9)
                            .foregroundStyle(.secondary)
                        Text(gymClass.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(Self.timeText(gymClass, now: context.date))
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows the class schedule")
            }
        }
    }

    static func timeText(_ gymClass: GymClass, now: Date) -> String {
        let time = gymClass.start.formatted(date: .omitted, time: .shortened)
        if gymClass.isUnderway(at: now) { return "until " + gymClass.end.formatted(date: .omitted, time: .shortened) }
        if Calendar.current.isDate(gymClass.start, inSameDayAs: now) { return time }
        return gymClass.start.formatted(.dateTime.weekday(.abbreviated)) + " " + time
    }
}

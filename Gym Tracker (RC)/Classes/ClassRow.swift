import SwiftUI

/// One class, title first. The dashboard is a glance: start time and gym (or the room once a gym is
/// chosen). The schedule is for planning, as in Calendar's list: time range, then gym · room.
/// "Now" in green replaces the time while the class runs.
struct ClassRow: View {
    enum Style { case glance, detail }

    let scheduled: ScheduledClass
    let style: Style
    let showsGym: Bool
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(gymClass.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            Group {
                switch style {
                case .glance:
                    timeText + Text(" · ") + Text(showsGym ? scheduled.gymName : gymClass.room)
                case .detail:
                    timeText
                    Text(showsGym ? "\(scheduled.gymName) · \(gymClass.room)" : gymClass.room)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ClassRowText.accessibilityLabel(scheduled, now: now))
    }

    private var gymClass: GymClass { scheduled.gymClass }

    /// Glance: "10:30 AM". Detail: "10:30–11:30 AM". While running: "Now", plus "· until 4:15 PM" in detail.
    private var timeText: Text {
        guard gymClass.isUnderway(at: now) else {
            return Text(style == .glance
                        ? gymClass.start.formatted(date: .omitted, time: .shortened)
                        : EventCard.timeRangeText(start: gymClass.start, end: gymClass.end))
        }
        let nowText = Text("Now").fontWeight(.semibold).foregroundStyle(Color("CustomGreen"))
        guard style == .detail else { return nowText }
        return nowText + Text(" · until \(gymClass.end.formatted(date: .omitted, time: .shortened))")
    }
}

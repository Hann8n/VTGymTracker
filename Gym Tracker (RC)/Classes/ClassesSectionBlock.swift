import SwiftUI

/// Dashboard section with the next classes in the chosen gyms; the full schedule opens in a sheet.
struct ClassesSectionBlock: View {
    @ObservedObject var classSchedule: ClassScheduleViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let motionPolicy: MotionPolicy
    var isSeparatePane = false
    let onShowSchedule: () -> Void

    @AppStorage(ClassGymFilter.storageKey) private var filter: ClassGymFilter = .all

    /// Enough to see what's coming without pushing events far down the feed.
    static let previewLimit = 4

    var body: some View {
        // Classes are extra to occupancy: with nothing cached and nothing loading, the section stays out of the way.
        // ContentView's `showsClasses` mirrors this so the following section keeps its spacing.
        if classSchedule.hasAnyClasses || classSchedule.isRefreshing {
            TimelineView(.everyMinute) { context in
                let next = classSchedule.schedule.nextDay(filter, after: context.date)

                VStack(alignment: .leading, spacing: 8) {
                    DashboardSectionHeader(title: "Classes", subtitle: next.map { ClassRowText.dayTitle($0.day, now: context.date) })
                        .padding(.horizontal, DashboardLayout.horizontalGutter)

                    ClassGymPicker(selection: $filter)
                        .padding(.horizontal, DashboardLayout.horizontalGutter)
                        .padding(.bottom, 4)

                    card(next: next, now: context.date)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .dashboardCardChrome(networkMonitor: networkMonitor)
                        .animation(motionPolicy.updateAnimation, value: filter)
                }
                .padding(.top, isSeparatePane ? 0 : DashboardLayout.sectionSpacingBeforeHeader)
            }
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func card(next: (day: Date, classes: [ScheduledClass])?, now: Date) -> some View {
        if let next {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(next.classes.prefix(Self.previewLimit)) { scheduled in
                    row(scheduled, now: now)
                    FullBleedDivider()
                }
                scheduleButton(moreCount: next.classes.count - Self.previewLimit)
            }
        } else if classSchedule.isRefreshing {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 96)
                .accessibilityLabel("Loading classes")
        } else {
            VStack(spacing: 6) {
                Text("NO UPCOMING CLASSES")
                    .font(.caption.weight(.bold))
                    .fontWidth(.condensed)
                    .tracking(0.9)
                    .foregroundStyle(.secondary)
                Text("Classes at \(filter == .all ? "either gym" : filter.title) will show up here.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DashboardLayout.cardVerticalPadding)
            .padding(.horizontal, DashboardLayout.horizontalGutter)
            .accessibilityElement(children: .combine)
        }
    }

    private func row(_ scheduled: ScheduledClass, now: Date) -> some View {
        Button(action: onShowSchedule) {
            ClassRow(scheduled: scheduled, style: .glance, showsGym: filter == .all, now: now)
                .padding(.horizontal, DashboardLayout.horizontalGutter)
                .padding(.vertical, 10)
                .frame(minHeight: 52, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(EventRowButtonStyle())
        .accessibilityHint("Shows the class schedule")
        .accessibilityAddTraits(.isButton)
    }

    private func scheduleButton(moreCount: Int) -> some View {
        Button(action: onShowSchedule) {
            HStack(spacing: 8) {
                Text("Full Schedule")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if moreCount > 0 {
                    Text("\(moreCount) more")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DashboardLayout.horizontalGutter)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(EventRowButtonStyle())
    }
}

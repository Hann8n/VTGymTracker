import Foundation
import WidgetKit

/// Shows the cached class schedule immediately and refreshes it from EMS when it is stale.
@MainActor
final class ClassScheduleViewModel: ObservableObject {
    @Published private(set) var schedule: ClassScheduleService.Schedule
    @Published private(set) var isRefreshing = false

    private let service: ClassScheduleService

    init(service: ClassScheduleService = ClassScheduleService()) {
        self.service = service
        schedule = service.cached()
    }

    func refreshIfStale(now: Date = Date()) async {
        if let fetchedAt = schedule.fetchedAt, now.timeIntervalSince(fetchedAt) < ClassScheduleService.refreshAge { return }
        await refresh(now: now)
    }

    /// Fetches regardless of age, for pull to refresh.
    func refresh(now: Date = Date()) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let previous = schedule
        schedule = await service.refresh(now: now)
        isRefreshing = false
        if schedule != previous { WidgetCenter.shared.reloadAllTimelines() }
    }

    var hasAnyClasses: Bool {
        schedule.classes.values.contains { !$0.isEmpty }
    }
}

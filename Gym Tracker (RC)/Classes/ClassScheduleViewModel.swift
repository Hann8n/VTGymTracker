import Foundation

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
        guard !isRefreshing else { return }
        if let fetchedAt = schedule.fetchedAt, now.timeIntervalSince(fetchedAt) < ClassScheduleService.refreshAge { return }
        isRefreshing = true
        schedule = await service.refresh(now: now)
        isRefreshing = false
    }

    func classes(for facility: TrackedFacility, now: Date = Date()) -> [GymClass] {
        schedule.classes(for: facility, after: now)
    }
}

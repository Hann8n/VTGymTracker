import Foundation

/// A class together with the gym it meets in, for lists that mix both gyms.
struct ScheduledClass: Hashable, Identifiable, Sendable {
    let facility: TrackedFacility
    let gymClass: GymClass

    var id: String { facility.rawValue + ":" + gymClass.id }

    /// "War Memorial" rather than "War Memorial Hall", to fit beside the room.
    var gymName: String {
        switch facility {
        case .warMemorial: return "War Memorial"
        case .mcComas: return "McComas"
        default: return facility.name
        }
    }

    /// Classes starting within this window read "In N min".
    static let startingSoonWindow: TimeInterval = 60 * 60

    enum Status: Equatable { case underway, startingIn(minutes: Int) }

    /// Rec Sports opens sign-up an hour before each class; after it starts, it's a walk-in.
    func isSignUpOpen(at now: Date) -> Bool {
        let start = gymClass.start
        return start.addingTimeInterval(-Constants.classSignUpWindow) <= now && now < start
    }

    func status(at now: Date) -> Status? {
        if gymClass.isUnderway(at: now) { return .underway }
        let seconds = gymClass.start.timeIntervalSince(now)
        guard seconds > 0, seconds <= Self.startingSoonWindow else { return nil }
        return .startingIn(minutes: max(1, Int((seconds / 60).rounded(.up))))
    }
}

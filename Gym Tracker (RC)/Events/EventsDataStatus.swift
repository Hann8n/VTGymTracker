import Foundation

enum EventsDataStatus: String, CaseIterable, Sendable {
    case live, cached, unavailable
}

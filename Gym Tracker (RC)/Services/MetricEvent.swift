import Foundation

enum MetricEvent: String, Sendable {
    case appSession = "app_session"
    case eventOpen = "event_open"
    case passportOpen = "passport_open"
    case settingsOpen = "settings_open"
    case classScheduleOpen = "class_schedule_open"
    case classSignUpTap = "class_signup_tap"
    case siriCrowds = "siri_crowds"
    case siriEvents = "siri_events"
    case siriEventDetails = "siri_event_details"
    case adImpression = "ad_impression"
    case adTap = "ad_tap"
}

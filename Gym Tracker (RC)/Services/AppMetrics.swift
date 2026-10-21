import Foundation

/// Best-effort first-party events. No SDK, identity profiles, campus IDs, or user content.
actor AppMetrics {
    static let shared = AppMetrics()
    static let enabledKey = "usageAnalyticsEnabled"
    static let installationKey = "analyticsInstallationID"
    static var productionBuild: Bool {
        #if os(iOS) && !DEBUG && !targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private let defaults: UserDefaults
    private let enabledForBuild: Bool
    private let send: @Sendable (URLRequest) async -> Bool
    private var sessionID = UUID().uuidString
    private var startedForegroundSession = false
    private var backgroundAt: Date?
    private var impressions: Set<String> = []

    init(defaults: UserDefaults = .standard, enabledForBuild: Bool = AppMetrics.productionBuild,
         send: @escaping @Sendable (URLRequest) async -> Bool = { request in await AppMetrics.deliver(request) }) {
        self.defaults = defaults
        self.enabledForBuild = enabledForBuild
        self.send = send
    }

    func setEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Self.enabledKey)
        if !enabled {
            defaults.removeObject(forKey: Self.installationKey)
            resetSession()
        }
    }

    /// A foreground session starts on launch or after at least 30 minutes in background.
    func activate(at now: Date = Date()) async {
        if let backgroundAt, now.timeIntervalSince(backgroundAt) >= 30 * 60 { resetSession() }
        backgroundAt = nil
        guard isEnabled, !startedForegroundSession else { return }
        startedForegroundSession = true
        await track(.appSession)
    }

    func enterBackground(at date: Date = Date()) { backgroundAt = date }

    func track(_ event: MetricEvent, properties: [String: String] = [:]) async {
        guard isEnabled else { return }
        if event == .adImpression {
            guard let adID = properties["ad_id"], !adID.hasPrefix("dev_") else { return }
            let key = adID + ":" + (properties["creative_version"] ?? "")
            guard impressions.insert(key).inserted else { return }
        }
        if event == .adTap, properties["ad_id"]?.hasPrefix("dev_") == true { return }
        let installID: String
        if let saved = defaults.string(forKey: Self.installationKey), UUID(uuidString: saved) != nil {
            installID = saved
        } else {
            installID = UUID().uuidString
            defaults.set(installID, forKey: Self.installationKey)
        }
        var values = properties
        values["session_id"] = sessionID
        values["app_version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        values["build"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        values["os_version"] = ProcessInfo.processInfo.operatingSystemVersionString
        // Lets reports split iOS from Android, which posts to the same endpoint.
        values["platform"] = "ios"
        guard let url = URL(string: Constants.metricsURLString),
              let body = try? JSONSerialization.data(withJSONObject: [
                "event_id": UUID().uuidString, "event": event.rawValue, "distinct_id": installID, "properties": values
              ]) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 2)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        // Intentionally no disk queue/retries: analytics never blocks core features or replays opted-out activity.
        _ = await send(request)
    }

    private var isEnabled: Bool {
        guard enabledForBuild else { return false }
        let enabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        // Settings.app writes this same preference while our app may be suspended.
        // Apply opt-out before any event, including foreground resumes and Siri actions.
        if !enabled {
            defaults.removeObject(forKey: Self.installationKey)
            resetSession()
        }
        return enabled
    }

    private func resetSession() {
        sessionID = UUID().uuidString
        impressions.removeAll()
        startedForegroundSession = false
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil
        config.urlCache = nil
        config.timeoutIntervalForRequest = 2
        config.timeoutIntervalForResource = 2
        return URLSession(configuration: config)
    }()

    private static func deliver(_ request: URLRequest) async -> Bool {
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 204
        } catch { return false }
    }
}

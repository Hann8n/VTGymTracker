//
//  AdService.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import Foundation

struct AdService {

    /// Distinguishes “couldn’t reach the server” from “server says there is no active ad”.
    enum ActiveAdOutcome: Equatable {
        /// Network error, non-2xx, or decode failure — safe to keep showing a previously loaded ad.
        case unavailable
        /// Fetch succeeded but the payload is not currently active.
        case inactive
        case active(AdConfig)
    }
    // Cache is written on successful fetch; callers may keep the last preloaded UI when
    // a refresh returns `.unavailable` (network / decode failure) so resume-after-freeze
    // does not flash an empty sponsor row.
    private static let adCacheKey = "cached_ad_config_v4"
    private static let adCacheSavedAtKey = "cached_ad_config_saved_at_v4"

    private let session: URLSession
    private let userDefaults: UserDefaults

    init(session: URLSession = AdService.makeSession(), userDefaults: UserDefaults = .standard) {
        self.session = session
        self.userDefaults = userDefaults
    }

    func fetchActiveAdOutcome() async -> ActiveAdOutcome {
        guard let remoteAd = await fetchRemoteAd() else {
            return .unavailable
        }
        cacheAd(remoteAd)
        return remoteAd.isCurrentlyActive ? .active(remoteAd) : .inactive
    }

    func fetchActiveAd() async -> AdConfig? {
        switch await fetchActiveAdOutcome() {
        case .active(let ad):
            return ad
        case .unavailable, .inactive:
            return nil
        }
    }

    func lastCacheDate() -> Date? {
        userDefaults.object(forKey: Self.adCacheSavedAtKey) as? Date
    }

    private func fetchRemoteAd() async -> AdConfig? {
        guard let requestURL = URL(string: Constants.adConfigURLString) else {
            return nil
        }

        do {
            let (data, response) = try await session.data(from: requestURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let decoder = JSONDecoder()
            return try decoder.decode(AdConfig.self, from: data)
        } catch {
            return nil
        }
    }

    /// Returns the last successfully fetched ad from UserDefaults. Currently unused —
    /// see cache keys above. Call this if adding offline fallback.
    private func cachedAd() -> AdConfig? {
        guard let cachedData = userDefaults.data(forKey: Self.adCacheKey) else {
            return nil
        }

        return try? JSONDecoder().decode(AdConfig.self, from: cachedData)
    }

    private func cacheAd(_ ad: AdConfig) {
        guard let encoded = try? JSONEncoder().encode(ad) else {
            return
        }

        userDefaults.set(encoded, forKey: Self.adCacheKey)
        userDefaults.set(Date(), forKey: Self.adCacheSavedAtKey)
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = Constants.adFetchTimeoutSeconds
        configuration.timeoutIntervalForResource = Constants.adFetchTimeoutSeconds
        return URLSession(configuration: configuration)
    }
}

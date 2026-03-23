//
//  AnalyticsService.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import Foundation
import PostHog

final class AnalyticsService {
    static let shared = AnalyticsService()

    let sessionID = UUID().uuidString
    private var isConfigured = false

    private init() {}

    func configureIfNeeded() {
        guard !isConfigured else { return }

        let config = PostHogConfig(apiKey: Constants.postHogAPIKey, host: Constants.postHogHost)
        PostHogSDK.shared.setup(config)
        isConfigured = true
    }

    func trackAdImpression(ad: AdConfig) {
        PostHogSDK.shared.capture(
            "ad_impression",
            properties: [
                "ad_id": ad.id,
                "sponsor": ad.sponsor,
                "placement": ad.placement,
                "destination_host": ad.destinationHost,
                "session_id": sessionID,
                "creative_version": ad.creativeVersion
            ]
        )
    }

    func trackAdTap(ad: AdConfig) {
        PostHogSDK.shared.capture(
            "ad_tap",
            properties: [
                "ad_id": ad.id,
                "sponsor": ad.sponsor,
                "placement": ad.placement,
                "destination_host": ad.destinationHost,
                "session_id": sessionID,
                "creative_version": ad.creativeVersion
            ]
        )
    }
}

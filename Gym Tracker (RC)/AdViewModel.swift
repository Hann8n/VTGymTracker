//
//  AdViewModel.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import Foundation

@MainActor
final class AdViewModel: ObservableObject {
    @Published private(set) var currentAd: AdConfig?

    private var impressionTracker = Set<String>()
    private let adService: AdService

    init(adService: AdService = AdService()) {
        self.adService = adService
    }

    /// - Parameter previewTier: When "text", "banner", or "feature", uses a local dev config instead of fetching. Pass "gist" or nil for production. Ignored in Release builds.
    func loadAd(previewTier: String? = nil) async {
        #if DEBUG
        if let tier = previewTier?.lowercased(), tier != "gist", let dev = AdConfig.devConfig(tier: tier) {
            currentAd = dev
            return
        }
        #endif
        currentAd = await adService.fetchActiveAd()
    }

    func trackImpressionIfNeeded(for ad: AdConfig) {
        let impressionKey = "\(ad.id)|\(AnalyticsService.shared.sessionID)|\(ad.placement)"
        guard !impressionTracker.contains(impressionKey) else {
            return
        }

        impressionTracker.insert(impressionKey)
        AnalyticsService.shared.trackAdImpression(ad: ad)
    }

    func trackTap(for ad: AdConfig) {
        AnalyticsService.shared.trackAdTap(ad: ad)
    }
}

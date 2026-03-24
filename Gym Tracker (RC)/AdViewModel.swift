//
//  AdViewModel.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import Foundation
import UIKit

@MainActor
final class AdViewModel: ObservableObject {
    struct LoadedAd: Equatable {
        let config: AdConfig
        let heroImage: UIImage?
        let logoImage: UIImage?

        static func == (lhs: LoadedAd, rhs: LoadedAd) -> Bool {
            lhs.config == rhs.config &&
            lhs.heroImage?.pngData() == rhs.heroImage?.pngData() &&
            lhs.logoImage?.pngData() == rhs.logoImage?.pngData()
        }
    }

    @Published private(set) var loadedAd: LoadedAd?

    private var impressionTracker = Set<String>()
    private let adService: AdService

    init(adService: AdService = AdService()) {
        self.adService = adService
    }

    /// - Parameter previewTier: In DEBUG, when "text", "banner", or "feature", uses a local dev config instead of fetching from `Constants.adConfigURLString`. Any other value (or nil in Release) loads from the production API. Ignored in Release builds.
    func loadAd(previewTier: String? = nil) async {
        #if DEBUG
        if let tier = previewTier?.lowercased(),
           let dev = AdConfig.devConfig(tier: tier) {
            loadedAd = await preload(ad: dev)
            return
        }
        #endif

        // Drop mock preview immediately so we never show dev content while waiting on the server,
        // and so `.unavailable` cannot leave a dev ad on screen after switching to LIVE.
        if loadedAd?.config.isDevelopmentPreview == true {
            loadedAd = nil
        }

        switch await adService.fetchActiveAdOutcome() {
        case .unavailable:
            // Keep showing the last good network ad after wake-from-freeze or transient network loss.
            break
        case .inactive:
            loadedAd = nil
        case .active(let ad):
            if let current = loadedAd, current.config == ad {
                return
            }
            loadedAd = await preload(ad: ad)
        }
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

    private func preload(ad: AdConfig) async -> LoadedAd {
        if ad.usesImageLayout, let heroURL = ad.imageURL {
            async let heroTask = Self.downloadUIImage(from: heroURL)
            async let logoTask: UIImage? = {
                guard let logoURL = ad.logoURL else { return nil }
                return await Self.downloadUIImage(from: logoURL)
            }()

            let (heroImage, logoImage) = await (heroTask, logoTask)
            return LoadedAd(config: ad, heroImage: heroImage, logoImage: logoImage)
        }

        if let logoURL = ad.logoURL {
            let logoImage = await Self.downloadUIImage(from: logoURL)
            return LoadedAd(config: ad, heroImage: nil, logoImage: logoImage)
        }

        return LoadedAd(config: ad, heroImage: nil, logoImage: nil)
    }

    nonisolated private static func downloadUIImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try Task.checkCancellation()
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

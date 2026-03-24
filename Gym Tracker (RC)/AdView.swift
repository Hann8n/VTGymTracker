//
//  AdView.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import SwiftUI
import UIKit

struct AdView: View {
    let ad: AdConfig
    let heroImage: UIImage?
    @ObservedObject var networkMonitor: NetworkMonitor
    let onImpression: () -> Void
    let onTap: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private var imageHeight: CGFloat {
        switch ad.tier {
        case "banner": return 140
        case "feature": return 220
        case "text": return 0
        default: return 140
        }
    }

    private func openAd() {
        onTap()
        openURL(ad.destinationURL)
    }

    var body: some View {
        Group {
            if ad.usesImageLayout, let hero = heroImage {
                imageTierView(hero: hero)
            } else {
                textTierView
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .athleticFrostedCardChrome(networkMonitor: networkMonitor)
        .onAppear(perform: onImpression)
    }

    // MARK: - Text tier (no image)

    private var textTierView: some View {
        VStack(alignment: .leading, spacing: 12) {
            copyContent

            ctaButton
        }
        .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
        .padding(.vertical, AthleticDashboardLayout.cardVerticalPadding)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Banner / Feature tier (image on top, copy below)

    private func imageTierView(hero: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(uiImage: hero)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipped()

            AthleticFullBleedDivider()

            VStack(alignment: .leading, spacing: 12) {
                copyContent

                ctaButton
            }
            .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
            .padding(.top, 12)
            .padding(.bottom, AthleticDashboardLayout.cardVerticalPadding)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    // MARK: - Shared components

    private var copyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(ad.headline)
                .font(.title3.weight(.bold))
                .fontWidth(.condensed)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let subline = ad.subline, !subline.isEmpty {
                Text(subline)
                    .font(.subheadline.weight(.medium))
                    .fontWidth(.condensed)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 6)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private var ctaButton: some View {
        let maroon = Color("CustomMaroon")
        let fillOpacity = colorScheme == .dark ? 0.18 : 0.072

        return Button(action: openAd) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: 6) {
                    Text(ad.cta)
                        .font(.subheadline.weight(.semibold))
                        .fontWidth(.condensed)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .imageScale(.small)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(maroon)
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(maroon.opacity(fillOpacity))
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

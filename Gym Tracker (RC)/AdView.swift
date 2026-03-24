//
//  AdView.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import SwiftUI

struct AdView: View {
    let ad: AdConfig
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
            if ad.usesImageLayout {
                imageTierView
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
            copyContentWithLogo

            ctaButton
        }
        .padding(.horizontal, AthleticDashboardLayout.horizontalGutter)
        .padding(.vertical, AthleticDashboardLayout.cardVerticalPadding)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Banner / Feature tier (image on top, copy below)

    private var imageTierView: some View {
        VStack(alignment: .leading, spacing: 0) {
            adImage(height: imageHeight)

            AthleticFullBleedDivider()

            VStack(alignment: .leading, spacing: 12) {
                copyContentWithLogo

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

    private var copyContentWithLogo: some View {
        VStack(alignment: .leading, spacing: 0) {
            sponsorLine

            Text(ad.headline)
                .font(.title3.weight(.bold))
                .fontWidth(.condensed)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

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

    private var sponsorLine: some View {
        HStack(alignment: .center, spacing: 10) {
            if let logoURL = ad.logoURL {
                logoImage(url: logoURL, size: 32)
            }
            Text(ad.sponsor.uppercased())
                .font(.subheadline.weight(.semibold))
                .fontWidth(.condensed)
                .tracking(0.65)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func logoImage(url: URL, size: CGFloat = 44) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure, .empty:
                Color(.tertiarySystemFill)
            @unknown default:
                Color(.tertiarySystemFill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }

    @ViewBuilder
    private func adImage(height: CGFloat) -> some View {
        AsyncImage(url: ad.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            case .failure, .empty:
                Color(.tertiarySystemFill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: height)
            @unknown default:
                Color(.tertiarySystemFill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: height)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
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
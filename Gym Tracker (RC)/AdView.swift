//
//  AdView.swift
//  Gym Tracker
//
//  Created by Jack Hannon on 3/22/26.
//

import SwiftUI

struct AdView: View {
    let ad: AdConfig
    let onImpression: () -> Void
    let onTap: () -> Void

    @Environment(\.openURL) private var openURL

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
        .onAppear(perform: onImpression)
    }

    // MARK: - Text tier (no image)

    private var textTierView: some View {
        VStack(alignment: .leading, spacing: 12) {
            copyContentWithLogo

            ctaButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Banner / Feature tier (image on top, copy below)

    private var imageTierView: some View {
        VStack(alignment: .leading, spacing: 0) {
            adImage(height: imageHeight)

            VStack(alignment: .leading, spacing: 12) {
                copyContentWithLogo

                ctaButton
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared components

    private var copyContentWithLogo: some View {
        VStack(alignment: .leading, spacing: 10) {
            sponsorLine

            Text(ad.headline)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            if let subline = ad.subline, !subline.isEmpty {
                Text(subline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sponsorLine: some View {
        HStack(spacing: 8) {
            if let logoURL = ad.logoURL {
                logoImage(url: logoURL, size: 24)
            }
            Text(ad.sponsor)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    @ViewBuilder
    private func adImage(height: CGFloat) -> some View {
        AsyncImage(url: ad.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            case .failure, .empty:
                Color(.tertiarySystemFill)
                    .frame(height: height)
            @unknown default:
                Color(.tertiarySystemFill)
                    .frame(height: height)
            }
        }
    }

    private var ctaButton: some View {
        Button(action: openAd) {
            HStack(spacing: 6) {
                Text(ad.cta)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color("CustomOrange"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color("CustomOrange").opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
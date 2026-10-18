import SwiftUI
import UIKit

struct DashboardSectionHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var subtitle: String? = nil
    var leadingLogo: UIImage? = nil
    @ScaledMetric(relativeTo: .subheadline) private var logoSize: CGFloat = 20

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                titleLabel.fixedSize()
                Spacer(minLength: 8)
                subtitleLabel.fixedSize()
            }

            VStack(alignment: .leading, spacing: 6) {
                titleLabel
                subtitleLabel
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private var titleLabel: some View {
        HStack(spacing: 10) {
            if let leadingLogo, !dynamicTypeSize.isAccessibilitySize {
                Image(uiImage: leadingLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .accessibilityHidden(true)
            }
            Text(title.uppercased())
                .font(.subheadline.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.9)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: logoSize)
    }

    @ViewBuilder private var subtitleLabel: some View {
        if let subtitle, !subtitle.isEmpty {
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

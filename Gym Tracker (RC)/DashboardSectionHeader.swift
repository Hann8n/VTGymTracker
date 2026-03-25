import SwiftUI
import UIKit

struct DashboardSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var leadingLogo: UIImage? = nil

    var body: some View {
        HStack(alignment: leadingLogo == nil ? .firstTextBaseline : .center, spacing: 10) {
            if let leadingLogo {
                Image(uiImage: leadingLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            }

            Text(title.uppercased())
                .font(.subheadline.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.9)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .fontWidth(.condensed)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .textCase(nil)
    }
}

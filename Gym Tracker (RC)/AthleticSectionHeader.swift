import SwiftUI

struct AthleticSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title.uppercased())
                .font(.subheadline.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.9)
                .foregroundStyle(.primary)
                .lineLimit(1)

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

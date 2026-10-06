import SwiftUI

/// Small uppercase condensed pill used for event status ("Live", "In 20 min") and price.
/// Tints reuse the brand occupancy palette at the same low-opacity fill as `SegmentedProgressBar`.
struct EventTag: View {
    enum Style {
        case live
        case soon
        case neutral
    }

    let text: String
    let style: Style

    var body: some View {
        HStack(spacing: 4) {
            if style == .live {
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
            }

            Text(text.uppercased())
                .font(.caption2.weight(.bold))
                .fontWidth(.condensed)
                .tracking(0.6)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .fixedSize()
    }

    private var tint: Color {
        switch style {
        case .live:
            return Color("CustomGreen")
        case .soon:
            return Color("CustomOrange")
        case .neutral:
            return Color.secondary
        }
    }
}

#Preview {
    HStack {
        EventTag(text: "Live", style: .live)
        EventTag(text: "In 20 min", style: .soon)
        EventTag(text: "Free", style: .neutral)
    }
    .padding()
}

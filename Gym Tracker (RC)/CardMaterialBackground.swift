import SwiftUI

// MARK: - Neutral frosted card surface

/// Blur + subtle monochrome wash (not brand color) for depth without competing with content or field art.
struct CardMaterialBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            // Near black-and-white diagonal: soft highlight → clear → soft shadow.
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08), location: 0),
                    .init(color: Color.clear, location: 0.45),
                    .init(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.025), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)
        }
    }
}

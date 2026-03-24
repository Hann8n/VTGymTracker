import SwiftUI

// MARK: - Field board atmosphere (VT-tinted depth + subtle grain)

struct AthleticFieldBoardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground)

            // Diagonal energy wash (muted maroon / orange)
            LinearGradient(
                stops: [
                    .init(color: Color("CustomMaroon").opacity(colorScheme == .dark ? 0.09 : 0.045), location: 0),
                    .init(color: Color.clear, location: 0.45),
                    .init(color: Color("CustomOrange").opacity(colorScheme == .dark ? 0.1 : 0.05), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft maroon glow — lower leading
            RadialGradient(
                colors: [
                    Color("CustomMaroon").opacity(colorScheme == .dark ? 0.14 : 0.065),
                    Color.clear
                ],
                center: UnitPoint(x: 0.12, y: 0.88),
                startRadius: 40,
                endRadius: 420
            )

            // Soft orange glow — upper trailing
            RadialGradient(
                colors: [
                    Color("CustomOrange").opacity(colorScheme == .dark ? 0.14 : 0.07),
                    Color.clear
                ],
                center: UnitPoint(x: 0.92, y: 0.08),
                startRadius: 20,
                endRadius: 340
            )

            // Lift from flat base
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(colorScheme == .dark ? 0.55 : 0.35),
                    Color(.secondarySystemBackground).opacity(colorScheme == .dark ? 0.25 : 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)

            AthleticFilmGrainOverlay()
                .blendMode(colorScheme == .dark ? .overlay : .multiply)
                .opacity(colorScheme == .dark ? 0.35 : 0.22)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Lightweight grain (deterministic, no random repaint churn)

private struct AthleticFilmGrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 5
            var x: CGFloat = 0
            while x < size.width + step {
                var y: CGFloat = 0
                while y < size.height + step {
                    let sx = sin(x * 0.09 + y * 0.05)
                    let cy = cos(x * 0.04 - y * 0.08)
                    let n = (sx * cy + 1) / 2
                    if n > 0.88 {
                        let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                        context.fill(Path(rect), with: .color(.primary.opacity(0.06)))
                    }
                    y += step
                }
                x += step
            }
        }
        .allowsHitTesting(false)
    }
}

import SwiftUI

// MARK: - Field board atmosphere (VT-tinted depth + subtle grain)

/// Dark-mode field board backdrop. Use plain `systemBackground` in light mode from the parent (see `AthleticDashboardContainer`).
struct AthleticFieldBoardBackground: View {
    /// VT atmosphere is drawn only in this top fraction of the screen and soft-fades out.
    private var topAtmosphereHeightFraction: CGFloat { 0.38 }

    private var maroonWashOpacity: Double { 0.13 }
    private var orangeWashOpacity: Double { 0.11 }
    private var orangeGlowOpacity: Double { 0.12 }

    var body: some View {
        ZStack {
            ZStack {
                Color(.systemBackground)
                Color("CustomMaroon").opacity(0.06)
            }

            GeometryReader { geo in
                let bandHeight = geo.size.height * topAtmosphereHeightFraction
                ZStack(alignment: .top) {
                    ZStack {
                        // Stadium edge — soft maroon along the top (scoreboard / end-zone cue)
                        LinearGradient(
                            stops: [
                                .init(color: Color("CustomMaroon").opacity(maroonWashOpacity * 1.15), location: 0),
                                .init(color: Color.clear, location: 0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Top-only maroon wash (no side bias)
                        LinearGradient(
                            stops: [
                                .init(color: Color("CustomMaroon").opacity(maroonWashOpacity), location: 0),
                                .init(color: Color.clear, location: 0.52)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Warm atmospheric orange wash, centered near the top.
                        LinearGradient(
                            stops: [
                                .init(color: Color("CustomOrange").opacity(orangeWashOpacity), location: 0.04),
                                .init(color: Color.clear, location: 0.62)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Soft top-center orange bloom for extra atmosphere without side bias.
                        RadialGradient(
                            colors: [
                                Color("CustomOrange").opacity(orangeGlowOpacity),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.04),
                            startRadius: 12,
                            endRadius: 260
                        )

                        // Faint “turf” hint — CustomGreen only in background, very low opacity
                        LinearGradient(
                            stops: [
                                .init(color: Color.clear, location: 0.55),
                                .init(color: Color("CustomGreen").opacity(0.05), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Lift from flat base
                        LinearGradient(
                            colors: [
                                Color(.systemBackground).opacity(0.55),
                                Color(.secondarySystemBackground).opacity(0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blendMode(.softLight)
                    }
                    .frame(width: geo.size.width, height: bandHeight)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: 0.58),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    AthleticFilmGrainOverlay()
                        .blendMode(.overlay)
                        .opacity(0.35)
                }
            }
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

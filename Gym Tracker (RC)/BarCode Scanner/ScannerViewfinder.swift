import SwiftUI

struct ScannerViewfinder: View {
    var body: some View {
        GeometryReader { geometry in
            let viewport = CampusIDScanLayout.viewport(in: geometry.size)
            // Extend behind translucent system bars while keeping the clear window
            // aligned with the displayed ID in the upper safe camera area.
            let backdrop = CGRect(
                x: -geometry.safeAreaInsets.leading,
                y: -geometry.safeAreaInsets.top,
                width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            )

            Path { path in
                path.addRect(backdrop)
                path.addRoundedRect(in: viewport, cornerSize: CGSize(width: 16, height: 16))
            }
            .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))

            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.85), lineWidth: 2)
                .frame(width: viewport.width, height: viewport.height)
                .position(x: viewport.midX, y: viewport.midY)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

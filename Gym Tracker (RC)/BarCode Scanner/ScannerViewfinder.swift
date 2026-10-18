import SwiftUI

struct ScannerViewfinder: View {
    var body: some View {
        GeometryReader { geometry in
            let width = max(0, min(440, geometry.size.width - 48))
            let height = min(width * 0.55, geometry.size.height * 0.55)
            let viewport = CGRect(
                x: (geometry.size.width - width) / 2,
                y: (geometry.size.height - height) / 2,
                width: width,
                height: height
            )
            // Extend behind translucent system bars while keeping the clear window
            // centered within the safe camera area, including on an adapted sheet.
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
                .frame(width: width, height: height)
                .position(x: viewport.midX, y: viewport.midY)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

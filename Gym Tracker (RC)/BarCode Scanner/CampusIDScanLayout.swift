import SwiftUI

/// Shared scan surface for presenting an ID and lining one up with the camera.
enum CampusIDScanLayout {
    static let horizontalInset: CGFloat = 24
    static let quietArea: CGFloat = 24
    static let maximumWidth: CGFloat = 440
    static let preferredTopInset: CGFloat = 64
    static let barcodeAspectRatio: CGFloat = 3

    static func viewport(in size: CGSize) -> CGRect {
        let width = max(0, min(maximumWidth, size.width - 2 * horizontalInset))
        let preferredHeight = max(0, width - 2 * quietArea) / barcodeAspectRatio + 2 * quietArea
        let height = min(preferredHeight, max(0, size.height - 32))
        return CGRect(
            x: (size.width - width) / 2,
            y: min(preferredTopInset, max(0, (size.height - height) / 4)),
            width: width,
            height: height
        )
    }
}

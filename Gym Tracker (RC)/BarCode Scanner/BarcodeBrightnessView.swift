import SwiftUI
import UIKit

/// Resolve the actual presenting display, including the Duo inner display.
struct BarcodeBrightnessView: UIViewRepresentable {
    func makeUIView(context: Context) -> DisplayObserver { DisplayObserver() }
    func updateUIView(_ uiView: DisplayObserver, context: Context) {}

    final class DisplayObserver: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let screen = window?.windowScene?.screen {
                BrightnessManager.shared.activateBarcodeDisplay(on: screen)
            }
        }
    }
}

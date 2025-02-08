import UIKit

final class BrightnessManager {
    static let shared = BrightnessManager()
    
    private var originalBrightness: CGFloat?
    
    private init() {
        // Observe the app going inactive (backgrounded/closed)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Call this when the barcode overlay appears.
    func activateBarcodeDisplay() {
        // Save the original brightness if not already saved, and set to 100%
        if originalBrightness == nil {
            originalBrightness = UIScreen.main.brightness
        }
        UIScreen.main.brightness = 1.0
        print("BrightnessManager: Activated barcode display. Brightness set to 100%.")
    }
    
    /// Call this when the barcode overlay disappears.
    func deactivateBarcodeDisplay() {
        restoreBrightness()
    }
    
    @objc private func appWillResignActive() {
        // Always restore brightness immediately if the app is backgrounded or closed.
        restoreBrightness()
    }
    
    private func restoreBrightness() {
        if let original = originalBrightness {
            UIScreen.main.brightness = original
            print("BrightnessManager: Restored brightness to \(original).")
            originalBrightness = nil
        }
    }
}

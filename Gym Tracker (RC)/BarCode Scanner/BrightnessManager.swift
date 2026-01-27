import UIKit

final class BrightnessManager {
    static let shared = BrightnessManager()
    
    // Store original brightness to restore user's preference after barcode display
    private var originalBrightness: CGFloat?
    
    private init() {
        // Restore brightness if app backgrounds/closes while barcode is displayed
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func activateBarcodeDisplay() {
        if originalBrightness == nil {
            originalBrightness = UIScreen.main.brightness
        }
        // Maximum brightness improves barcode scanner readability
        UIScreen.main.brightness = 1.0
    }
    
    func deactivateBarcodeDisplay() {
        restoreBrightness()
    }
    
    @objc private func appWillResignActive() {
        restoreBrightness()
    }
    
    private func restoreBrightness() {
        if let original = originalBrightness {
            UIScreen.main.brightness = original
            originalBrightness = nil
        }
    }
}

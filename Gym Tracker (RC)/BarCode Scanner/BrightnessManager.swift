import UIKit

/// Thread-safe brightness manager that must be called on the main thread
/// The presenting screen is resolved from the barcode sheet’s window scene.
@MainActor
final class BrightnessManager {
    static let shared = BrightnessManager()
    
    // Store original brightness to restore user's preference after barcode display
    private var originalBrightness: CGFloat?
    private weak var activeScreen: UIScreen?
    
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
    
    func activateBarcodeDisplay(on screen: UIScreen) {
        guard activeScreen !== screen || originalBrightness == nil else { return }
        restoreBrightness()
        activeScreen = screen
        originalBrightness = screen.brightness
        screen.brightness = 1.0
    }

    func deactivateBarcodeDisplay() {
        restoreBrightness()
    }
    
    @objc private func appWillResignActive() {
        // NotificationCenter callbacks may come from any thread, ensure main thread access
        Task { @MainActor in
            restoreBrightness()
        }
    }
    
    private func restoreBrightness() {
        if let original = originalBrightness {
            activeScreen?.brightness = original
            originalBrightness = nil
            activeScreen = nil
        }
    }
}

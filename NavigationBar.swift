import SwiftUI
import AVFoundation
import LocalAuthentication

struct BottomNavigationBar: View {
    // Bound to ContentView.
    @Binding var isScannerPresented: Bool
    @Binding var showAboutPopup: Bool
    @Binding var showBarcodeDisplay: Bool  // Controlled by the parent (ContentView).

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var alertManager: AlertManager

    @AppStorage("faceIDEnabled") private var faceIDEnabled: Bool = false
    @AppStorage("gymBarcode") private var scannedBarcode: String = ""

    // Local state for showing the Settings sheet.
    @State private var showSettingsPopup: Bool = false

    // Computed property to check if the device is an iPhone.
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with a blur effect.
                BlurView(style: .systemMaterial)
                    .frame(width: geometry.size.width, height: 80)
                    .edgesIgnoringSafeArea(.bottom)
                    .overlay(
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                            .frame(height: 1)
                            .frame(maxHeight: .infinity, alignment: .top),
                        alignment: .top
                    )
                
                VStack {
                    HStack {
                        // Hokie Passport Button (only on iPhone).
                        if isPhone {
                            Button(action: {
                                handlePassportButtonTapped()
                            }) {
                                Image(systemName: scannedBarcode.isEmpty ? "plus.rectangle" : "person.crop.rectangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 27)
                                    .foregroundColor(.primary)
                            }
                            .accessibilityLabel(scannedBarcode.isEmpty ? "Add Hokie Passport" : "Show Hokie Passport")
                        }
                        
                        Spacer()
                        
                        // Settings Button with your custom "Gear" asset.
                        Button(action: {
                            showSettingsPopup.toggle()
                        }) {
                            Image("Gear")
                                .resizable()
                                .renderingMode(.template)  // Allows tinting via foregroundColor.
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.primary)
                        }
                        .accessibilityLabel("Settings")
                        .sheet(isPresented: $showSettingsPopup) {
                            SettingsView()
                                .environmentObject(alertManager)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
        }
        // Present the scanner as a sheet.
        .sheet(isPresented: $isScannerPresented) {
            BarcodeScannerView(isPresented: $isScannerPresented)
                .environmentObject(alertManager)
        }
    }
}

// MARK: - Private Methods
extension BottomNavigationBar {
    /// Decide whether to display the stored barcode (after authentication) or open the scanner.
    private func handlePassportButtonTapped() {
        if scannedBarcode.isEmpty {
            // No stored barcode; check camera access and present the scanner.
            checkCameraAccess()
        } else {
            // Barcode exists; if Face ID is enabled, authenticate before displaying.
            if faceIDEnabled {
                authenticateUser { success in
                    if success {
                        showBarcodeDisplay = true
                    } else {
                        alertManager.showAlert(.authenticationFailed)
                    }
                }
            } else {
                showBarcodeDisplay = true
            }
        }
    }
    
    /// Check camera access before presenting the scanner.
    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isScannerPresented = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isScannerPresented = true
                    } else {
                        alertManager.showAlert(.cameraAccessDenied)
                    }
                }
            }
        case .denied, .restricted:
            alertManager.showAlert(.cameraAccessDenied)
        @unknown default:
            alertManager.showAlert(.cameraAccessDenied)
        }
    }
    
    /// Prompt Face ID authentication before displaying the stored barcode.
    private func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to view your Hokie Passport."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
}

/// A UIViewRepresentable for UIKit's UIVisualEffectView with an optional overlay.
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    var overlayColor: UIColor = .clear

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let effectView = UIVisualEffectView(effect: blurEffect)
        
        let overlayView = UIView(frame: .zero)
        overlayView.backgroundColor = overlayColor
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        effectView.contentView.addSubview(overlayView)
        
        return effectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        if let overlayView = uiView.contentView.subviews.first {
            overlayView.backgroundColor = overlayColor
        }
    }
}

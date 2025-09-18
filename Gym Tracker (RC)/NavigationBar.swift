import SwiftUI
import AVFoundation
import LocalAuthentication

struct BottomNavigationBar: View {
    // Whether to present the scanner sheet (bound to ContentView)
    @Binding var isScannerPresented: Bool
    
    // Optional: If you still use the About popup, keep it here
    @Binding var showAboutPopup: Bool

    // Environment & AppStorage
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var alertManager: AlertManager
    
    @AppStorage("faceIDEnabled") private var faceIDEnabled: Bool = false
    @AppStorage("gymBarcode") private var scannedBarcode: String = ""
    
    // Local state for showing the Barcode display sheet
    @State private var isBarcodeDisplayPresented: Bool = false
    
    // Local state for showing the Settings sheet
    @State private var showSettingsPopup: Bool = false
    
    // Computed property to check if the device is an iPhone
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with blur effect
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
                        // Conditionally show the Hokie Passport Button only if it's an iPhone
                        if isPhone {
                            Button(action: {
                                handlePassportButtonTapped()
                            }) {
                                Image(systemName: scannedBarcode.isEmpty ? "plus.rectangle" : "person.crop.rectangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27, height: 27)
                                    .foregroundColor(.primary)
                            }
                            .accessibilityLabel(scannedBarcode.isEmpty ? "Add Hokie Passport" : "Show Hokie Passport")
                        }
                        
                        Spacer()
                        
                        // Settings Button
                        Button(action: {
                            showSettingsPopup.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
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
        // Present the scanner in one sheet
        .sheet(isPresented: $isScannerPresented) {
            BarcodeScannerView(isPresented: $isScannerPresented)
                .environmentObject(alertManager)
        }
        // Present the display in a separate sheet
        .sheet(isPresented: $isBarcodeDisplayPresented) {
            BarcodeDisplayView(isPresented: $isBarcodeDisplayPresented)
        }
    }
}

// MARK: - Private Methods
extension BottomNavigationBar {
    /// Decides whether to display the existing barcode or open the scanner
    private func handlePassportButtonTapped() {
        if scannedBarcode.isEmpty {
            // If there's no stored barcode, present the scanner (with camera check)
            checkCameraAccess()
        } else {
            // If a barcode is already stored, authenticate (if needed) then display it
            if faceIDEnabled {
                authenticateUser { success in
                    if success {
                        isBarcodeDisplayPresented = true
                    } else {
                        alertManager.showAlert(.authenticationFailed)
                    }
                }
            } else {
                isBarcodeDisplayPresented = true
            }
        }
    }
    
    /// Checks camera access before presenting the barcode scanner
    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already granted
            isScannerPresented = true
        case .notDetermined:
            // Request access
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
    
    /// Prompts Face ID before displaying the stored barcode
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
            // If Face ID is not available, automatically fail
            completion(false)
        }
    }
}

// A UIViewRepresentable for UIKit's UIVisualEffectView
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        return visualEffectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // Nothing to update since the blur style is static
    }
}

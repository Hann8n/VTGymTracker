//
//  SettingsView.swift
//  Gym Tracker
//
//  Created by Jack Hannon on February 8, 2025.
//

import SwiftUI
import LocalAuthentication
import AVFoundation

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var alertManager: AlertManager

    @AppStorage("appTheme") private var appTheme: String = "Auto"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("gymBarcode") private var gymBarcode: String = ""
    @AppStorage("faceIDEnabled") private var faceIDEnabled: Bool = false

    @State private var showBarcodeScanner: Bool = false

    // Computed property to check if the device is an iPhone
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        NavigationView {
            Form {
                AppearanceSection(appTheme: $appTheme)
                
                // Conditionally include HokiePassportSection only if on iPhone
                if isPhone {
                    HokiePassportSection(
                        gymBarcode: $gymBarcode,
                        showBarcodeScanner: $showBarcodeScanner,
                        faceIDEnabled: $faceIDEnabled,
                        alertManager: alertManager
                    )
                }
                
                AboutSection()
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing:
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.customOrange)
            )
            .alert(item: $alertManager.currentAlert) { alertType in
                alertType.generateAlert(openSettings: {
                    UIApplication.shared.openSettings()
                })
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(isPresented: $showBarcodeScanner)
                    .environmentObject(alertManager)
            }
        }
        // Minimal change: apply the chosen theme so the settings view updates immediately.
        .preferredColorScheme(appTheme == "Light" ? .light : appTheme == "Dark" ? .dark : nil)
    }
}

// MARK: - Subviews

struct AppearanceSection: View {
    @Binding var appTheme: String

    var body: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $appTheme) {
                Text("Auto").tag("Auto")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
            .pickerStyle(MenuPickerStyle()) // Dropdown style picker
            .frame(maxWidth: .infinity, alignment: .leading)
            .tint(Color.orange) // Custom orange for dropdown
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) // Add some padding
    }
}

struct HokiePassportSection: View {
    @Binding var gymBarcode: String
    @Binding var showBarcodeScanner: Bool
    @Binding var faceIDEnabled: Bool
    var alertManager: AlertManager

    @State private var showCopyConfirmation: Bool = false
    @State private var showRevealedBarcode: Bool = false
    @State private var revealingBarcode: Bool = false

    var body: some View {
        Section(header: Text("Hokie Passport")) {
            if gymBarcode.isEmpty {
                Button(action: {
                    checkCameraAccess()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.customOrange)
                            .font(.title3)
                        Text("Add Hokie Passport")
                            .foregroundColor(.customOrange)
                    }
                }
            } else {
                if faceIDEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.customOrange)
                            .font(.title3)
                        
                        if showRevealedBarcode {
                            // Revealed state: display normal barcode text with copy options.
                            Text(gymBarcode)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.customOrange.opacity(0.1))
                                .cornerRadius(16)
                                .transition(.opacity)
                        } else {
                            // Hidden state: display larger bullet dots.
                            let hiddenText = String(repeating: "•", count: gymBarcode.count)
                            Text(hiddenText)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0))
                                .cornerRadius(16)
                        }
                        
                        Spacer()
                        
                        if showRevealedBarcode {
                            Button(action: {
                                copyToClipboard()
                            }) {
                                Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.customOrange)
                            }
                            .disabled(gymBarcode.isEmpty)
                            .padding(.trailing, 8)
                        } else {
                            Button(action: {
                                authenticateAndRevealBarcode()
                            }) {
                                Image(systemName: "lock")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.customOrange)
                            }
                            .padding(.trailing, 8)
                            .disabled(revealingBarcode)
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.customOrange)
                            .font(.title3)
                        
                        Text(gymBarcode)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.customOrange.opacity(0.1))
                            .cornerRadius(16)
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard()
                        }) {
                            Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.customOrange)
                        }
                        .disabled(gymBarcode.isEmpty)
                        .padding(.trailing, 8)
                    }
                }
            }
            
            Toggle(isOn: Binding(
                get: { faceIDEnabled },
                set: { newValue in
                    handleFaceIDToggle(isOn: newValue)
                }
            )) {
                Text("Require Face ID")
            }
            
            if !gymBarcode.isEmpty {
                Button(action: {
                    removeHokiePassport()
                }) {
                    Text("Remove Card")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            Color(UIColor { traitCollection in
                                traitCollection.userInterfaceStyle == .light
                                ? UIColor(red: 134 / 255, green: 31 / 255, blue: 65 / 255, alpha: 1.0)
                                : .clear
                            })
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.customMaroon, lineWidth: 2)
                        )
                }
                .padding(.vertical, 2)
            }
        }
        .animation(.default, value: showRevealedBarcode)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = gymBarcode
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showCopyConfirmation = false
        }
    }

    private func removeHokiePassport() {
        gymBarcode = ""
        showRevealedBarcode = false
    }

    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showBarcodeScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showBarcodeScanner = true
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

    private func handleFaceIDToggle(isOn: Bool) {
        if isOn {
            authenticateFaceID(reason: "Authenticate to enable Face ID.") { success, error in
                if success {
                    faceIDEnabled = true
                    // Optionally hide the barcode if it's currently revealed.
                    showRevealedBarcode = false
                } else {
                    faceIDEnabled = false
                    if let error = error, isFaceIDUnavailable(error: error) {
                        alertManager.showAlert(.faceIDSettings)
                    }
                }
            }
        } else {
            authenticateFaceID(reason: "Authenticate to disable Face ID.") { success, error in
                if success {
                    faceIDEnabled = false
                    showRevealedBarcode = false
                } else {
                    faceIDEnabled = true
                    if let error = error, isFaceIDUnavailable(error: error) {
                        alertManager.showAlert(.faceIDSettings)
                    }
                }
            }
        }
    }

    private func authenticateAndRevealBarcode() {
        guard !revealingBarcode else { return }
        revealingBarcode = true
        authenticateFaceID(reason: "Authenticate to view your Hokie Passport.") { success, error in
            revealingBarcode = false
            if success {
                withAnimation {
                    showRevealedBarcode = true
                }
                // Optionally hide the barcode again after a delay.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showRevealedBarcode = false
                    }
                }
            } else {
                if let error = error, isFaceIDUnavailable(error: error) {
                    alertManager.showAlert(.faceIDSettings)
                }
            }
        }
    }

    private func authenticateFaceID(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
                DispatchQueue.main.async {
                    completion(success, evaluateError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }

    private func isFaceIDUnavailable(error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == LAErrorDomain &&
            (nsError.code == LAError.biometryNotAvailable.rawValue ||
             nsError.code == LAError.biometryLockout.rawValue ||
             nsError.code == LAError.biometryNotEnrolled.rawValue)
    }
}

struct AboutSection: View {
    var body: some View {
        Section(header: Text("About")) {
            NavigationLink("App Information") {
                AboutView()
            }
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
        }
    }
}

struct AboutView: View {
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (Build \(build))"
        }
        return "Version N/A"
    }

    var body: some View {
        VStack {
            // Top content
            VStack(spacing: 16) {
                Text("VT Gym Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(appVersion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("""
                    An open-source app for Virginia Tech Gyms
                    
                    Developed by Jack Hannon
                    """)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            // Footer text pinned to the bottom
            Text("""
                Virginia Tech is not associated with this project
                
                All rights reserved to their respective holders
                """)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .padding()
        .navigationTitle("App Information")
    }
}

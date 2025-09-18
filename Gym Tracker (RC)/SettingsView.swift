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
    @State private var isIDInputOptionsPresented: Bool = false

    // Computed property to check if the device is an iPhone
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        NavigationStack {
            Form {
                AppearanceSection(appTheme: $appTheme)
                
                // Conditionally include HokiePassportSection only if on iPhone
                if isPhone {
                    HokiePassportSection(
                        gymBarcode: $gymBarcode,
                        showBarcodeScanner: $showBarcodeScanner,
                        isIDInputOptionsPresented: $isIDInputOptionsPresented,
                        faceIDEnabled: $faceIDEnabled,
                        alertManager: alertManager
                    )
                }
                
                AboutSection()
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .tint(.customOrange)
                }
            }
            .alert(item: $alertManager.currentAlert) { alertType in
                alertType.generateAlert(openSettings: {
                    UIApplication.shared.openSettings()
                })
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(isPresented: $showBarcodeScanner)
                    .environmentObject(alertManager)
            }
            .sheet(isPresented: $isIDInputOptionsPresented) {
                IDInputOptionsView(isPresented: $isIDInputOptionsPresented)
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
        Section("Appearance") {
            Picker("Theme", selection: $appTheme) {
                Label("Auto", systemImage: "circle.lefthalf.filled").tag("Auto")
                Label("Light", systemImage: "sun.max").tag("Light")
                Label("Dark", systemImage: "moon").tag("Dark")
            }
            .pickerStyle(.menu)
            .tint(.customOrange)
        }
    }
}

struct HokiePassportSection: View {
    @Binding var gymBarcode: String
    @Binding var showBarcodeScanner: Bool
    @Binding var isIDInputOptionsPresented: Bool
    @Binding var faceIDEnabled: Bool
    var alertManager: AlertManager

    @State private var showCopyConfirmation: Bool = false
    @State private var showRevealedBarcode: Bool = false
    @State private var revealingBarcode: Bool = false

    var body: some View {
        Section("Hokie Passport") {
            if gymBarcode.isEmpty {
                Button {
                    isIDInputOptionsPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.rectangle.fill")
                            .foregroundColor(.customOrange)
                        Text("Add Hokie Passport")
                            .foregroundColor(.customOrange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                if faceIDEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.customOrange)
                        
                        if showRevealedBarcode {
                            // Revealed state: display normal barcode text with copy options.
                            Text(gymBarcode)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .transition(.opacity)
                        } else {
                            // Hidden state: display larger bullet dots.
                            let hiddenText = String(repeating: "•", count: gymBarcode.count)
                            Text(hiddenText)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        
                        Spacer()
                        
                        if showRevealedBarcode {
                            Button {
                                copyToClipboard()
                            } label: {
                                Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.regular)
                            .tint(.customOrange)
                            .disabled(gymBarcode.isEmpty)
                        } else {
                            Button {
                                authenticateAndRevealBarcode()
                            } label: {
                                Image(systemName: "lock")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.regular)
                            .tint(.customOrange)
                            .disabled(revealingBarcode)
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.customOrange)
                        
                        Text(gymBarcode)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        
                        Spacer()
                        
                        Button {
                            copyToClipboard()
                        } label: {
                            Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.regular)
                        .tint(.customOrange)
                        .disabled(gymBarcode.isEmpty)
                    }
                }
            }
            
            if !gymBarcode.isEmpty {
                Toggle("Require Face ID", isOn: Binding(
                    get: { faceIDEnabled },
                    set: { newValue in
                        handleFaceIDToggle(isOn: newValue)
                    }
                ))
                .tint(.customOrange)
                
                Button("Remove Card", role: .destructive) {
                    removeHokiePassport()
                }
                .foregroundColor(.customMaroon)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
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
        Section("About") {
            NavigationLink("App Information") {
                AboutView()
            }
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
            // GitHub link with an external link icon on the opposite side
            Link(destination: URL(string: "https://github.com/Hann8n/VTGymTracker")!) {
                HStack {
                    Text("View on GitHub")
                    .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

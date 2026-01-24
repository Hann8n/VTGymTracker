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
    @State private var showManualInput: Bool = false

    // Computed property to check if the device is an iPhone
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        NavigationStack {
            Form {
                AppearanceSection(appTheme: $appTheme)
                
                // Conditionally include CampusIDSection only if on iPhone
                if isPhone {
                    CampusIDSection(
                        gymBarcode: $gymBarcode,
                        showBarcodeScanner: $showBarcodeScanner,
                        showManualInput: $showManualInput,
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
            .sheet(isPresented: $showManualInput) {
                ManualIDInputView(isPresented: $showManualInput)
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

struct CampusIDSection: View {
    @Binding var gymBarcode: String
    @Binding var showBarcodeScanner: Bool
    @Binding var showManualInput: Bool
    @Binding var faceIDEnabled: Bool
    var alertManager: AlertManager

    @State private var showCopyConfirmation: Bool = false
    @State private var isAuthenticatingForCopy: Bool = false
    @State private var isAuthenticatingForRemove: Bool = false
    @State private var showRemoveConfirmation: Bool = false

    var body: some View {
        Section("Campus ID") {
            if gymBarcode.isEmpty {
                Button {
                    showBarcodeScanner = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.customOrange)
                            .frame(width: 24, height: 24, alignment: .center)
                        Text("Scan Barcode")
                            .foregroundColor(.customOrange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    showManualInput = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "keyboard")
                            .foregroundColor(.customOrange)
                            .frame(width: 24, height: 24, alignment: .center)
                        Text("Enter ID Number")
                            .foregroundColor(.customOrange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                LabeledContent {
                    copyableIdValueView(
                        text: faceIDEnabled ? "####-#####" : formatCampusID(gymBarcode),
                        requireFaceID: faceIDEnabled
                    )
                } label: {
                    Label("Campus ID", systemImage: "barcode.viewfinder")
                        .foregroundStyle(.customOrange)
                }
            }
            
            if !gymBarcode.isEmpty {
                Toggle(isOn: Binding(
                    get: { faceIDEnabled },
                    set: { newValue in handleFaceIDToggle(isOn: newValue) }
                )) {
                    Label("Require Face ID", systemImage: "faceid")
                }
                .tint(.customOrange)

                Button {
                    handleRemoveCampusID()
                } label: {
                    Text("Remove")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.white)
                .listRowBackground(Color.customMaroon.opacity(0.7))
                .disabled(isAuthenticatingForRemove)
            }
        }
        .alert("Remove Campus ID?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                performRemoveAfterConfirmation()
            }
        } message: {
            Text("You can add your card back anytime by scanning or entering your ID.")
        }
    }

    @ViewBuilder
    private func copyableIdValueView(text: String, requireFaceID: Bool = false) -> some View {
        Button {
            if requireFaceID {
                authenticateAndCopy()
            } else {
                copyToClipboard()
            }
        } label: {
            Text(text)
                .font(.subheadline.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.primary)
                .opacity(showCopyConfirmation ? 0 : 1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    Text("Copied")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        .opacity(showCopyConfirmation ? 1 : 0)
                        .allowsHitTesting(false)
                }
        }
        .buttonStyle(.plain)
        .disabled(gymBarcode.isEmpty || (requireFaceID && isAuthenticatingForCopy))
        .animation(.easeInOut(duration: 0.25), value: showCopyConfirmation)
        .accessibilityLabel("Copy ID")
        .accessibilityHint(showCopyConfirmation ? "Copied" : (requireFaceID ? "Double-tap to authenticate and copy" : "Double-tap to copy"))
    }

    private func formatCampusID(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        let nine = String(digits.prefix(9))
        if nine.count <= 4 { return nine }
        let first4 = nine.prefix(4)
        let rest = nine.dropFirst(4)
        return "\(first4)-\(rest)"
    }

    private func copyToClipboard() {
        let digits = gymBarcode.filter { $0.isNumber }
        UIPasteboard.general.string = String(digits.prefix(9))
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showCopyConfirmation = false
        }
    }
    
    private func removeCampusID() {
        gymBarcode = ""
    }

    private func handleRemoveCampusID() {
        showRemoveConfirmation = true
    }

    private func performRemoveAfterConfirmation() {
        if faceIDEnabled {
            guard !isAuthenticatingForRemove else { return }
            isAuthenticatingForRemove = true
            authenticateFaceID(reason: "Authenticate to remove your Campus ID.") { success, error in
                isAuthenticatingForRemove = false
                if success {
                    removeCampusID()
                } else if let error = error, isFaceIDUnavailable(error: error) {
                    alertManager.showAlert(.faceIDSettings)
                }
            }
        } else {
            removeCampusID()
        }
    }

    private func handleFaceIDToggle(isOn: Bool) {
        if isOn {
            authenticateFaceID(reason: "Authenticate to enable Face ID.") { success, error in
                if success {
                    faceIDEnabled = true
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
                } else {
                    faceIDEnabled = true
                    if let error = error, isFaceIDUnavailable(error: error) {
                        alertManager.showAlert(.faceIDSettings)
                    }
                }
            }
        }
    }

    private func authenticateAndCopy() {
        guard !isAuthenticatingForCopy else { return }
        isAuthenticatingForCopy = true
        authenticateFaceID(reason: "Authenticate to copy your Campus ID.") { success, error in
            isAuthenticatingForCopy = false
            if success {
                copyToClipboard()
            } else if let error = error, isFaceIDUnavailable(error: error) {
                alertManager.showAlert(.faceIDSettings)
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

//
//  Alerts.swift
//  Gym Tracker
//
//  Created by Jack on 1/18/25.
//  Updated by [Your Name] on [Date].
//

import SwiftUI
import UIKit

// MARK: - AlertType Enum
enum AlertType: Identifiable {
    case barcodeScanned
    case cameraAccessDenied
    case authenticationFailed
    case invalidBarcode
    case faceIDSettings
    case custom(title: String, message: String, primaryButton: Alert.Button?, secondaryButton: Alert.Button?)

    // Unique identifier for each alert instance based on its content
    var id: String {
        switch self {
        case .barcodeScanned:
            return "barcodeScanned"
        case .cameraAccessDenied:
            return "cameraAccessDenied"
        case .authenticationFailed:
            return "authenticationFailed"
        case .invalidBarcode:
            return "invalidBarcode"
        case .faceIDSettings:
            return "faceIDSettings"
        case .custom(let title, let message, _, _):
            return "custom_\(title)_\(message)"
        }
    }

    // Generate Alert based on AlertType
    func generateAlert(openSettings: (() -> Void)? = nil) -> Alert {
        switch self {
        case .barcodeScanned:
            return Alert(
                title: Text("Barcode Scanned"),
                message: Text("Your gym barcode has been successfully scanned."),
                dismissButton: .default(Text("OK"))
            )
        case .cameraAccessDenied:
            return Alert(
                title: Text("Camera Access Required"),
                message: Text("Camera access is currently disabled. To enable it, please go to Settings and allow Camera access for this app."),
                primaryButton: .default(Text("Settings"), action: {
                    openSettings?()
                }),
                secondaryButton: .cancel()
            )
        case .authenticationFailed:
            return Alert(
                title: Text("Authentication Failed"),
                message: Text("Unable to authenticate using Face ID. Please try again."),
                dismissButton: .default(Text("OK"))
            )
        case .invalidBarcode:
            return Alert(
                title: Text("Invalid Barcode"),
                message: Text("Please enter a valid alphanumeric barcode."),
                dismissButton: .default(Text("OK"))
            )
        case .faceIDSettings:
            return Alert(
                title: Text("Face ID Disabled"),
                message: Text("Face ID authentication is currently disabled. To enable it, please go to Settings and allow Face ID access for this app."),
                primaryButton: .default(Text("Open Settings"), action: {
                    openSettings?()
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        case .custom(let title, let message, let primary, let secondary):
            if let primary = primary, let secondary = secondary {
                return Alert(
                    title: Text(title),
                    message: Text(message),
                    primaryButton: primary,
                    secondaryButton: secondary
                )
            } else {
                return Alert(
                    title: Text(title),
                    message: Text(message),
                    dismissButton: primary ?? .default(Text("OK"))
                )
            }
        }
    }
}

// MARK: - AlertManager Class
class AlertManager: ObservableObject {
    @Published var currentAlert: AlertType?

    // Function to present an alert
    func showAlert(_ alert: AlertType) {
        DispatchQueue.main.async {
            self.currentAlert = alert
        }
    }

    // Function to dismiss the current alert
    func dismissAlert() {
        DispatchQueue.main.async {
            self.currentAlert = nil
        }
    }
}

// MARK: - UIApplication Extension to Open Settings
extension UIApplication {
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if self.canOpenURL(settingsURL) {
            self.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

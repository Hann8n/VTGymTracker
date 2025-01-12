//
//  NavigationBar.swift
//  Gym Tracker
//
//  Created by Jack on 1/13/25.
//

import SwiftUI
import AVFoundation

struct BottomNavigationBar: View {
    @Binding var isScannerPresented: Bool
    @Binding var scannedBarcode: String
    @Binding var showAboutPopup: Bool
    @Binding var showBarcodeAlert: Bool
    @Binding var showCameraAccessDeniedAlert: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with blur effect
                BlurView(style: .systemMaterial)
                    .frame(width: geometry.size.width, height: 80) // Navigation bar height
                    .edgesIgnoringSafeArea(.bottom)
                    .overlay(
                        // Thin line at the top of the navigation bar
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                            .frame(height: 1)
                            .frame(maxHeight: .infinity, alignment: .top), // Align the line to the top
                        alignment: .top
                    )

                VStack {
                    HStack {
                        // Left button: Barcode Scanner
                        Button(action: {
                            checkAndPresentScanner()
                        }) {
                            Image(systemName: scannedBarcode.isEmpty ? "person.crop.rectangle" : "person.crop.rectangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.primary)
                        }
                        .accessibilityLabel(scannedBarcode.isEmpty ? "Add PID" : "Show PID")
                        .sheet(isPresented: $isScannerPresented) {
                            if scannedBarcode.isEmpty {
                                BarcodeScannerView(
                                    isPresented: $isScannerPresented,
                                    scannedBarcode: $scannedBarcode,
                                    showAlert: $showBarcodeAlert
                                )
                                .edgesIgnoringSafeArea(.all)
                            } else {
                                BarcodeDisplayView(
                                    isPresented: $isScannerPresented,
                                    scannedBarcode: $scannedBarcode
                                )
                            }
                        }

                        Spacer()

                        // Right button: About Info
                        Button(action: {
                            showAboutPopup.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.primary)
                        }
                        .alert(isPresented: $showAboutPopup) {
                            Alert(
                                title: Text("App Info"),
                                message: Text("VT Gym Tracker is an open-source app by Jack Hannon. \n\nHours are sourced from the Virginia Tech Rec Sports website.\n\nOccupancy data is provided by Innosoft Canada. \n\nThis project is not associated with Virginia Tech."),
                                primaryButton: .default(Text("GitHub")) {
                                    if let url = URL(string: "https://github.com/Hann8n/VTGymTracker") {
                                        UIApplication.shared.open(url)
                                    }
                                },
                                secondaryButton: .cancel(Text("Close"))
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10) // Minimal padding to keep icons close to the top

                    Spacer() // Push the icons to the top within the increased height
                }
            }
        }
    }

    // Function to check camera permissions and present the scanner
    private func checkAndPresentScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isScannerPresented.toggle()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isScannerPresented.toggle()
                    } else {
                        showCameraAccessDeniedAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraAccessDeniedAlert = true
        @unknown default:
            showCameraAccessDeniedAlert = true
        }
    }
}

// UIViewRepresentable for creating a blur effect
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

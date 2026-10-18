import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Binding var isPresented: Bool
    @AppStorage("gymBarcode") private var gymBarcode = ""
    @State private var torchOn = false
    @State private var torchAvailable = false
    @State private var cameraAuthorized = false
    @State private var permissionChecked = false
    @State private var cameraError: String?

    var body: some View {
        Group {
            if #available(iOS 27.0, *) {
                scannerScreen
                    .presentationSizing(.form)
                    .presentationPlacement(.trailing)
            } else if #available(iOS 18.0, *) {
                scannerScreen.presentationSizing(.form)
            } else {
                scannerScreen
            }
        }
        .preferredColorScheme(.dark)
        .task {
            cameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            permissionChecked = true
        }
    }

    private var scannerScreen: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let cameraError {
                    ContentUnavailableView("Camera unavailable", systemImage: "camera", description: Text(cameraError))
                } else if cameraAuthorized {
                    CampusIDCameraView(
                        torchOn: torchOn,
                        onCode: saveBarcode,
                        onError: { cameraError = $0 },
                        onTorchAvailability: { available in
                            torchAvailable = available
                            if !available { torchOn = false }
                        }
                    )
                    .ignoresSafeArea()
                    scanGuide
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                } else if permissionChecked {
                    ContentUnavailableView {
                        Label("Camera access needed", systemImage: "camera")
                    } actions: {
                        Button("Open Settings") { UIApplication.shared.openSettings() }
                    }
                } else {
                    ProgressView().accessibilityLabel("Opening camera")
                }
            }
            .navigationTitle("Scan Campus ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close scanner", systemImage: "xmark") { isPresented = false }
                        .labelStyle(.iconOnly)
                }
                if #available(iOS 27.1, *) {
                    flashlightItem.axisBehavior(.verticalPreferred)
                } else {
                    flashlightItem
                }
            }
        }
    }

    private var flashlightItem: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button(torchOn ? "Turn flashlight off" : "Turn flashlight on",
                   systemImage: torchOn ? "flashlight.on.fill" : "flashlight.off.fill") {
                torchOn.toggle()
            }
            .disabled(!torchAvailable || cameraError != nil)
            .accessibilityValue(torchOn ? "On" : "Off")
        }
    }

    private var scanGuide: some View {
        GeometryReader { geometry in
            let width = max(0, min(440, geometry.size.width - 48))
            let height = min(width * 0.55, geometry.size.height * 0.55)
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.85), lineWidth: 2)
                .frame(width: width, height: height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private func saveBarcode(_ value: String) {
        var code = value.uppercased()
        let markers: Set<Character> = ["A", "B", "C", "D"]
        if code.first.map({ !markers.contains($0) }) ?? true { code = "A" + code }
        if code.last.map({ !markers.contains($0) }) ?? true { code += "B" }
        gymBarcode = code
        isPresented = false
    }
}

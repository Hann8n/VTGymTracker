// BarcodeScannerView.swift
// Gym Tracker
//
// Created by Jack on 1/18/25.
//

import SwiftUI
import CodeScanner
import AVFoundation

private let flashlightBottomPadding: CGFloat = 32

struct BarcodeScannerView: View {
    @Binding var isPresented: Bool
    @AppStorage("gymBarcode") private var gymBarcode: String = ""
    @State private var torchOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                CodeScannerView(
                    codeTypes: [.codabar],
                    scanMode: .once,
                    showViewfinder: false,
                    requiresPhotoOutput: false,
                    isTorchOn: torchOn,
                    videoCaptureDevice: AVCaptureDevice.default(for: .video),
                    completion: handleScanResult
                )
                .ignoresSafeArea(.all)

                GeometryReader { geo in
                    let (scanRect, w, h) = scanFrame(in: geo.size)
                    ZStack {
                        // Even-odd fill creates visual "hole" in overlay for scan area
                        ScanOverlayShape(holeRect: scanRect)
                            .fill(.black.opacity(0.5), style: FillStyle(eoFill: true))
                            .allowsHitTesting(false)

                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.white, lineWidth: 2)
                            .frame(width: w, height: h)
                            .position(x: scanRect.midX, y: scanRect.midY)
                            .allowsHitTesting(false)

                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 12, weight: .medium))
                            Text("All data is stored locally on this device")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .position(x: geo.size.width / 2, y: scanRect.maxY + 30)
                        .allowsHitTesting(false)
                    }
                }
                .ignoresSafeArea(.all)
            }
            .overlay(alignment: .bottom) {
                Button { torchOn.toggle() } label: {
                    Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 22))
                        .padding(16)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.white)
                .padding(.bottom, flashlightBottomPadding)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("Scan Campus ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func scanFrame(in size: CGSize) -> (CGRect, CGFloat, CGFloat) {
        let baseW: CGFloat = 300, baseH: CGFloat = 200
        let w = baseW * 1.15, h = baseH * 1.15
        let x = (size.width - w) / 2
        let y = (size.height - h) / 2 - 100
        return (CGRect(x: x, y: y, width: w, height: h), w, h)
    }

    private func handleScanResult(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scan):
            var code = scan.string.uppercased()
            // Codabar format requires A/B/C/D start/stop characters; ensure they exist
            let valid: Set<Character> = ["A", "B", "C", "D"]
            if code.first == nil || !valid.contains(code.first!) { code = "A" + code }
            if code.last == nil || !valid.contains(code.last!) { code = code + "B" }
            gymBarcode = code
            isPresented = false
        case .failure:
            break
        }
    }
}

private struct ScanOverlayShape: Shape {
    var holeRect: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addRoundedRect(in: holeRect, cornerSize: CGSize(width: 15, height: 15), style: .continuous)
        return p
    }
}

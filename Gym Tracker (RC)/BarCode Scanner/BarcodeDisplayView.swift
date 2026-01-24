import SwiftUI

// Removed custom card modifier to let system handle Liquid Glass styling

/// The barcode display view.
struct BarcodeDisplayView: View {
    @AppStorage("gymBarcode") private var gymBarcode = ""
    // The binding is kept for potential future use.
    @Binding var isPresented: Bool

    // Generate the barcode image.
    private var generatedBarcode: UIImage? {
        BarcodeGenerator.shared.generateCodabarBarcode(from: gymBarcode)
    }

    var body: some View {
        VStack(spacing: 16) {
            // The barcode display with system styling
            if let barcodeImage = generatedBarcode {
                Image(uiImage: barcodeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No barcode available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Optional header text for context.
            Text("Campus ID")
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

/// The overlay view that presents the barcode display along with the custom "Close" image.
struct BarcodeDisplayOverlayView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background covers the entire screen.
            Color.clear
                .ignoresSafeArea()
            
            VStack {
                // Barcode display respecting safe areas
                BarcodeDisplayView(isPresented: $isPresented)
                    .padding(.horizontal)
                Spacer()
                // Close indicator with liquid glass styling
                Image(systemName: "xmark")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(20)
                    .background(.regularMaterial, in: Circle())
                    .allowsHitTesting(false)
            }
            .padding(.top)
            .padding(.bottom)
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        // Ensure the entire area is tappable.
        .contentShape(Rectangle())
        // Tap anywhere dismisses the overlay.
        .onTapGesture {
            isPresented = false
        }
        .onAppear {
            BrightnessManager.shared.activateBarcodeDisplay()
        }
        .onDisappear {
            BrightnessManager.shared.deactivateBarcodeDisplay()
        }
    }
}

import SwiftUI

/// A high-contrast scan surface. The barcode keeps its aspect ratio and white quiet area.
struct BarcodeDisplayView: View {
    @AppStorage("gymBarcode") private var gymBarcode = ""
    @State private var cachedBarcodeImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            if let barcodeImage = cachedBarcodeImage {
                Image(uiImage: barcodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(24)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.black.opacity(0.1), lineWidth: 1)
                    }
                    .accessibilityLabel("Campus ID barcode")

                Text("ID ending in \(gymBarcode.filter(\.isNumber).suffix(4))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                ContentUnavailableView(
                    "Barcode unavailable",
                    systemImage: "barcode",
                    description: Text("Close this screen and check your Campus ID in Settings.")
                )
            }
        }
        .onAppear { updateBarcode() }
        .onChange(of: gymBarcode) { _, _ in updateBarcode() }
    }

    private func updateBarcode() {
        cachedBarcodeImage = BarcodeGenerator.shared.generateCodabarBarcode(from: gymBarcode)
    }
}

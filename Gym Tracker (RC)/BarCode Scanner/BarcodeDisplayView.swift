import SwiftUI

struct BarcodeDisplayView: View {
    @AppStorage("gymBarcode") private var gymBarcode = ""
    @Binding var isPresented: Bool

    private var generatedBarcode: UIImage? {
        BarcodeGenerator.shared.generateCodabarBarcode(from: gymBarcode)
    }

    var body: some View {
        VStack(spacing: 16) {
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
            
            Text("Campus ID")
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

struct BarcodeDisplayOverlayView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            VStack {
                BarcodeDisplayView(isPresented: $isPresented)
                    .padding(.horizontal)
                Spacer()
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
        .contentShape(Rectangle())
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

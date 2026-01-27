import SwiftUI

struct BarcodeDisplayView: View {
    @AppStorage("gymBarcode") private var gymBarcode = ""
    @State private var cachedBarcodeImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 16) {
            if let barcodeImage = cachedBarcodeImage {
                Image(uiImage: barcodeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .padding()
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No barcode available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Campus ID")
                .font(.headline)
                .foregroundColor(.black)
        }
        .onAppear {
            // Generate barcode when view appears
            cachedBarcodeImage = BarcodeGenerator.shared.generateCodabarBarcode(from: gymBarcode)
        }
        .onChange(of: gymBarcode) { _, newValue in
            // Regenerate barcode only when the barcode string changes
            cachedBarcodeImage = BarcodeGenerator.shared.generateCodabarBarcode(from: newValue)
        }
    }
}

// MARK: - Glass Close Button
@available(iOS 26.0, *)
struct GlassCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
        }
        .glassEffect(.regular.tint(.customMaroon).interactive(), in: Circle())
    }
}

struct FallbackGlassCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .semibold))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.customMaroon)
        .clipShape(Circle())
    }
}

struct BarcodeDisplayOverlayView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                BarcodeDisplayView()
                    .padding(.horizontal)
                Spacer()
                
                Group {
                    if #available(iOS 26.0, *) {
                        GlassCloseButton {
                            isPresented = false
                        }
                    } else {
                        FallbackGlassCloseButton {
                            isPresented = false
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.vertical)
        }
        .environment(\.colorScheme, .light)
        .transition(.move(edge: .bottom))
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

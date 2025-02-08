import SwiftUI

/// A reusable card view modifier for consistent styling.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)  // Always white background
            )
            .padding(.horizontal, 10)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
}

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
            // The card that holds the barcode image or a placeholder.
            Group {
                if let barcodeImage = generatedBarcode {
                    Image(uiImage: barcodeImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(10)
                } else {
                    Text("No barcode available")
                        .foregroundColor(.secondary)
                        .padding(20)
                }
            }
            .cardStyle()              // Apply the card styling.
            .frame(maxHeight: 150)     // Limit the card's height.
            
            // Optional header text for context.
            Text("Hokie Passport")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(5)
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
                // Barcode display near the top.
                BarcodeDisplayView(isPresented: $isPresented)
                Spacer()
                // Custom "Close" image styled as a button with a blur background.
                Image("Close")
                    .resizable()
                    .renderingMode(.template)  // This enables tinting.
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.primary) // Adjust the color as needed.
                    .padding(.bottom, 24)
                    .allowsHitTesting(false)
            }
            .padding(.top, 60) // Adjust the top padding as needed.
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

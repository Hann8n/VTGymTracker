import SwiftUI

struct BarcodeDisplayView: View {
    @Binding var isPresented: Bool
    @Binding var scannedBarcode: String

    let barcodeGenerator = BarcodeGenerator()
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    @State private var showAlert = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Background Layer: BlurView with a near-black overlay
            BlurView(style: .systemMaterialDark) // Choose a style that complements the dark theme
                .edgesIgnoringSafeArea(.all)

            Color.black.opacity(0.7) // Adjust opacity as needed for the "near black" effect
                .edgesIgnoringSafeArea(.all)

            // Main Content Layer
            NavigationView {
                VStack(spacing: 20) {
                    // Barcode Display
                    if let uiImage = barcodeGenerator.generateCodabarBarcode(from: scannedBarcode) {
                        ZStack {
                            Color.white
                                .frame(height: 170)
                                .cornerRadius(10)
                            Image(uiImage: uiImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(height: 150)
                                .padding()
                        }
                        .padding(.horizontal, 16)
                    } else {
                        Text("Unable to generate barcode.")
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .navigationTitle("Hokie Passport")
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                showAlert = true
                            }) {
                                Image(systemName: "gear")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.primary)
                                    .padding(15)
                                    .background(
                                        BlurView(style: .systemMaterial)
                                            .clipShape(Circle())
                                    )
                            }
                            .frame(width: 45, height: 45)
                            .padding(.leading, 20)
                            .padding(.bottom, 20)

                            Spacer()
                        }
                    }
                )
                .onAppear {
                    // Save the original brightness
                    originalBrightness = UIScreen.main.brightness
                    // Set brightness to 100%
                    UIScreen.main.brightness = 1.0
                }
                .onDisappear {
                    // Restore the original brightness when the view disappears
                    UIScreen.main.brightness = originalBrightness
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        UIScreen.main.brightness = 1.0
                    case .inactive, .background:
                        UIScreen.main.brightness = originalBrightness
                        isPresented = false
                    @unknown default:
                        break
                    }
                }
                .alert("Card Info", isPresented: $showAlert) {
                    Button("Remove Card", role: .destructive) {
                        deleteBarcode()
                    }
                    Button("Visit hokiepassport.vt.edu") {
                        openHokiePassportURL()
                    }
                    Button("Close", role: .cancel) {
                        showAlert = false
                    }
                } message: {
                    Text("All Data is stored locally on this device.\n\nBarcode: \(scannedBarcode)")
                }
            }
        }
    }

    /// Deletes the stored barcode from UserDefaults and updates the state.
    private func deleteBarcode() {
        UserDefaults.standard.removeObject(forKey: "gymBarcode")
        scannedBarcode = ""
        isPresented = false
    }

    /// Opens the Hokie Passport URL in a web browser.
    private func openHokiePassportURL() {
        if let url = URL(string: "https://www.hokiepassport.vt.edu/") {
            UIApplication.shared.open(url)
        }
    }
}

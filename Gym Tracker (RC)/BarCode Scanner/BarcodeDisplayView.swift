// BarcodeDisplayView.swift

import SwiftUI

struct BarcodeDisplayView: View {
    @Binding var isPresented: Bool
    @AppStorage("gymBarcode") private var gymBarcode: String = ""
    
    let barcodeGenerator = BarcodeGenerator()
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // Background Layers
            BlurView(style: .systemMaterialDark)
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Main Content
            NavigationView {
                VStack(spacing: 20) {
                    // Barcode Display
                    if !gymBarcode.isEmpty, let uiImage = barcodeGenerator.generateCodabarBarcode(from: gymBarcode) {
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
                        Text("No Hokie Passport Card Available.")
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Spacer()
                }
                .navigationTitle("Hokie Passport")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.white)
                        }
                        .accessibilityLabel("Close")
                    }
                }
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
            }
        }
    }
}

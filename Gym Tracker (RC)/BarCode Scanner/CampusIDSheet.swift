import SwiftUI

struct CampusIDSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if #available(iOS 27.0, *) {
                scanScreen
                    .presentationSizing(.form)
                    .presentationPlacement(.trailing)
            } else if #available(iOS 18.0, *) {
                scanScreen
                    .presentationSizing(.form)
            } else {
                scanScreen
            }
        }
        .preferredColorScheme(.light)
        .onDisappear { BrightnessManager.shared.deactivateBarcodeDisplay() }
    }

    private var scanScreen: some View {
        NavigationStack {
            ScrollView {
                BarcodeDisplayView()
                    .frame(maxWidth: 440)
                    .padding(24)
                    .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center)
            .background(Color(.systemBackground))
            .background { BarcodeBrightnessView().frame(width: 0, height: 0) }
            .navigationTitle("Campus ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close Campus ID", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
}

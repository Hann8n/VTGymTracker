import SwiftUI

struct CampusIDSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close Campus ID", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
        }
        .onDisappear { BrightnessManager.shared.deactivateBarcodeDisplay() }
    }
}

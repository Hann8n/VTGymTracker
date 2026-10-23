import SwiftUI

struct CampusIDSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let viewport = CampusIDScanLayout.viewport(in: geometry.size)
                ScrollView {
                    BarcodeDisplayView(scanWindowSize: viewport.size)
                        .frame(width: viewport.width)
                        .padding(.top, viewport.minY)
                        .padding(.bottom, CampusIDScanLayout.horizontalInset)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .defaultScrollAnchor(.top)
            }
            .background(Color(.systemBackground))
            .background { BarcodeBrightnessView().frame(width: 0, height: 0) }
            .navigationTitle("Campus ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton(label: "Close Campus ID") { dismiss() }
                }
            }
        }
        .onDisappear { BrightnessManager.shared.deactivateBarcodeDisplay() }
    }
}

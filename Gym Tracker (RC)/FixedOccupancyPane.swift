import SwiftUI

/// The arrangement proposes the usable area above the fold, excluding the seam.
/// Keep this pane stationary and choose the readout density from that proposal.
struct FixedOccupancyPane<Occupancy: View>: View {
    @ViewBuilder let occupancy: (_ isCompact: Bool) -> Occupancy

    var body: some View {
        ViewThatFits(in: .vertical) {
            readouts(isCompact: false)
            readouts(isCompact: true)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("dashboard-occupancy-pane")
    }

    private func readouts(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            occupancy(isCompact)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

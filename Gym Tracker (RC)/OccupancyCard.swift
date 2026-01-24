import SwiftUI

struct OccupancyCard: View {
    let occupancy: Int
    let remaining: Int
    let maxCapacity: Int
    let segmentCount: Int
    @ObservedObject var networkMonitor: NetworkMonitor

    var percentageCapacity: CGFloat {
        CGFloat(occupancy) / CGFloat(maxCapacity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Display current occupancy and max capacity
                Text("\(occupancy.abbreviatedCount)")
                    .font(.subheadline)
                    .bold()
                +
                Text(" / \(maxCapacity.abbreviatedCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()

                // Display occupancy percentage
                HStack(spacing: 0) {
                    Text("\(Int(percentageCapacity * 100))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("%")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(" capacity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar for occupancy
            SegmentedProgressBar(
                height: 12,
                occupancyPercentage: percentageCapacity,
                totalSegments: segmentCount
            )
            .padding(.top, 2)
        }
        .grayscale(networkMonitor.isConnected ? 0 : 1) // Grey out when offline
        .opacity(networkMonitor.isConnected ? 1 : 0.5) // Dim view when offline
        .allowsHitTesting(networkMonitor.isConnected) // Disable interactions when offline
    }
}

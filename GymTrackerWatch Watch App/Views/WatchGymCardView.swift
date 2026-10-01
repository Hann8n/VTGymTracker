import SwiftUI

struct WatchGymCardView: View {
    let title: String
    let occupancy: Int
    let maxCapacity: Int
    let facilityId: String
    @ObservedObject var networkMonitor: WatchNetworkMonitor
    let color: Color
    
    private var occupancyPercentage: Double {
        WatchOccupancyMath.percent(occupancy: occupancy, maxCapacity: maxCapacity)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Segmented Circular Progress View (matching widget design)
            WatchCircularProgressView(
                percentage: occupancyPercentage,
                size: 120,
                lineWidth: 8,
                fontScale: 0.25,
                totalSegments: 20,
                isEmpty: occupancy == 0,
                showPercentageSymbol: true,
                occupancy: occupancy,
                maxCapacity: maxCapacity
            )
            
            // Occupancy numbers
            VStack(spacing: 4) {
                if networkMonitor.isConnected {
                    Text("\(occupancy.watchAbbreviatedCount) / \(maxCapacity.watchAbbreviatedCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Offline")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(occupancyBackgroundColor)
        .opacity(networkMonitor.isConnected ? 1.0 : 0.6)
    }
    
    private var occupancyBackgroundColor: Color {
        Color.black
    }
}

struct WatchGymCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WatchGymCardView(
                title: "War Memorial Hall",
                occupancy: 450,
                maxCapacity: 1200,
                facilityId: WatchGymConstants.warMemorialFacilityId,
                networkMonitor: WatchNetworkMonitor(),
                color: .green
            )
            .previewDisplayName("War Memorial - Moderate")
            
            WatchGymCardView(
                title: "McComas Hall",
                occupancy: 480,
                maxCapacity: 600,
                facilityId: WatchGymConstants.mcComasFacilityId,
                networkMonitor: WatchNetworkMonitor(),
                color: .blue
            )
            .previewDisplayName("McComas - Busy")
            
            WatchGymCardView(
                title: "Bouldering Wall",
                occupancy: 6,
                maxCapacity: 8,
                facilityId: WatchGymConstants.boulderingWallFacilityId,
                networkMonitor: WatchNetworkMonitor(),
                color: .orange
            )
            .previewDisplayName("Bouldering - Very Busy")
        }
    }
}

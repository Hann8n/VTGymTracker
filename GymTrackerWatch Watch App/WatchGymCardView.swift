import SwiftUI

struct WatchGymCardView: View {
    let title: String
    let occupancy: Int
    let maxCapacity: Int
    let facilityId: String
    @ObservedObject var networkMonitor: NetworkMonitor
    let color: Color
    
    private var occupancyPercentage: Double {
        guard maxCapacity > 0 else { return 0 }
        return (Double(occupancy) / Double(maxCapacity)) * 100.0
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
                    Text("\(occupancy) / \(maxCapacity)")
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
        if !networkMonitor.isConnected {
            return Color.black
        }
        
        switch occupancyPercentage {
        case 0:
            return Color.black
        case 0..<50:
            return Color("WatchCustomGreen").opacity(0.1)
        case 50..<75:
            return Color("WatchCustomOrange").opacity(0.1)
        default:
            return Color("WatchCustomMaroon").opacity(0.1)
        }
    }
}

struct WatchGymCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WatchGymCardView(
                title: "War Memorial Hall",
                occupancy: 450,
                maxCapacity: 1200,
                facilityId: Constants.warMemorialFacilityId,
                networkMonitor: NetworkMonitor(),
                color: .green
            )
            .previewDisplayName("War Memorial - Moderate")
            
            WatchGymCardView(
                title: "McComas Hall",
                occupancy: 480,
                maxCapacity: 600,
                facilityId: Constants.mcComasFacilityId,
                networkMonitor: NetworkMonitor(),
                color: .blue
            )
            .previewDisplayName("McComas - Busy")
            
            WatchGymCardView(
                title: "Bouldering Wall",
                occupancy: 6,
                maxCapacity: 8,
                facilityId: Constants.boulderingWallFacilityId,
                networkMonitor: NetworkMonitor(),
                color: .orange
            )
            .previewDisplayName("Bouldering - Very Busy")
        }
    }
}

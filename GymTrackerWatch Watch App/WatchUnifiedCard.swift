import SwiftUI

struct WatchUnifiedCard: View {
    let occupancy: Int
    let maxCapacity: Int
    let facilityId: String
    
    // Calculate occupancy percentage (0.0 to 1.0)
    private var occupancyPercentage: CGFloat {
        guard maxCapacity > 0 else { return 0 }
        return CGFloat(occupancy) / CGFloat(maxCapacity)
    }
    
    // Formatted occupancy percentage (e.g., "75%")
    private var occupancyPercentText: String {
        "\(Int(occupancyPercentage * 100))%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header row: current occupancy bold, "/" and max capacity in normal style
            HStack {
                (Text("\(occupancy)")
                    .fontWeight(.bold) // Bold current occupancy
                    + Text(" / \(maxCapacity)")
                    .foregroundColor(.secondary)
                )
                .font(.footnote)
                
                Spacer()
                
                Text(occupancyPercentText)
                    .font(.footnote)
                // Uses primary color by default
            }
            
            // Segmented progress bar reflecting occupancy
            WatchSegmentedProgressBar(occupancyPercentage: occupancyPercentage)
                .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}

struct WatchUnifiedCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WatchUnifiedCard(
                occupancy: 450,
                maxCapacity: 600,
                facilityId: Constants.mcComasFacilityId
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("McComas Hall")
            
            WatchUnifiedCard(
                occupancy: 1200,
                maxCapacity: 1200,
                facilityId: Constants.warMemorialFacilityId
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("War Memorial Hall")
        }
    }
}

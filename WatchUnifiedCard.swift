import SwiftUI

struct WatchUnifiedCard: View {
    let occupancy: Int
    let maxCapacity: Int
    let facilityId: String
    let defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))]
    let adjustedHours: [AdjustedHours]
    
    // Calculate occupancy percentage (0.0 to 1.0)
    private var occupancyPercentage: CGFloat {
        guard maxCapacity > 0 else { return 0 }
        return CGFloat(occupancy) / CGFloat(maxCapacity)
    }
    
    // Formatted occupancy percentage (e.g., "75%")
    private var occupancyPercentText: String {
        "\(Int(occupancyPercentage * 100))%"
    }
    
    // Fetch today's gym status using your helper
    private var gymStatus: GymStatus {
        GymStatusHelper.getTodayGymStatus(
            facilityId: facilityId,
            defaultHours: defaultHours,
            adjustedHours: adjustedHours,
            currentTime: Date()
        )
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
            
            // Single line showing open/closed status and next open/close info
            HStack {
                Text(gymStatus.isOpen ? "Open" : "Closed")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(gymStatus.isOpen ? .green : .red)
                
                Spacer()
                
                if gymStatus.isOpen,
                   let closingTime = gymStatus.status.components(separatedBy: "Until ").last {
                    Text("Until \(closingTime)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if !gymStatus.isOpen,
                          let statusDetail = gymStatus.status.components(separatedBy: "Opens").last {
                    Text("Opens\(statusDetail)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
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
                facilityId: Constants.mcComasFacilityId,
                defaultHours: Constants.mcComasHours,
                adjustedHours: mcComasSpring2025AdjustedHours
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("McComas Hall")
            
            WatchUnifiedCard(
                occupancy: 1200,
                maxCapacity: 1200,
                facilityId: Constants.warMemorialFacilityId,
                defaultHours: Constants.warMemorialHours,
                adjustedHours: warMemorialSpring2025AdjustedHours
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("War Memorial Hall")
        }
    }
}

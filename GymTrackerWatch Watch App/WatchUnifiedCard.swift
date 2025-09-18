import SwiftUI

struct WatchUnifiedCard: View {
    let title: String
    let occupancy: Int
    let maxCapacity: Int
    let facilityId: String
    let defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))]
    let adjustedHours: [AdjustedHours]
    
    // Calculate occupancy percentage from occupancy and maxCapacity
    private var occupancyPercentage: CGFloat {
        guard maxCapacity > 0 else { return 0 }
        return CGFloat(occupancy) / CGFloat(maxCapacity)
    }
    
    // Fetch today’s gym status using your helper
    private var gymStatus: GymStatus {
        GymStatusHelper.getTodayGymStatus(
            facilityId: facilityId,
            defaultHours: defaultHours,
            adjustedHours: adjustedHours,
            currentTime: Date()
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Title and occupancy count
            HStack {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.bold)
                Spacer()
                Text("\(occupancy)/\(maxCapacity)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            // Occupancy progress bar
            WatchSegmentedProgressBar(occupancyPercentage: occupancyPercentage)
                .frame(height: 4)
            
            // Single-line Hours/Status row: Open/Closed + Next open/close info
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
                title: "Occupancy",
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
                title: "Occupancy",
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

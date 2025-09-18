//
//  WatchSegmentedProgressBar.swift
//  Gym Tracker
//
//  Created by Jack on 1/30/25.
//

// WatchSegmentedProgressBar.swift
// Gym Tracker Watch App

import SwiftUI

struct WatchSegmentedProgressBar: View {
    let occupancyPercentage: CGFloat  // 0.0 to 1.0
    
    private let totalSegments = 12
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<totalSegments, id: \.self) { index in
                Rectangle()
                    .fill(colorForSegment(index: index))
                    .frame(height: 4)
            }
        }
    }
    
    // Determine the color for each segment based on occupancy
    private func colorForSegment(index: Int) -> Color {
        let segmentThreshold = CGFloat(index + 1) / CGFloat(totalSegments)
        if occupancyPercentage >= segmentThreshold {
            return progressColor(for: segmentThreshold)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    // Color logic similar to WatchProgressBar
    private func progressColor(for fraction: CGFloat) -> Color {
        switch fraction {
        case 0..<0.5:
            return Color("WatchCustomGreen")
        case 0.5..<0.75:
            return Color("WatchCustomOrange")
        default:
            return Color("WatchCustomMaroon")
        }
    }
}

struct WatchSegmentedProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WatchSegmentedProgressBar(occupancyPercentage: 0.3)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("30% Occupied")
            
            WatchSegmentedProgressBar(occupancyPercentage: 0.6)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("60% Occupied")
            
            WatchSegmentedProgressBar(occupancyPercentage: 0.9)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("90% Occupied")
        }
    }
}

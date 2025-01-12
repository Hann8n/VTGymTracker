//SegmentedProgressBar.swift
//

import SwiftUI

struct SegmentedProgressBar: View {
    var height: CGFloat                  // Controls the height of the segments
    var occupancyPercentage: CGFloat     // A value between 0.0 and 1.0 representing the progress
    
    // Private properties
    private let segmentSpacing: CGFloat = 4  // Spacing between segments
    private let totalSegments: Int = 20      // Total number of segments
    private let minimumBrightness: CGFloat = 0.3  // Minimum brightness (30% opacity) for partially filled segments

    // Track the previous occupancy value to detect if progress is increasing or decreasing
    @State private var previousOccupancyPercentage: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geo in
            // Calculate the width of each segment based on the total available width and spacing
            let segmentWidth = (geo.size.width - (CGFloat(totalSegments - 1) * segmentSpacing)) / CGFloat(totalSegments)
            
            // Ensure the occupancy percentage stays between 0 and 1
            let adjustedOccupancy = min(max(occupancyPercentage, 0), 1)
            
            ZStack(alignment: .leading) {
                // Background segments (static, non-animated)
                HStack(spacing: segmentSpacing) {
                    ForEach(0..<totalSegments, id: \.self) { index in
                        RoundedRectangle(cornerRadius: height / 4)
                            .fill(self.backgroundColor(for: index))
                            .frame(width: segmentWidth, height: height)
                    }
                }
                
                // Filled segments (animated, based on occupancyPercentage)
                HStack(spacing: segmentSpacing) {
                    ForEach(0..<totalSegments, id: \.self) { index in
                        RoundedRectangle(cornerRadius: height / 4)
                            .fill(self.foregroundColor(for: index))
                            .frame(width: segmentWidth, height: height)
                            .opacity(self.opacityForSegment(index: index, totalSegments: totalSegments, occupancyPercentage: adjustedOccupancy))
                            .animation(self.segmentAnimation(index: index), value: adjustedOccupancy)
                    }
                }
            }
        }
        .frame(height: height)
        .background(Color.clear)
        // Track initial value on appearance and update manually if needed
        .onAppear {
            previousOccupancyPercentage = occupancyPercentage
        }
        // Monitor occupancyPercentage change through property updates, not `onChange`
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if previousOccupancyPercentage != occupancyPercentage {
                previousOccupancyPercentage = occupancyPercentage
            }
        }
    }
    
    // Determines the animation style for each segment based on whether the progress is increasing or decreasing
    private func segmentAnimation(index: Int) -> Animation {
        let baseDuration = 0.6
        let segmentDelay = 0.05
        
        // Detect if progress is increasing or decreasing and apply appropriate delays for a sequential effect
        if occupancyPercentage > previousOccupancyPercentage {
            // Increasing: Apply a delay for each segment based on the index for a step effect
            return .easeIn(duration: baseDuration).delay(Double(index) * segmentDelay)
        } else {
            // Decreasing: Reverse the delay sequence for a step-back animation
            return .easeOut(duration: baseDuration).delay(Double(totalSegments - index - 1) * segmentDelay)
        }
    }
    
    // Determines the background color for a segment based on its index
    private func backgroundColor(for index: Int) -> Color {
        if index < 10 { // Green for the first 10 segments (50%)
            return Color.green.opacity(0.2)
        } else if index < 15 { // Orange for the next 5 segments (25%)
            return Color(red: 229/255, green: 117/255, blue: 31/255).opacity(0.2)
        } else { // Maroon for the final 5 segments (25%)
            return Color(red: 134/255, green: 31/255, blue: 65/255).opacity(0.2)
        }
    }
    
    // Determines the foreground (filled) color for a segment based on its index
    private func foregroundColor(for index: Int) -> Color {
        if index < 10 { // Green for the first 10 segments (50%)
            return Color.green
        } else if index < 15 { // Orange for the next 5 segments (25%)
            return Color(red: 229/255, green: 117/255, blue: 31/255)
        } else { // Maroon for the final 5 segments (25%)
            return Color(red: 134/255, green: 31/255, blue: 65/255)
        }
    }
    
    // Determines the opacity for each segment based on the progress
    private func opacityForSegment(index: Int, totalSegments: Int, occupancyPercentage: CGFloat) -> CGFloat {
        // Calculate the progress range for the current segment
        let segmentProgress = CGFloat(index) / CGFloat(totalSegments)
        let nextSegmentProgress = CGFloat(index + 1) / CGFloat(totalSegments)
        
        // Determine opacity based on how filled the segment is
        if occupancyPercentage >= nextSegmentProgress {
            // Fully filled segment
            return 1.0
        } else if occupancyPercentage > segmentProgress {
            // Partially filled segment, ensure it does not go below the minimum brightness
            let segmentFraction = (occupancyPercentage - segmentProgress) / (nextSegmentProgress - segmentProgress)
            return max(segmentFraction, minimumBrightness)
        } else {
            // Not filled segment
            return 0.0
        }
    }
}

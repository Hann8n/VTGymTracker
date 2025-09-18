//
//  GymComplicationView.swift
//  Gym Tracker
//
//  Created by Jack on 1/31/25.
//

import SwiftUI

/// Draws a circular segmented arc representing occupancy.
/// Each segment is drawn as a small arc. Filled segments use a progress color;
/// empty segments are shown in a light gray.
struct SegmentedArcView: View {
    let occupancyPercentage: CGFloat  // Expected between 0.0 and 1.0
    
    private let totalSegments: Int = 10
    private let gapDegrees: Double = 2    // gap between segments in degrees
    private let lineWidth: CGFloat = 8    // thickness of the arc
    
    /// Determines the color for a given segment index.
    private func colorForSegment(index: Int) -> Color {
        let segmentThreshold = CGFloat(index + 1) / CGFloat(totalSegments)
        if occupancyPercentage >= segmentThreshold {
            return progressColor(for: segmentThreshold)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    /// Uses the same logic as your existing code to pick a progress color.
    private func progressColor(for fraction: CGFloat) -> Color {
        switch fraction {
        case 0..<0.5:
            return .green
        case 0.5..<0.75:
            return Color(red: 229/255, green: 117/255, blue: 31/255) // customOrange
        default:
            return Color(red: 134/255, green: 31/255, blue: 65/255)  // customMaroon
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - lineWidth / 2
            ZStack {
                ForEach(0..<totalSegments, id: \.self) { index in
                    // Each segment spans an equal portion of the full circle.
                    let segmentAngle = 360.0 / Double(totalSegments)
                    // Apply a small gap at the start and end of each segment.
                    let startAngle = Double(index) * segmentAngle + gapDegrees / 2
                    let endAngle = Double(index + 1) * segmentAngle - gapDegrees / 2
                    
                    Path { path in
                        path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                                    radius: radius,
                                    startAngle: Angle(degrees: startAngle),
                                    endAngle: Angle(degrees: endAngle),
                                    clockwise: false)
                    }
                    .stroke(colorForSegment(index: index),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            }
        }
    }
}

/// A complication view for a gym that shows a clock-face–style design with
/// a segmented occupancy bar curving around the edge and the occupancy percentage above.
struct GymComplicationView: View {
    let occupancy: Int
    let maxCapacity: Int
    
    /// Calculate occupancy percentage.
    private var occupancyPercentage: CGFloat {
        maxCapacity > 0 ? CGFloat(occupancy) / CGFloat(maxCapacity) : 0
    }
    
    /// Formats the occupancy percentage as a percentage string.
    private var occupancyPercentText: String {
        "\(Int(occupancyPercentage * 100))%"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Display the percentage above the clock face.
            Text(occupancyPercentText)
                .font(.caption)
                .fontWeight(.bold)
            
            ZStack {
                // The segmented arc appears as a border around the clock face.
                SegmentedArcView(occupancyPercentage: occupancyPercentage)
                
                // The center "clock face" can be a simple circle.
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    // Adjust the size so the segmented arc is clearly visible.
                    .padding(16)
            }
        }
        // Overall size for the complication.
        .frame(width: 120, height: 140)
    }
}

struct GymComplicationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GymComplicationView(occupancy: 450, maxCapacity: 600)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("McComas Hall")
            
            GymComplicationView(occupancy: 1200, maxCapacity: 1200)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("War Memorial Hall")
        }
    }
}

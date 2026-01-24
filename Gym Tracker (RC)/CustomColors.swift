//
//  CustomColors.swift
//  Gym Tracker
//
//  Created by Jack on 1/19/25.
//
import SwiftUI

// MARK: - Color System
// Note: Brand colors (customOrange, customMaroon, customGreen) and semantic colors 
// (cardBackground, secondaryBackground, borderColor) are automatically generated 
// by Xcode from the Asset Catalog and available as Color.customOrange, Color.cardBackground, etc.

extension Color {
    // MARK: - Progress/Status Colors
    /// Returns appropriate color based on occupancy percentage
    /// - Parameter percentage: Value between 0.0 and 1.0
    /// - Returns: Green for low, orange for medium, maroon for high occupancy
    static func occupancyColor(for percentage: CGFloat) -> Color {
        switch percentage {
        case 0..<0.5:
            return Color("CustomGreen")
        case 0.5..<0.75:
            return Color("CustomOrange")
        default:
            return Color("CustomMaroon")
        }
    }
    
    /// Returns appropriate color for segment-based progress indicators
    /// - Parameters:
    ///   - segmentIndex: Current segment index
    ///   - totalSegments: Total number of segments
    /// - Returns: Appropriate color for the segment position
    static func segmentColor(index: Int, totalSegments: Int) -> Color {
        let fraction = CGFloat(index + 1) / CGFloat(totalSegments)
        return occupancyColor(for: fraction)
    }
}

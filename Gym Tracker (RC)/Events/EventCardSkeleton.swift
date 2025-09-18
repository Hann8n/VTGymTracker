//
//  EventCardSkeleton.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import SwiftUI

struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title Placeholder
            ShimmerView()
                .frame(height: 20)
                .cornerRadius(4)
                .padding(.trailing, 200) // Adjust as needed

            // Date Placeholder
            ShimmerView()
                .frame(height: 16)
                .cornerRadius(4)
                .padding(.trailing, 150) // Adjust as needed

            // Location Placeholder
            ShimmerView()
                .frame(height: 16)
                .cornerRadius(4)
                .padding(.trailing, 180) // Adjust as needed
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.leading, 30)
    }
}

struct EventCardSkeleton_Previews: PreviewProvider {
    static var previews: some View {
        EventCardSkeleton()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

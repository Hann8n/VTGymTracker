//
//  EventCardSkeleton.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import SwiftUI

struct EventCardSkeleton: View {
    var body: some View {
        HStack(alignment: .center, spacing: EventCard.leadingColumnSpacing) {
            VStack(spacing: 4) {
                ShimmerView()
                    .frame(width: EventCard.leadingColumnWidth, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                ShimmerView()
                    .frame(width: EventCard.leadingColumnWidth * 0.6, height: 10)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            }
            .frame(width: EventCard.leadingColumnWidth)

            VStack(alignment: .leading, spacing: 8) {
                ShimmerView()
                    .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.72
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                ShimmerView()
                    .frame(maxWidth: .infinity, minHeight: 14, maxHeight: 14)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.44
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 44, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventCardSkeleton_Previews: PreviewProvider {
    static var previews: some View {
        EventCardSkeleton()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

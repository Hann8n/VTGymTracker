//
//  EventCardSkeleton.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import SwiftUI

/// Loading placeholder shaped like an `EventDayGroup` with a single event.
struct EventCardSkeleton: View {
    var body: some View {
        HStack(alignment: .center, spacing: EventDayGroup.columnSpacing) {
            VStack(spacing: 5) {
                bar(width: EventDayGroup.dateColumnWidth * 0.6, height: 9)
                bar(width: EventDayGroup.dateColumnWidth * 0.75, height: 24)
                bar(width: EventDayGroup.dateColumnWidth * 0.55, height: 9)
            }
            .frame(width: EventDayGroup.dateColumnWidth)

            VStack(alignment: .leading, spacing: 8) {
                ShimmerView()
                    .frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.62
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                ShimmerView()
                    .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.36
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, DashboardLayout.horizontalGutter)
        .padding(.trailing, DashboardLayout.horizontalGutter)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        ShimmerView()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }
}

struct EventCardSkeleton_Previews: PreviewProvider {
    static var previews: some View {
        EventCardSkeleton()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

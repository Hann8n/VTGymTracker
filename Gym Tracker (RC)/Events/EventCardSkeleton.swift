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
                placeholder
                    .frame(height: 16)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.62
                    }

                placeholder
                    .frame(height: 12)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.36
                    }
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
        placeholder
            .frame(width: width, height: height)
    }

    /// Static, unanimated block in the same neutral gray as an empty `SegmentedProgressBar`.
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.gray.opacity(0.2))
    }
}

struct EventCardSkeleton_Previews: PreviewProvider {
    static var previews: some View {
        EventCardSkeleton()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

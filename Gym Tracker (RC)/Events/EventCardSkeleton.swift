//
//  EventCardSkeleton.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import SwiftUI

struct EventCardSkeleton: View {
    private let thumbnailSize: CGFloat = 70

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ShimmerView()
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                ShimmerView()
                    .frame(width: 128, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                ShimmerView()
                    .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.78
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                ShimmerView()
                    .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.52
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ShimmerView()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(width: 44, height: 44)
        }
        .frame(minHeight: thumbnailSize, alignment: .center)
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

import SwiftUI

struct FacilityOccupancyCard: View {
    let facilityTitle: String
    let occupancy: Int
    let maxCapacity: Int
    let segmentCount: Int
    @ObservedObject var networkMonitor: NetworkMonitor
    let motionPolicy: MotionPolicy

    private var occupancyRatio: CGFloat {
        CGFloat(OccupancyMath.fraction(occupancy: occupancy, maxCapacity: maxCapacity))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(facilityTitle.uppercased())
                .font(.caption.weight(.bold))
                .fontWidth(.condensed)
                .foregroundStyle(.secondary)
                .tracking(0.9)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 3)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Group {
                        if motionPolicy.reduceMotion {
                            Text(occupancy.abbreviatedCount)
                        } else {
                            Text(occupancy.abbreviatedCount)
                                .contentTransition(.numericText(value: Double(occupancy)))
                        }
                    }
                    .font(.system(size: 40, weight: .black, design: .default))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                    Text("/ \(maxCapacity.abbreviatedCount)")
                        .font(.body.weight(.medium))
                        .fontWidth(.condensed)
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 8)

                Text("\(OccupancyMath.wholePercent(occupancy: occupancy, maxCapacity: maxCapacity))%")
                    .font(.subheadline.weight(.semibold))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .animation(motionPolicy.updateAnimation, value: occupancy)

            SegmentedProgressBar(
                height: 6,
                occupancyPercentage: occupancyRatio,
                totalSegments: min(segmentCount, 14)
            )
            .padding(.top, 4)
            .animation(motionPolicy.updateAnimation, value: occupancy)
        }
        .padding(.horizontal, DashboardLayout.horizontalGutter)
        .padding(.top, DashboardLayout.horizontalGutter)
        .padding(.bottom, DashboardLayout.cardVerticalPadding)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .dashboardCardChrome(networkMonitor: networkMonitor)
    }
}


//OccupancyCard.swift
//

import SwiftUI

struct OccupancyCard: View {
    let occupancy: Int
    let remaining: Int
    let maxCapacity: Int
    @ObservedObject var networkMonitor: NetworkMonitor

    @State private var isLiveVisible: Bool = true
    @State private var timer: Timer?

    var percentageCapacity: CGFloat {
        CGFloat(occupancy) / CGFloat(maxCapacity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Combine current occupancy and max capacity in a single Text to control spacing
                Text("\(occupancy)")
                    .font(.subheadline)
                    .bold()  // Bold only the current value
                +
                Text(" / \(maxCapacity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)  // Match color and keep unbolded
                
                Spacer()

                // Occupancy percentage and "%" with matching color to "Capacity"
                HStack(spacing: 0) {
                    Text("\(Int(percentageCapacity * 100))")
                        .font(.subheadline)
                        .foregroundColor(.primary)  // Match color to "Capacity"
                    Text("%")
                        .font(.subheadline)
                        .foregroundColor(.primary)  // Match color to "Capacity"
                    Text(" capacity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)  // Secondary color for "Capacity" label
                }

                // Indicator dot without "LIVE" text
                if networkMonitor.isConnected {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .opacity(isLiveVisible ? 0.7 : 0.5)  // Reduced travel, subtler effect
                        .onAppear {
                            startLiveIndicatorAnimation()
                        }
                        .onDisappear {
                            stopLiveIndicatorAnimation()
                        }
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 10, height: 10)
                        .opacity(0.5)  // Dim gray dot for "OFFLINE"
                        .onAppear {
                            stopLiveIndicatorAnimation()  // Stop animation when offline
                        }
                }
            }

            // Progress Bar showing the percentage of occupancy
            SegmentedProgressBar(
                height: 12,
                occupancyPercentage: percentageCapacity
            )
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
        .padding(.horizontal)
        .background(Color.clear)
        .cornerRadius(8)
    }

    // Helper functions to manage the live indicator animation
    private func startLiveIndicatorAnimation() {
        stopLiveIndicatorAnimation()  // Ensure no existing timer is running
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {  // Slower and smoother easing
                isLiveVisible.toggle()
            }
        }
    }

    private func stopLiveIndicatorAnimation() {
        timer?.invalidate()
        timer = nil
        isLiveVisible = true  // Reset to visible when stopping the animation
    }
}

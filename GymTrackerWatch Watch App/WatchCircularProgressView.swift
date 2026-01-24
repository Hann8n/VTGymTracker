import SwiftUI

// MARK: - Watch Circular Progress Components (matching widget design)
struct WatchCircularProgressView: View {
    let percentage: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let fontScale: CGFloat
    let totalSegments: Int
    var segmentSpacing: Double = 2.0
    let isEmpty: Bool
    let showPercentageSymbol: Bool
    let occupancy: Int
    let maxCapacity: Int

    private var segmentAngle: Double {
        (360.0 / Double(totalSegments)) - segmentSpacing
    }

    var body: some View {
        ZStack {
            // Background segments (tinted track: segment color 0.28, empty 0.22)
            ForEach(0..<totalSegments, id: \.self) { index in
                WatchSegmentShape(
                    startAngle: segmentStartAngle(for: index),
                    endAngle: segmentStartAngle(for: index) + segmentAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(isEmpty ? Color.gray.opacity(0.20) : segmentColor(index).opacity(0.20))
            }
            
            // Foreground segments
            ForEach(0..<totalSegments, id: \.self) { index in
                WatchSegmentShape(
                    startAngle: segmentStartAngle(for: index),
                    endAngle: segmentStartAngle(for: index) + segmentAngle,
                    lineWidth: lineWidth
                )
                .stroke(lineWidth: lineWidth)
                .foregroundColor(isEmpty ? Color.gray : segmentColor(index))
                .opacity(opacityForSegment(index: index, adjustedPercentage: percentage / 100.0))
                .animation(.easeInOut(duration: 0.6), value: percentage)
            }

            // Percentage Text
            Text(String(format: "%.0f%@", percentage, showPercentageSymbol ? "%" : ""))
                .font(.system(size: size * fontScale, weight: .bold))
                .foregroundColor(isEmpty ? Color.gray : .primary)
        }
        .frame(width: size, height: size)
    }

    private func segmentStartAngle(for index: Int) -> Double {
        (Double(index) * (segmentAngle + segmentSpacing)) - 90
    }

    private func segmentColor(_ index: Int) -> Color {
        index < totalSegments / 2 ? Color("WatchCustomGreen") :
        index < (totalSegments * 3) / 4 ? Color("WatchCustomOrange") : Color("WatchCustomMaroon")
    }

    private func opacityForSegment(index: Int, adjustedPercentage: Double) -> Double {
        let segmentProgress = Double(index) / Double(totalSegments)
        let nextSegmentProgress = Double(index + 1) / Double(totalSegments)

        if adjustedPercentage >= nextSegmentProgress {
            return 1.0
        } else if adjustedPercentage > segmentProgress {
            return (adjustedPercentage - segmentProgress) / (nextSegmentProgress - segmentProgress)
        }
        return 0.0
    }
}

struct WatchSegmentShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - (lineWidth / 2)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: endAngle),
            clockwise: false
        )
        return path
    }
}

struct WatchCircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WatchCircularProgressView(
                percentage: 37.5,
                size: 120,
                lineWidth: 8,
                fontScale: 0.25,
                totalSegments: 20,
                isEmpty: false,
                showPercentageSymbol: true,
                occupancy: 450,
                maxCapacity: 1200
            )
            .previewDisplayName("37.5% - Moderate")
            
            WatchCircularProgressView(
                percentage: 80.0,
                size: 120,
                lineWidth: 8,
                fontScale: 0.25,
                totalSegments: 20,
                isEmpty: false,
                showPercentageSymbol: true,
                occupancy: 480,
                maxCapacity: 600
            )
            .previewDisplayName("80% - Busy")
            
            WatchCircularProgressView(
                percentage: 0.0,
                size: 120,
                lineWidth: 8,
                fontScale: 0.25,
                totalSegments: 20,
                isEmpty: true,
                showPercentageSymbol: true,
                occupancy: 0,
                maxCapacity: 1200
            )
            .previewDisplayName("0% - Empty")
        }
        .padding()
    }
}

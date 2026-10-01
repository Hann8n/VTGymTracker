import SwiftUI

// MARK: - WatchRootView

/// Native pager: barcode | gyms (default) | events.
struct WatchRootView: View {
    @StateObject private var gymService = WatchGymService.shared
    @StateObject private var networkMonitor = WatchNetworkMonitor()
    @State private var selection = 1

    var body: some View {
        TabView(selection: $selection) {
            Text("Barcode")
                .tag(0)
            gymsPage
                .tag(1)
            Text("Events")
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onAppear {
            Task {
                if networkMonitor.isConnected {
                    await gymService.fetchAllGymOccupancy()
                }
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, newValue in
            if newValue {
                Task { await gymService.fetchAllGymOccupancy() }
            }
        }
    }

    // MARK: - Gyms page (mirrors SmallWidgetView 1:1)

    private var gymsPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            gymRow(
                title: "War Memorial",
                occupancy: gymService.warMemorialOccupancy ?? 0,
                maxCapacity: WatchGymConstants.warMemorialMaxCapacity,
                totalSegments: 20
            )
            Spacer(minLength: 0)
            Divider()
            Spacer(minLength: 0)
            gymRow(
                title: "McComas",
                occupancy: gymService.mcComasOccupancy ?? 0,
                maxCapacity: WatchGymConstants.mcComasMaxCapacity,
                totalSegments: 20
            )
            Spacer(minLength: 0)
            Divider()
            Spacer(minLength: 0)
            gymRow(
                title: "Bouldering Wall",
                occupancy: gymService.boulderingWallOccupancy ?? 0,
                maxCapacity: WatchGymConstants.boulderingWallMaxCapacity,
                totalSegments: 8
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .safeAreaPadding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gymRow(title: String, occupancy: Int, maxCapacity: Int, totalSegments: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            WatchCircularProgressView(
                percentage: WatchOccupancyMath.percent(occupancy: occupancy, maxCapacity: maxCapacity),
                size: 42,
                lineWidth: 5,
                fontScale: 0.3,
                totalSegments: totalSegments,
                isEmpty: occupancy == 0,
                showPercentageSymbol: false,
                occupancy: occupancy,
                maxCapacity: maxCapacity
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                (Text("\(occupancy.watchAbbreviatedCount)")
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    + Text(" / \(maxCapacity.watchAbbreviatedCount)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

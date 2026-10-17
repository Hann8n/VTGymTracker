// swift-tools-version: 5.9
import PackageDescription

// Small host-side contract suite; no simulator or third-party dependency required.
let package = Package(
    name: "GymCrowds",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10)],
    products: [.library(name: "GymCrowds", targets: ["GymCrowds"])],
    targets: [
        .target(name: "GymCrowds", path: "Gym Tracker (RC)", exclude: [
            "Ads/AdView.swift", "Ads/AdViewModel.swift",
            "SegmentedProgressBar.swift",
            "SettingsView.swift", "Settings.bundle",
            "DashboardLayout.swift",
            "BarCode Scanner",
            "MotionPolicy.swift",
            "Assets.xcassets",
            "AppInfo.swift",
            "CustomColors.swift",
            "FacilityOccupancyCard.swift",
            "Preview Content",
            "Gym_Tracker__RC_.entitlements",
            "Gym_Tracker__RC_App.swift",
            "AppIcon.icon",
            "Alerts.swift",
            "Components",
            "DashboardSectionHeader.swift",
            "GymTrackerWidgetExtension.entitlements",
            "Events/EventCard.swift", "Events/EventDateTile.swift", "Events/EventsSectionBlock.swift",
            "Events/EventsViewModel.swift", "Events/EventDayGroup.swift", "Events/EventRowButtonStyle.swift",
            "ContentView.swift",
            "DashboardScrollContainer.swift",
            "PrivacyPolicyView.swift", "PrivacyInfo.xcprivacy",
            "Services/GymFacility.swift",
            "Services/AuthenticationService.swift",
            "Services/WarningManager.swift",
            "Services/WebView.swift",
            "Services/UnifiedGymTrackerProvider.swift",
            "Services/GymService.swift",
            "Services/NetworkMonitor.swift"
        ], sources: [
            "Services/AppMetrics.swift", "Services/MetricEvent.swift", "Ads/AdConfig.swift", "Ads/AdService.swift",
            "Services/CrowdDataStatus.swift", "Services/Constants.swift", "Services/TrackedFacility.swift", "Services/OccupancySnapshot.swift",
            "Services/OccupancySnapshotStore.swift", "Services/OccupancyHTMLParser.swift",
            "Services/GymOccupancyFetcher.swift", "Services/CrowdsService.swift", "Services/CrowdsDialog.swift", "Intents",
            "Events/Event.swift", "Events/CampusGroupsEventsParser.swift", "Events/ParsedEventsFeed.swift",
            "Events/EventsDataStatus.swift", "Events/EventsSnapshot.swift", "Events/EventsCacheStore.swift",
            "Events/EventsService.swift", "Events/EventsSelection.swift", "Events/EventsDialog.swift"
        ]),
        .testTarget(name: "CrowdsTests", dependencies: ["GymCrowds"], path: "Tests/CrowdsTests"),
        .testTarget(name: "EventsTests", dependencies: ["GymCrowds"], path: "Tests/EventsTests")
    ]
)

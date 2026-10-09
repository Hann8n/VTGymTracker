// swift-tools-version: 5.9
import PackageDescription

// Small host-side contract suite; no simulator or third-party dependency required.
let package = Package(
    name: "GymCrowds",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10)],
    products: [.library(name: "GymCrowds", targets: ["GymCrowds"])],
    targets: [
        .target(name: "GymCrowds", path: "Gym Tracker (RC)", exclude: [
            "Ads",
            "SegmentedProgressBar.swift",
            "SettingsView.swift",
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
            "Events",
            "ContentView.swift",
            "DashboardScrollContainer.swift",
            "PrivacyPolicyView.swift",
            "Services/GymFacility.swift",
            "Services/AuthenticationService.swift",
            "Services/WarningManager.swift",
            "Services/WebView.swift",
            "Services/UnifiedGymTrackerProvider.swift",
            "Services/GymService.swift",
            "Services/NetworkMonitor.swift"
        ], sources: [
            "Services/CrowdDataStatus.swift", "Services/Constants.swift", "Services/TrackedFacility.swift", "Services/OccupancySnapshot.swift",
            "Services/OccupancySnapshotStore.swift", "Services/OccupancyHTMLParser.swift",
            "Services/GymOccupancyFetcher.swift", "Services/CrowdsService.swift", "Services/CrowdsDialog.swift", "Intents"
        ]),
        .testTarget(name: "CrowdsTests", dependencies: ["GymCrowds"], path: "Tests/CrowdsTests")
    ]
)

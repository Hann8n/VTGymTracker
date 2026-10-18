import SwiftUI
import AVFoundation
import Combine

struct ContentView: View {
    // MARK: - State Objects and Dependencies
    @StateObject private var networkMonitor: NetworkMonitor
    @StateObject private var eventsViewModel: EventsViewModel
    @StateObject private var adViewModel = AdViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject var alertManager: AlertManager
    @ObservedObject private var gymService = GymService.shared

    // MARK: - State Variables
    @State private var isLoading: Bool = false
    @State private var isScannerPresented: Bool = false
    @State private var isBarcodeDisplayPresented: Bool = false
    @State private var showManualInput: Bool = false
    @State private var showAddIDChoice: Bool = false
    @State private var showAboutPopup: Bool = false
    @State private var showSettingsPopup: Bool = false
    
    @AppStorage("appTheme") private var appTheme: String = "Auto"
    @AppStorage("faceIDEnabled") private var faceIDEnabled: Bool = false
    @AppStorage("gymBarcode") private var scannedBarcode: String = ""
    #if DEBUG
    @AppStorage("sponsoredAdsEnabled") private var sponsoredAdsEnabled: Bool = true
    @AppStorage("adPreviewTier") private var adPreviewTier: String = "production"
    #else
    // The preview toggle is a development preference, not a release feature switch.
    // Existing debug installs share preferences with TestFlight and App Store builds.
    private let sponsoredAdsEnabled = true
    #endif
    
    // MARK: - Initializer
    init() {
        let networkMonitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: networkMonitor)
        _eventsViewModel = StateObject(wrappedValue: EventsViewModel(networkMonitor: networkMonitor))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            NavigationStack {
                mainListView
                    .onAppear {
                        Task { await AppMetrics.shared.activate() }
                        #if DEBUG
                        if adPreviewTier == "gist" {
                            adPreviewTier = "production"
                        }
                        #endif
                        scheduleAppRefresh()
                        Task {
                            if networkMonitor.isConnected {
                                await fetchGymOccupancyData()
                            }
                            eventsViewModel.fetchEvents()
                            if sponsoredAdsEnabled {
                                #if DEBUG
                                await adViewModel.loadAd(previewTier: adPreviewTier)
                                #else
                                await adViewModel.loadAd(previewTier: nil)
                                #endif
                            }
                        }
                    }
                .sheet(isPresented: $isScannerPresented) {
                    BarcodeScannerView(isPresented: $isScannerPresented)
                        .environmentObject(alertManager)
                }
                .sheet(isPresented: $showManualInput) {
                    ManualIDInputView(isPresented: $showManualInput)
                        .environmentObject(alertManager)
                }
                .sheet(isPresented: $isBarcodeDisplayPresented) {
                    CampusIDSheet()
                }
                .sheet(isPresented: $showSettingsPopup) {
                    SettingsView()
                        .onAppear { Task { await AppMetrics.shared.track(.settingsOpen) } }
                        .environmentObject(alertManager)
                }
                .alert(item: $alertManager.currentAlert) { alertType in
                    alertType.generateAlert(openSettings: {
                        UIApplication.shared.openSettings()
                    })
                }
                .onChange(of: isBarcodeDisplayPresented) { _, presented in
                    if presented { Task { await AppMetrics.shared.track(.passportOpen) } }
                }
                .onChange(of: networkMonitor.isConnected) { _, newValue in
                    if newValue {
                        Task {
                            await fetchGymOccupancyData()
                            if sponsoredAdsEnabled {
                                #if DEBUG
                                await adViewModel.loadAd(previewTier: adPreviewTier)
                                #else
                                await adViewModel.loadAd(previewTier: nil)
                                #endif
                            }
                        }
                    }
                }
                #if DEBUG
                .onChange(of: adPreviewTier) { _, _ in
                    if sponsoredAdsEnabled {
                        Task { await adViewModel.loadAd(previewTier: adPreviewTier) }
                    }
                }
                #endif
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        Task { await AppMetrics.shared.enterBackground() }
                        isBarcodeDisplayPresented = false
                    case .inactive:
                        isBarcodeDisplayPresented = false
                    case .active:
                        Task { await AppMetrics.shared.activate() }
                        if sponsoredAdsEnabled {
                            Task {
                                #if DEBUG
                                await adViewModel.loadAd(previewTier: adPreviewTier)
                                #else
                                await adViewModel.loadAd(previewTier: nil)
                                #endif
                            }
                        }
                    @unknown default:
                        break
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("")
                .toolbar {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        campusIDToolbar
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showSettingsPopup.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                        }
                        .controlSize(.regular)
                        .accessibilityLabel("Settings")
                    }
                }
            }
        }
        .preferredColorScheme(appTheme == "Light" ? .light : appTheme == "Dark" ? .dark : nil)
    }
    
    // MARK: - Main List & Sections
    private var mainListView: some View {
        DashboardContentLayout {
            Text("Gym Tracker")
                .font(.largeTitle.weight(.bold))
                .fontWidth(.condensed)
                .tracking(-0.5)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DashboardLayout.horizontalGutter)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
                .id("dashboard-title")
        } occupancy: { isCompact in
            warMemorialSection(isCompact: isCompact)
                .id("dashboard-war-memorial")
            mcComasSection(isCompact: isCompact)
                .id("dashboard-mccomas")
            boulderingWallSection(isCompact: isCompact)
                .id("dashboard-bouldering")
        } events: { isSeparatePane in
            VStack(alignment: .leading, spacing: 0) {
                sponsoredSection(isSeparatePane: isSeparatePane)
                EventsSectionBlock(
                    eventsViewModel: eventsViewModel,
                    networkMonitor: networkMonitor,
                    motionPolicy: motionPolicy,
                    isSeparatePane: isSeparatePane && !hasActiveSponsoredAd
                )
                .staggeredAppear(index: 4, motionPolicy: motionPolicy)
                .id("dashboard-events")
            }
            .animation(motionPolicy.sponsorSectionLayoutAnimation, value: sponsoredSectionLayoutToken)
        }
    }

    private var hasActiveSponsoredAd: Bool {
        sponsoredAdsEnabled && adViewModel.loadedAd?.config.isCurrentlyActive == true
    }

    /// Drives smooth reflow of sections below the fold when the sponsor block mounts/unmounts or toggles.
    private var sponsoredSectionLayoutToken: String {
        if sponsoredAdsEnabled, let ad = adViewModel.loadedAd {
            return "on-\(ad.config.id)"
        }
        return "off"
    }

    private var motionPolicy: MotionPolicy {
        MotionPolicy(reduceMotion: reduceMotion)
    }

    private func warMemorialSection(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FacilityOccupancyCard(
                facilityTitle: "War Memorial Hall",
                occupancy: gymService.warMemorialOccupancy,
                maxCapacity: Constants.warMemorialMaxCapacity,
                segmentCount: 20,
                networkMonitor: networkMonitor,
                motionPolicy: motionPolicy,
                isCompact: isCompact
            )
            FullBleedDivider()
        }
        .staggeredAppear(index: 0, motionPolicy: motionPolicy)
    }

    private func mcComasSection(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FacilityOccupancyCard(
                facilityTitle: "McComas Hall",
                occupancy: gymService.mcComasOccupancy,
                maxCapacity: Constants.mcComasMaxCapacity,
                segmentCount: 20,
                networkMonitor: networkMonitor,
                motionPolicy: motionPolicy,
                isCompact: isCompact
            )
            FullBleedDivider()
        }
        .staggeredAppear(index: 1, motionPolicy: motionPolicy)
    }

    private func boulderingWallSection(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FacilityOccupancyCard(
                facilityTitle: "Bouldering Wall",
                occupancy: gymService.boulderingWallOccupancy,
                maxCapacity: Constants.boulderingWallMaxCapacity,
                segmentCount: 8,
                networkMonitor: networkMonitor,
                motionPolicy: motionPolicy,
                isCompact: isCompact
            )
        }
        .staggeredAppear(index: 2, motionPolicy: motionPolicy)
    }

    private func sponsoredSection(isSeparatePane: Bool) -> some View {
        Group {
            if let loadedAd = adViewModel.loadedAd, sponsoredAdsEnabled, loadedAd.config.isCurrentlyActive {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        DashboardSectionHeader(
                            title: loadedAd.config.sponsor,
                            subtitle: loadedAd.config.sponsoredLabel,
                            leadingLogo: loadedAd.logoImage
                        )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        AdView(
                            ad: loadedAd.config,
                            heroImage: loadedAd.heroImage,
                            isOccluded: isScannerPresented || showManualInput || showSettingsPopup || isBarcodeDisplayPresented || showAddIDChoice,
                            networkMonitor: networkMonitor
                        )
                    }
                    .padding(.top, isSeparatePane ? 0 : DashboardLayout.cardVerticalPadding)
                }
                .id("dashboard-sponsored")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .transition(motionPolicy.transition)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchGymOccupancyData() async {
        await gymService.fetchAllGymOccupancy()
    }
    
    // MARK: - Toolbar Button Methods
    
    @ToolbarContentBuilder
    private var campusIDToolbar: some ToolbarContent {
        if #available(iOS 27.1, *) {
            ToolbarItem(placement: .bottomBar) {
                campusIDButton
            }
            .axisBehavior(.verticalPreferred)
            .visibilityPriority(.high)
        } else {
            ToolbarItem(placement: .bottomBar) {
                campusIDButton
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    private var campusIDButton: some View {
        Button(action: handlePassportButtonTapped) {
            Label(
                scannedBarcode.isEmpty ? "Add Campus ID" : "Show ID",
                systemImage: scannedBarcode.isEmpty ? "plus.circle.fill" : "barcode"
            )
        }
        .controlSize(.regular)
        .confirmationDialog("Add Campus ID", isPresented: $showAddIDChoice, titleVisibility: .visible) {
            Button("Scan Barcode") {
                showAddIDChoice = false
                isScannerPresented = true
            }
            Button("Enter ID Number") {
                showAddIDChoice = false
                showManualInput = true
            }
            Button("Cancel", role: .cancel) {
                showAddIDChoice = false
            }
        } message: {
            Text("Scan barcode or enter your ID number.")
        }
    }

    private func handlePassportButtonTapped() {
        if scannedBarcode.isEmpty {
            showAddIDChoice = true
        } else {
            // Face ID is optional; user preference determines if authentication is required
            if faceIDEnabled {
                Task {
                    let success = await AuthenticationService.shared.authenticate(reason: "Authenticate to view your Campus ID.")
                    if success {
                        isBarcodeDisplayPresented = true
                    }
                    // Silently fail if authentication is cancelled or fails
                }
            } else {
                isBarcodeDisplayPresented = true
            }
        }
    }
    
    // Camera access is required for barcode scanning; must request permission if not granted
    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isScannerPresented = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isScannerPresented = true
                    } else {
                        alertManager.showAlert(.cameraAccessDenied)
                    }
                }
            }
        case .denied, .restricted:
            alertManager.showAlert(.cameraAccessDenied)
        @unknown default:
            alertManager.showAlert(.cameraAccessDenied)
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AlertManager())
            .preferredColorScheme(.light)
    }
}

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
    @AppStorage("sponsoredAdsEnabled") private var sponsoredAdsEnabled: Bool = true
    #if DEBUG
    @AppStorage("adPreviewTier") private var adPreviewTier: String = "gist"
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
                .sheet(isPresented: $showSettingsPopup) {
                    SettingsView()
                        .environmentObject(alertManager)
                }
                .alert(item: $alertManager.currentAlert) { alertType in
                    alertType.generateAlert(openSettings: {
                        UIApplication.shared.openSettings()
                    })
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
                    case .inactive, .background:
                        isBarcodeDisplayPresented = false
                    case .active:
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
                        ToolbarItem(placement: .bottomBar) {
                            Button(action: handlePassportButtonTapped) {
                                HStack(spacing: 6) {
                                    Image(systemName: scannedBarcode.isEmpty ? "plus.circle.fill" : "barcode")
                                    Text(scannedBarcode.isEmpty ? "Add Campus ID" : "Show ID")
                                }
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
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showSettingsPopup.toggle() }) {
                            Image(systemName: "gearshape.fill")
                        }
                        .controlSize(.regular)
                        .accessibilityLabel("Settings")
                    }
                }
            }
            if isBarcodeDisplayPresented {
                BarcodeDisplayOverlayView(isPresented: $isBarcodeDisplayPresented)
            }
        }
        .preferredColorScheme(appTheme == "Light" ? .light : appTheme == "Dark" ? .dark : nil)
    }
    
    // MARK: - Main List & Sections
    private var mainListView: some View {
        AthleticDashboardContainer {
            Text("Gym Tracker")
                .font(.system(size: 36, weight: .bold, design: .default))
                .fontWidth(.condensed)
                .tracking(-0.5)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            warMemorialSection
            mcComasSection
            boulderingWallSection
            sponsoredSection
            eventsSection
        }
    }

    private var motionPolicy: MotionPolicy {
        MotionPolicy(reduceMotion: reduceMotion)
    }

    private var warMemorialSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            AthleticFacilityCard(
                facilityTitle: "War Memorial Hall",
                occupancy: gymService.warMemorialOccupancy ?? 0,
                maxCapacity: Constants.warMemorialMaxCapacity,
                segmentCount: 20,
                networkMonitor: networkMonitor,
                motionPolicy: motionPolicy
            )
            AthleticFullBleedDivider()
        }
        .athleticStaggeredAppear(index: 0, motionPolicy: motionPolicy)
    }

    private var mcComasSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            AthleticFacilityCard(
                facilityTitle: "McComas Hall",
                occupancy: gymService.mcComasOccupancy ?? 0,
                maxCapacity: Constants.mcComasMaxCapacity,
                segmentCount: 20,
                networkMonitor: networkMonitor,
                motionPolicy: motionPolicy
            )
            AthleticFullBleedDivider()
        }
        .athleticStaggeredAppear(index: 1, motionPolicy: motionPolicy)
    }

    private var boulderingWallSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            AthleticFacilityCard(
                facilityTitle: "Bouldering Wall",
                occupancy: gymService.boulderingWallOccupancy ?? 0,
                maxCapacity: Constants.boulderingWallMaxCapacity,
                segmentCount: 8,
                networkMonitor: networkMonitor,
                motionPolicy: motionPolicy
            )
        }
        .athleticStaggeredAppear(index: 2, motionPolicy: motionPolicy)
    }

    private var eventsSection: some View {
        AthleticEventsBlock(eventsViewModel: eventsViewModel, networkMonitor: networkMonitor, motionPolicy: motionPolicy)
            .animation(motionPolicy.entryAnimation, value: eventsViewModel.events.count)
            .athleticStaggeredAppear(index: 4, motionPolicy: motionPolicy)
    }

    @ViewBuilder
    private var sponsoredSection: some View {
        if let ad = adViewModel.currentAd, sponsoredAdsEnabled {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    AthleticSectionHeader(title: "Sponsored")
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)

                    AdView(
                        ad: ad,
                        networkMonitor: networkMonitor,
                        onImpression: { adViewModel.trackImpressionIfNeeded(for: ad) },
                        onTap: { adViewModel.trackTap(for: ad) }
                    )
                }
                .padding(.vertical, 18)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .athleticStaggeredAppear(index: 3, motionPolicy: motionPolicy)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchGymOccupancyData() async {
        await gymService.fetchAllGymOccupancy()
    }
    
    // MARK: - Toolbar Button Methods
    
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

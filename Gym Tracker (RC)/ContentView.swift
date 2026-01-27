import SwiftUI
import AVFoundation
import Combine

struct ContentView: View {
    // MARK: - State Objects and Dependencies
    @StateObject private var networkMonitor: NetworkMonitor
    @StateObject private var eventsViewModel: EventsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
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
                        Task { await fetchGymOccupancyData() }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .inactive, .background:
                        isBarcodeDisplayPresented = false
                    case .active:
                        break
                    @unknown default:
                        break
                    }
                }
                .navigationTitle("Gym Tracker")
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
        List {
            warMemorialSection
            mcComasSection
            boulderingWallSection
            eventsSection
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
    
    private var warMemorialSection: some View {
        Section("War Memorial Hall") {
            OccupancyCard(
                occupancy: gymService.warMemorialOccupancy ?? 0,
                remaining: gymService.warMemorialRemaining,
                maxCapacity: Constants.warMemorialMaxCapacity,
                segmentCount: 20,
                networkMonitor: networkMonitor
            )
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
    }
    
    private var mcComasSection: some View {
        Section("McComas Hall") {
            OccupancyCard(
                occupancy: gymService.mcComasOccupancy ?? 0,
                remaining: gymService.mcComasRemaining,
                maxCapacity: Constants.mcComasMaxCapacity,
                segmentCount: 20,
                networkMonitor: networkMonitor
            )
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
    }
    
    private var boulderingWallSection: some View {
        Section("Bouldering Wall") {
            OccupancyCard(
                occupancy: gymService.boulderingWallOccupancy ?? 0,
                remaining: gymService.boulderingWallRemaining,
                maxCapacity: Constants.boulderingWallMaxCapacity,
                segmentCount: 8,
                networkMonitor: networkMonitor
            )
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
    }
    
    private var eventsSection: some View {
        Section {
            if let errorMessage = eventsViewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        eventsViewModel.fetchEvents()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(.top, 5)
                }
                .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            } else if eventsViewModel.events.isEmpty {
                Text("Nothing scheduled right now")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            } else {
                ForEach(eventsViewModel.events) { event in
                    EventCard(event: event)
                        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                }
            }
        } header: {
            HStack {
                Text("Upcoming Events")
                Spacer()
                Text("Today - \(Constants.formattedDateTwoWeeksAhead())")
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
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

import SwiftUI
import AVFoundation
import LocalAuthentication
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
            // Use NavigationStack for Liquid Glass compatibility
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
                        // Dismiss the barcode overlay when leaving the active state.
                        isBarcodeDisplayPresented = false
                    case .active:
                        print("ContentView: Scene phase changed to active.")
                    @unknown default:
                        print("ContentView: Unknown scene phase \(newPhase).")
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
            // Dimming layer when barcode overlay is active (avoids .blur/.overlay on NavigationStack
            // which can trigger "UIKitToolbar as subview of UIHostingController" hierarchy issues).
            if isBarcodeDisplayPresented {
                ZStack {
                    Rectangle().fill(.regularMaterial).ignoresSafeArea()
                    if colorScheme == .dark {
                        Color.black.opacity(0.6).ignoresSafeArea()
                    }
                }
            }
            if isBarcodeDisplayPresented {
                BarcodeDisplayOverlayView(isPresented: $isBarcodeDisplayPresented)
            }
        }
        // Minimal change: apply the user's theme choice.
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
                remaining: Constants.warMemorialMaxCapacity - (gymService.warMemorialOccupancy ?? 0),
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
                remaining: Constants.mcComasMaxCapacity - (gymService.mcComasOccupancy ?? 0),
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
                remaining: Constants.boulderingWallMaxCapacity - (gymService.boulderingWallOccupancy ?? 0),
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
                Text("Today - \(formattedDateTwoWeeksAhead())")
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formattedDateTwoWeeksAhead() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let twoWeeksAhead = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return formatter.string(from: twoWeeksAhead)
    }
    
    private func fetchGymOccupancyData() async {
        await gymService.fetchAllGymOccupancy()
    }
    
    // MARK: - Toolbar Button Methods
    /// Decide whether to display the stored barcode (after authentication) or open the ID input options.
    private func handlePassportButtonTapped() {
        if scannedBarcode.isEmpty {
            // No stored barcode; show Scan vs Manual choice in a dialog.
            showAddIDChoice = true
        } else {
            // Barcode exists; if Face ID is enabled, authenticate before displaying.
            if faceIDEnabled {
                authenticateUser { success in
                    if success {
                        isBarcodeDisplayPresented = true
                    } else {
                        alertManager.showAlert(.authenticationFailed)
                    }
                }
            } else {
                isBarcodeDisplayPresented = true
            }
        }
    }
    
    /// Check camera access before presenting the scanner.
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
    
    /// Prompt Face ID authentication before displaying the stored barcode.
    private func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to view your Campus ID."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
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

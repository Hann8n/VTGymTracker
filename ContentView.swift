import SwiftUI
import WidgetKit
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
    @State private var isMcComasExpanded: Bool = false
    @State private var isWarMemorialExpanded: Bool = false
    @State private var isLoading: Bool = false
    @State private var isScannerPresented: Bool = false
    @State private var isBarcodeDisplayPresented: Bool = false
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var showAboutPopup: Bool = false
    
    @AppStorage("appTheme") private var appTheme: String = "Auto"
    
    // MARK: - Initializer
    init() {
        let networkMonitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: networkMonitor)
        _eventsViewModel = StateObject(wrappedValue: EventsViewModel(networkMonitor: networkMonitor))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Wrap the NavigationView inside a ZStack.
            NavigationView {
                VStack(spacing: 0) {
                    mainListView
                        .onAppear {
                            Task {
                                if networkMonitor.isConnected {
                                    await fetchGymOccupancyData()
                                }
                                eventsViewModel.fetchEvents()
                            }
                        }
                    
                    BottomNavigationBar(
                        isScannerPresented: $isScannerPresented,
                        showAboutPopup: $showAboutPopup,
                        showBarcodeDisplay: $isBarcodeDisplayPresented
                    )
                    .frame(height: 80)
                }
                .edgesIgnoringSafeArea(.bottom)
                .sheet(isPresented: $isScannerPresented) {
                    BarcodeScannerView(isPresented: $isScannerPresented)
                        .environmentObject(alertManager)
                }
                .background(backgroundColor())
                .alert(item: $alertManager.currentAlert) { alertType in
                    alertType.generateAlert(openSettings: {
                        UIApplication.shared.openSettings()
                    })
                }
                .onReceive(timer) { _ in
                    if networkMonitor.isConnected {
                        Task { await fetchGymOccupancyData() }
                    }
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
                .navigationTitle("VT Gym Tracker")
            }
            .navigationViewStyle(StackNavigationViewStyle())
            // Blur the entire NavigationView when the barcode overlay is active.
            .blur(radius: isBarcodeDisplayPresented ? 35 : 0)
            // Overlay a dark translucent color only if in dark mode.
            .overlay {
                if isBarcodeDisplayPresented && colorScheme == .dark {
                    Color.black.opacity(0.6) // Adjust opacity as needed.
                        .ignoresSafeArea()
                }
            }
            
            // Present the barcode overlay view.
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
            eventsSection
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(backgroundColor())
    }
    
    private var warMemorialSection: some View {
        Section(header: Text("War Memorial Hall")) {
            OccupancyCard(
                occupancy: gymService.warMemorialOccupancy ?? 0,
                remaining: Constants.warMemorialMaxCapacity - (gymService.warMemorialOccupancy ?? 0),
                maxCapacity: Constants.warMemorialMaxCapacity,
                networkMonitor: networkMonitor
            )
            .listRowBackground(Color.clear)
            
            HoursCard(
                facilityId: Constants.warMemorialFacilityId,
                defaultHours: Constants.warMemorialHours,
                adjustedHours: warMemorialSpring2025AdjustedHours,
                isExpanded: $isWarMemorialExpanded
            )
            .listRowBackground(Color.clear)
        }
    }
    
    private var mcComasSection: some View {
        Section(header: Text("McComas Hall")) {
            OccupancyCard(
                occupancy: gymService.mcComasOccupancy ?? 0,
                remaining: Constants.mcComasMaxCapacity - (gymService.mcComasOccupancy ?? 0),
                maxCapacity: Constants.mcComasMaxCapacity,
                networkMonitor: networkMonitor
            )
            .listRowBackground(Color.clear)
            
            HoursCard(
                facilityId: Constants.mcComasFacilityId,
                defaultHours: Constants.mcComasHours,
                adjustedHours: mcComasSpring2025AdjustedHours,
                isExpanded: $isMcComasExpanded
            )
            .listRowBackground(Color.clear)
        }
    }
    
    private var eventsSection: some View {
        Section(
            header: HStack {
                Text("Upcoming Events")
                Spacer()
                Text("Today - \(formattedDateTwoWeeksAhead())")
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
        ) {
            if let errorMessage = eventsViewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: { eventsViewModel.fetchEvents() }) {
                        Text("Retry")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .padding(.top, 5)
                }
                .listRowBackground(Color.clear)
            } else if eventsViewModel.events.isEmpty {
                Text("No upcoming events.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(eventsViewModel.events) { event in
                    VStack(spacing: 0) {
                        EventCard(event: event)
                        Divider()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func backgroundColor() -> Color {
        colorScheme == .dark
            ? Color(red: 28/255, green: 28/255, blue: 30/255)
            : Color(red: 242/255, green: 242/255, blue: 247/255)
    }
    
    private func formattedDateTwoWeeksAhead() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let twoWeeksAhead = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return formatter.string(from: twoWeeksAhead)
    }
    
    private func fetchGymOccupancyData() async {
        await gymService.fetchAllGymOccupancy()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AlertManager())
            .preferredColorScheme(.light)
    }
}

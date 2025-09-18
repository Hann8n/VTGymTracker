//  ContentView.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import SwiftUI
import WidgetKit
import AVFoundation

struct ContentView: View {
    // MARK: - State Objects and Dependencies
    @StateObject private var networkMonitor: NetworkMonitor
    @StateObject private var warningManager = WarningManager(gymService: GymService.shared)
    @StateObject private var eventsViewModel: EventsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    // Provide AlertManager from environment
    @EnvironmentObject var alertManager: AlertManager
    
    // MARK: - Gym Service and State Variables
    private let gymService = GymService.shared
    @State private var mcComasOccupancy: Int = 0
    @State private var mcComasRemaining: Int = Constants.mcComasMaxCapacity
    @State private var warMemorialOccupancy: Int = 0
    @State private var warMemorialRemaining: Int = Constants.warMemorialMaxCapacity
    @State private var isMcComasExpanded: Bool = false
    @State private var isWarMemorialExpanded: Bool = false
    @State private var isLoading: Bool = false
    
    // MARK: - Barcode Scanner State Variables
    @State private var isScannerPresented: Bool = false
    
    // MARK: - UI State
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var showAboutPopup: Bool = false
    
    // MARK: - App Theme Setting
    @AppStorage("appTheme") private var appTheme: String = "Auto"
    
    // MARK: - Initializer
    init() {
        let networkMonitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: networkMonitor)
        _eventsViewModel = StateObject(wrappedValue: EventsViewModel(networkMonitor: networkMonitor))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // MARK: - Main Content
                    List {
                        // War Memorial Section
                        Section(header: Text("War Memorial Hall")) {
                            OccupancyCard(
                                occupancy: warMemorialOccupancy,
                                remaining: warMemorialRemaining,
                                maxCapacity: Constants.warMemorialMaxCapacity,
                                networkMonitor: networkMonitor
                            )
                            .listRowBackground(rowBackgroundColor())
                            
                            HoursCard(
                                gymHours: Constants.warMemorialHours,
                                currentTime: Date(),
                                isExpanded: $isWarMemorialExpanded
                            )
                            .listRowBackground(rowBackgroundColor())
                        }
                        
                        // McComas Hall Section
                        Section(header: Text("McComas Hall")) {
                            OccupancyCard(
                                occupancy: mcComasOccupancy,
                                remaining: mcComasRemaining,
                                maxCapacity: Constants.mcComasMaxCapacity,
                                networkMonitor: networkMonitor
                            )
                            .listRowBackground(rowBackgroundColor())
                            
                            HoursCard(
                                gymHours: Constants.mcComasHours,
                                currentTime: Date(),
                                isExpanded: $isMcComasExpanded
                            )
                            .listRowBackground(rowBackgroundColor())
                        }
                        
                        Section(header: HStack {
                            Text("Upcoming Events")
                            Spacer() // Push the date range to the opposite side
                            Text("Today — \(formattedDateTwoWeeksAhead())")
                                .fontWeight(.regular) // Make the text less emphasized
                                .foregroundColor(.secondary) // Use a secondary color for further de-emphasis
                        }) {
                            if let errorMessage = eventsViewModel.errorMessage {
                                VStack {
                                    Text(errorMessage)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    Button(action: {
                                        eventsViewModel.fetchEvents()
                                    }) {
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
                                    .listRowBackground(rowBackgroundColor())
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle("VT Gym Tracker")
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor())
                    .onAppear {
                        Task {
                            if networkMonitor.isConnected {
                                await fetchGymOccupancyData()
                            }
                            eventsViewModel.fetchEvents()
                        }
                    }
                    
                    // MARK: - Bottom Navigation Bar
                    BottomNavigationBar(
                        isScannerPresented: $isScannerPresented,
                        showAboutPopup: $showAboutPopup
                    )
                    .frame(height: 80)
                }
                .edgesIgnoringSafeArea(.bottom)
                .sheet(isPresented: $isScannerPresented) {
                    BarcodeScannerView(isPresented: $isScannerPresented)
                        .environmentObject(alertManager)
                }
            }
            .preferredColorScheme(getColorScheme()) // Apply Theme Setting
            .background(backgroundColor())
            
            // <--- IMPORTANT: Alert for ContentView
            .alert(item: $alertManager.currentAlert) { alertType in
                alertType.generateAlert(openSettings: {
                    UIApplication.shared.openSettings()
                })
            }
            
            // MARK: - Timers and Scene Changes
            .onReceive(timer) { _ in
                if networkMonitor.isConnected {
                    Task {
                        await fetchGymOccupancyData()
                    }
                }
            }
            .onChange(of: networkMonitor.isConnected) { _, newValue in
                if newValue {
                    Task {
                        await fetchGymOccupancyData()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && networkMonitor.isConnected {
                    Task {
                        await fetchGymOccupancyData()
                    }
                }
            }
        }
        // Apply the stack navigation view style to prevent sidebar on iPad
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helper Methods
    private func backgroundColor() -> Color {
        colorScheme == .dark
        ? Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
        : Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    }
    
    private func rowBackgroundColor() -> Color {
        Color.clear
    }
    
    private func fetchGymOccupancyData() async {
        isLoading = true
        async let mcComasData = gymService.fetchGymOccupancy(for: Constants.mcComasFacilityId)
        async let warMemorialData = gymService.fetchGymOccupancy(for: Constants.warMemorialFacilityId)
        let (mcComasResult, warMemorialResult) = await (mcComasData, warMemorialData)
        
        if let mcComasResult = mcComasResult {
            mcComasOccupancy = mcComasResult.occupancy
            mcComasRemaining = Constants.mcComasMaxCapacity - mcComasResult.occupancy
        }
        
        if let warMemorialResult = warMemorialResult {
            warMemorialOccupancy = warMemorialResult.occupancy
            warMemorialRemaining = Constants.warMemorialMaxCapacity - warMemorialResult.occupancy
        }
        
        isLoading = false
    }
    private func formattedDateTwoWeeksAhead() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Month and day only
        let twoWeeksAhead = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return formatter.string(from: twoWeeksAhead)
    }
    // MARK: - Theme Handling
    private func getColorScheme() -> ColorScheme? {
        switch appTheme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default:
            return nil // Auto
        }
    }
}

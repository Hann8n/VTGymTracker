//
//  ContentView.swift
//  Gym Tracker
//
//  Created by Jack on 1/13/25.
//

import SwiftUI
import WidgetKit
import AVFoundation

struct ContentView: View {
    // MARK: - State Objects and Dependencies
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var warningManager = WarningManager(gymService: GymService.shared)
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme

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
    @State private var scannedBarcode: String = UserDefaults.standard.string(forKey: "gymBarcode") ?? ""
    @State private var showBarcodeAlert: Bool = false
    @State private var showCameraAccessDeniedAlert: Bool = false

    // MARK: - UI State
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var showAboutPopup: Bool = false

    var body: some View {
        VStack(spacing: 0) { // Ensure no extra spacing
            // MARK: - Main Content
            NavigationView {
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
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("VT Gym Tracker")
                .scrollContentBackground(.hidden)
                .background(backgroundColor())
                .onAppear {
                    Task {
                        if networkMonitor.isConnected {
                            await fetchGymOccupancyData()
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .background(backgroundColor())

            // MARK: - Bottom Navigation Bar
            BottomNavigationBar(
                isScannerPresented: $isScannerPresented,
                scannedBarcode: $scannedBarcode,
                showAboutPopup: $showAboutPopup,
                showBarcodeAlert: $showBarcodeAlert,
                showCameraAccessDeniedAlert: $showCameraAccessDeniedAlert
            )
            .frame(height: 80)
        }
        .edgesIgnoringSafeArea(.bottom)
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

    // MARK: - Helper Methods
    func backgroundColor() -> Color {
        colorScheme == .dark
            ? Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
            : Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    }

    func rowBackgroundColor() -> Color {
        colorScheme == .dark
            ? Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
            : Color.white
    }

    func fetchGymOccupancyData() async {
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
}

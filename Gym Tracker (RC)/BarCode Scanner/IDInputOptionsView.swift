// IDInputOptionsView.swift
// Gym Tracker
//
// Created by Jack on 1/18/25.
//

import SwiftUI

struct IDInputOptionsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var alertManager: AlertManager
    @AppStorage("gymBarcode") private var gymBarcode: String = ""
    
    @State private var showScanner = false
    @State private var showManualInput = false
    @State private var initialBarcode: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header section
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.rectangle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.customOrange)
                    
                    VStack(spacing: 8) {
                        Text("Add Hokie Passport")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose how you'd like to add your student ID")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Options section
                VStack(spacing: 16) {
                    // Scan option
                    Button(action: {
                        showScanner = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2)
                                .foregroundColor(.customOrange)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan Barcode")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Use your camera to scan the barcode")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Manual input option
                    Button(action: {
                        showManualInput = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "keyboard")
                                .font(.title2)
                                .foregroundColor(.customOrange)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enter Manually")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Type your student ID number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Info section
                VStack(spacing: 8) {
                    Label("All data is stored locally on this device", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("Your ID will be formatted as a barcode", systemImage: "barcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Add ID")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .tint(.customOrange)
                }
            }
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView(isPresented: $showScanner)
                .environmentObject(alertManager)
        }
        .sheet(isPresented: $showManualInput) {
            ManualIDInputView(isPresented: $showManualInput)
                .environmentObject(alertManager)
        }
        .onAppear {
            initialBarcode = gymBarcode
        }
        .onChange(of: gymBarcode) { _, newValue in
            // Close the options view when a new barcode is saved
            if !newValue.isEmpty && newValue != initialBarcode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    IDInputOptionsView(isPresented: .constant(true))
        .environmentObject(AlertManager())
}

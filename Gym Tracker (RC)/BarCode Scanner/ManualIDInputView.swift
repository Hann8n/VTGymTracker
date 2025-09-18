// ManualIDInputView.swift
// Gym Tracker
//
// Created by Jack on 1/18/25.
//

import SwiftUI

struct ManualIDInputView: View {
    @Binding var isPresented: Bool
    @AppStorage("gymBarcode") private var gymBarcode: String = ""
    @EnvironmentObject var alertManager: AlertManager
    
    @State private var idNumber: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header section
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.customOrange)
                    
                    Text("Enter ID Number")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your student ID number manually")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Input section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Student ID Number")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your ID number", text: $idNumber)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal)
                
                // Info section
                VStack(spacing: 12) {
                    Label("All data is stored locally on this device", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("Your ID will be formatted as a barcode", systemImage: "barcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: saveID) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save ID")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(idNumber.isEmpty ? Color.gray.opacity(0.3) : Color.customOrange)
                        .foregroundColor(idNumber.isEmpty ? .secondary : .white)
                        .cornerRadius(12)
                    }
                    .disabled(idNumber.isEmpty || isLoading)
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.customOrange)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Manual Entry")
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
    }
    
    private func saveID() {
        // Validate the input
        let trimmedID = idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedID.isEmpty else {
            alertManager.showAlert(.custom(
                title: "Invalid Input",
                message: "Please enter a valid ID number.",
                primaryButton: .default(Text("OK")),
                secondaryButton: nil
            ))
            return
        }
        
        // Basic validation - check if it's numeric and reasonable length
        guard trimmedID.allSatisfy({ $0.isNumber }) else {
            alertManager.showAlert(.custom(
                title: "Invalid Format",
                message: "ID number should only contain numbers.",
                primaryButton: .default(Text("OK")),
                secondaryButton: nil
            ))
            return
        }
        
        guard trimmedID.count >= 4 && trimmedID.count <= 12 else {
            alertManager.showAlert(.custom(
                title: "Invalid Length",
                message: "ID number should be between 4 and 12 digits.",
                primaryButton: .default(Text("OK")),
                secondaryButton: nil
            ))
            return
        }
        
        isLoading = true
        
        // Format the ID as a Codabar barcode (same format as scanner)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let formattedBarcode = "A\(trimmedID)B"
            gymBarcode = formattedBarcode
            isLoading = false
            isPresented = false
            
            // Show success alert
            alertManager.showAlert(.custom(
                title: "ID Saved",
                message: "Your student ID has been saved successfully.",
                primaryButton: .default(Text("OK")),
                secondaryButton: nil
            ))
        }
    }
}

#Preview {
    ManualIDInputView(isPresented: .constant(true))
        .environmentObject(AlertManager())
}

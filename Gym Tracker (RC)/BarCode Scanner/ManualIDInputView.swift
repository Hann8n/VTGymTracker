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
    @FocusState private var isIDFieldFocused: Bool

    private var isSaveDisabled: Bool {
        idNumber.filter(\.isNumber).count != 9 || isLoading
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CampusIDFieldView(text: $idNumber, onTap: { isIDFieldFocused = true })
                        .onChange(of: idNumber) { _, newValue in
                            let digits = newValue.filter(\.isNumber)
                            if digits.count > 9 || newValue != digits {
                                idNumber = String(digits.prefix(9))
                            }
                        }
                        .overlay(
                            TextField("", text: $idNumber)
                                .keyboardType(.numberPad)
                                .focused($isIDFieldFocused)
                                .opacity(0)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                } header: {
                    Text("Campus ID")
                } footer: {
                    VStack(alignment: .center, spacing: 8) {
                        Label("All data is stored locally on this device", systemImage: "lock.shield")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("Your ID will be formatted as a barcode", systemImage: "barcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
            }
            .formStyle(.grouped)
            .safeAreaInset(edge: .bottom) {
                Button(action: saveID) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Text("Save ID")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.customOrange)
                .controlSize(.regular)
                .disabled(isSaveDisabled)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
            }
            .onAppear { isIDFieldFocused = true }
            .navigationTitle("Enter ID Number")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        let digits = idNumber.filter(\.isNumber)

        guard digits.count == 9 else {
            alertManager.showAlert(.custom(
                title: "Invalid Length",
                message: "Campus ID is 9 digits (XXXX-XXXXX).",
                primaryButton: .default(Text("OK")),
                secondaryButton: nil
            ))
            return
        }

        isLoading = true
        let formattedBarcode = "A\(digits)B"
        gymBarcode = formattedBarcode
        isLoading = false
        isPresented = false
    }
}

#Preview {
    ManualIDInputView(isPresented: .constant(true))
        .environmentObject(AlertManager())
}

//
//  PrivacyPolicyView.swift
//  Gym Tracker
//
//  Created by Jack on 1/16/25.
//


import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    // The URL of your Privacy Policy
    private let privacyPolicyURL = URL(string: "https://hann8n.github.io/VTGymTracker/docs/privacy-policy.html")!

    var body: some View {
        WebView(url: privacyPolicyURL)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .tint(.customOrange)
                }
            }
            .navigationBarBackButtonHidden(true)
            .edgesIgnoringSafeArea(.bottom) // Ensures the web view covers the entire screen
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}

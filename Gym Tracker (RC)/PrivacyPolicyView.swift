//
//  PrivacyPolicyView.swift
//  Gym Tracker
//
//  Created by Jack on 1/16/25.
//


import SwiftUI

struct PrivacyPolicyView: View {
    // The URL of your Privacy Policy
    private let privacyPolicyURL = URL(string: "https://gymtracker.jackhannon.net/privacy")!

    var body: some View {
        WebView(url: privacyPolicyURL)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom) // Ensures the web view covers the entire screen
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}

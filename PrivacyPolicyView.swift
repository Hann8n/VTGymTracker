//
//  PrivacyPolicyView.swift
//  Gym Tracker
//
//  Created by Jack on 1/16/25.
//


import SwiftUI

struct PrivacyPolicyView: View {
    // The URL of your Privacy Policy
    private let privacyPolicyURL = URL(string: "https://jhannon.notion.site/Privacy-Policy-1852ed69af6080a8bdeec447e8d54e2d?pvs=74")!

    var body: some View {
        WebView(url: privacyPolicyURL)
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .edgesIgnoringSafeArea(.bottom) // Ensures the web view covers the entire screen
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}

//
//  AppInfo.swift
//  Gym Tracker
//
//  Created by Jack on 2/9/25.
//

//
//  appinfo.swift
//  Gym Tracker
//
//  Created by Jack Hannon on February 8, 2025.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (Build \(build))"
        }
        return "Version N/A"
    }

    var body: some View {
        VStack {
            // Top content with logo image and details
            VStack(spacing: 16) {
                Image("VTGymApp_Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 135, height: 135) // Adjust size as needed
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5) // Floating effect
                    .padding(.top, 16)
                
                Text("Gym Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(appVersion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("""
                    An open-source app for Virginia Tech Gyms
                    
                    Developed by Jack Hannon
                    """)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Social Links Row with Bluesky, LinkedIn, GitHub, etc.
                HStack(spacing: 40) {
                    Link(destination: URL(string: "https://bsky.app/profile/did:plc:tjio2pnbsuc6ps77kocywwmc")!) {
                        Image("Bluesky_Logo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Link(destination: URL(string: "https://www.linkedin.com/in/jackphannon/")!) {
                        Image("LinkedIn_Logo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Link(destination: URL(string: "https://github.com/Hann8n")!) {
                        Image("GitHub_Logo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
            
            Spacer()
            
            // Footer text pinned to the bottom
            Text("""
                Virginia Tech is not associated with this project
                """)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .navigationTitle("App Information")
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
    }
}

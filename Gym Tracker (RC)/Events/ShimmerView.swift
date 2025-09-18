//
//  ShimmerView.swift
//  Gym Tracker
//
//  Created by Jack on 1/14/25.
//

import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .black, .black]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase * 300)
            )
            .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            .onAppear {
                self.phase = 1
            }
    }
}

struct ShimmerView_Previews: PreviewProvider {
    static var previews: some View {
        ShimmerView()
            .frame(width: 200, height: 20)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

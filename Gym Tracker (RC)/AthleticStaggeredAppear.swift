import SwiftUI

// MARK: - Staggered section reveal (respects Reduce Motion)

struct AthleticStaggeredAppear: ViewModifier {
    let index: Int
    let motionPolicy: MotionPolicy

    @State private var revealed = false

    func body(content: Content) -> some View {
        content
            .opacity(motionPolicy.reduceMotion || revealed ? 1 : 0)
            .offset(y: motionPolicy.reduceMotion || revealed ? 0 : 14)
            .scaleEffect(motionPolicy.reduceMotion || revealed ? 1 : 0.98)
            .onAppear {
                if motionPolicy.reduceMotion {
                    revealed = true
                    return
                }
                let delayMs = min(index, 12) * 55
                Task { @MainActor in
                    if delayMs > 0 {
                        try? await Task.sleep(for: .milliseconds(delayMs))
                    }
                    withAnimation(motionPolicy.entryAnimation) {
                        revealed = true
                    }
                }
            }
    }
}

extension View {
    func athleticStaggeredAppear(index: Int, motionPolicy: MotionPolicy) -> some View {
        modifier(AthleticStaggeredAppear(index: index, motionPolicy: motionPolicy))
    }
}

import SwiftUI

// MARK: - Staggered section reveal (respects Reduce Motion)

struct StaggeredAppear: ViewModifier {
    let index: Int
    let motionPolicy: MotionPolicy

    @State private var revealed = false

    func body(content: Content) -> some View {
        content
            .opacity(motionPolicy.reduceMotion || revealed ? 1 : 0)
            .onAppear {
                if motionPolicy.reduceMotion {
                    revealed = true
                    return
                }
                // Sibling inserts (e.g. sponsor) can re-trigger onAppear; don’t restagger — keeps layout + opacity in sync with the dashboard animation.
                guard !revealed else { return }
                let delayMs = min(index, 4) * 22
                Task { @MainActor in
                    if delayMs > 0 {
                        try? await Task.sleep(for: .milliseconds(delayMs))
                    }
                    withAnimation(motionPolicy.staggeredSectionRevealAnimation) {
                        revealed = true
                    }
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int, motionPolicy: MotionPolicy) -> some View {
        modifier(StaggeredAppear(index: index, motionPolicy: motionPolicy))
    }
}

import SwiftUI

struct MotionPolicy {
    let reduceMotion: Bool

    var entryAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.34, dampingFraction: 0.84)
    }

    var updateAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.1) : .spring(response: 0.26, dampingFraction: 0.88)
    }

    var transition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity)
    }
}

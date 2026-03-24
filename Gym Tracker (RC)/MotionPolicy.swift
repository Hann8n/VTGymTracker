import SwiftUI

struct MotionPolicy {
    let reduceMotion: Bool

    var entryAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.14) : .easeOut(duration: 0.26)
    }

    /// First-open stagger on dashboard sections only. Softer than `entryAnimation` so the cascade
    /// feels calm; list-driven UI (e.g. events) keeps using `entryAnimation`.
    var staggeredSectionRevealAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.14) : .easeInOut(duration: 0.30)
    }

    /// Reflow when sponsor mounts/unmounts — short ease-in-out so “Upcoming Events” shifts feel
    /// tight and even without bounce.
    var sponsorSectionLayoutAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.20) : .easeInOut(duration: 0.32)
    }

    var updateAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.1) : .easeInOut(duration: 0.24)
    }

    /// Opacity-only so section inserts (sponsor, events) do not stack slide + scale + fade.
    var transition: AnyTransition {
        .opacity
    }
}

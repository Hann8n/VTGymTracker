import SwiftUI

/// Keep the familiar labeled action in a horizontal bar, with a native symbol
/// representation when the system proposes a narrow vertical toolbar slot.
struct CampusIDButtonLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ViewThatFits(in: .horizontal) {
            Label(configuration)
                .labelStyle(.titleAndIcon)
                .fixedSize()
            Label(configuration)
                .labelStyle(.iconOnly)
        }
    }
}

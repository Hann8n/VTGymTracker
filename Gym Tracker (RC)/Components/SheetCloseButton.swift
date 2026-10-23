import SwiftUI

/// The system close button (iOS 26 `role: .close`), or an xmark before it, so every sheet closes the same way.
struct SheetCloseButton: View {
    /// Spoken name; "Close" unless the sheet needs to say what closes.
    var label = "Close"
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
                .accessibilityLabel(label)
        } else {
            Button(label, systemImage: "xmark", action: action)
                .labelStyle(.iconOnly)
        }
    }
}

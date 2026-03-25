import SwiftUI

// MARK: - Layout metrics (dashboard)

enum DashboardLayout {
    /// Horizontal inset for card content, section headers, and rows inside frosted surfaces.
    static let horizontalGutter: CGFloat = 16
    /// Vertical padding for a standard dashboard card block.
    static let cardVerticalPadding: CGFloat = 18
    /// Space before a section header that follows another dashboard block (gym cards, sponsor, etc.).
    static let sectionSpacingBeforeHeader: CGFloat = 24
    /// Opacity when offline, paired with grayscale in `dashboardCardChrome`.
    static let offlineOpacity: Double = 0.55
}

extension View {
    /// Frosted card background plus offline dimming (grayscale + reduced opacity).
    func dashboardCardChrome(networkMonitor: NetworkMonitor) -> some View {
        background { CardMaterialBackground() }
            .grayscale(networkMonitor.isConnected ? 0 : 1)
            .opacity(networkMonitor.isConnected ? 1 : DashboardLayout.offlineOpacity)
    }
}

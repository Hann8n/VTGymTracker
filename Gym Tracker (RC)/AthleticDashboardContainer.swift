import SwiftUI

struct AthleticDashboardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(AthleticFieldBoardBackground())
    }
}

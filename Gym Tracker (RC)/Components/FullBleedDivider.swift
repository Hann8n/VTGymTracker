import SwiftUI
import UIKit

struct FullBleedDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(uiColor: UIColor.separator))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }
}

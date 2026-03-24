import SwiftUI
import UIKit

struct AthleticFullBleedDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(uiColor: UIColor.separator))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }
}

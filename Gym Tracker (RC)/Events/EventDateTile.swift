import SwiftUI

/// A compact date heading shared by all events on the same day.
struct EventDateTile: View {
    let date: Date
    let isToday: Bool

    var body: some View {
        Text(isToday ? "Today · \(Self.dateFormatter.string(from: date))" : Self.dateFormatter.string(from: date))
            .font(.caption.weight(.semibold))
            .fontWidth(.condensed)
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundStyle(isToday ? Color("CustomOrange") : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(isToday ? "Today, \(Self.accessibilityFormatter.string(from: date))" : Self.accessibilityFormatter.string(from: date))
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Formatters

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter
    }()
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        EventDateTile(date: .now, isToday: true)
        EventDateTile(date: .now.addingTimeInterval(86_400 * 3), isToday: false)
    }
    .padding()
}

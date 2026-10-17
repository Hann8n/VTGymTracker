import SwiftUI

/// A calendar badge shared by all events on the same day, distinct from each event's time.
struct EventDateTile: View {
    let date: Date
    let isToday: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "calendar")
                .accessibilityHidden(true)
            Text(isToday ? "Today · \(Self.dateFormatter.string(from: date))" : Self.dateFormatter.string(from: date))
                .tracking(0.7)
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(isToday ? Color("CustomOrange") : Color.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isToday ? Color("CustomOrange").opacity(0.12) : Color.primary.opacity(0.06))
        }
        .accessibilityElement(children: .ignore)
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

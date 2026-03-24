import SwiftUI

struct EventCard: View {
    let event: Event

    var body: some View {
        Link(destination: event.link) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(event.title)
                        .font(.title3.weight(.bold))
                        .fontWidth(.condensed)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: "arrow.up.right")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(Constants.formattedEventStartDate(event.startDate))
                        .font(.subheadline.weight(.medium))
                        .fontWidth(.condensed)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 10)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(event.location)
                        .font(.subheadline.weight(.medium))
                        .fontWidth(.condensed)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

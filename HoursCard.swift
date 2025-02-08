import SwiftUI

struct HoursCard: View {
    let facilityId: String
    let defaultHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))]
    let adjustedHours: [AdjustedHours]
    @Binding var isExpanded: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    private let calendar = Calendar.current
    private let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name, e.g., "Monday"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // Computed property to determine the appropriate URL based on facilityId
    private var moreInfoURL: URL {
        switch facilityId {
        case Constants.mcComasFacilityId:
            return URL(string: "https://recsports.vt.edu/facilities/mccomas.html")!
        case Constants.warMemorialFacilityId:
            return URL(string: "https://recsports.vt.edu/facilities/warmemorial.html")!
        default:
            return URL(string: "https://recsports.vt.edu/facilities/hours.html")!
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1) Fetch today's status from GymStatusHelper using the current system time
            let currentTime = Date()
            let gymStatus = GymStatusHelper.getTodayGymStatus(
                facilityId: facilityId,
                defaultHours: defaultHours,
                adjustedHours: adjustedHours,
                currentTime: currentTime
            )
            
            // 2) Fetch weekly hours
            let weeklyHours = GymStatusHelper.getWeeklyHoursAndDates(
                facilityId: facilityId,
                defaultHours: defaultHours,
                adjustedHours: adjustedHours,
                currentTime: currentTime
            )
            
            // 3) Top bar with dynamic open/closed message
            HStack {
                if gymStatus.isOpen {
                    Text("Open")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text(gymStatus.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text("Closed")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(gymStatus.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron for expand/collapse
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 14, weight: .bold))
            }
            .contentShape(Rectangle()) // Makes the entire HStack tappable
            .onTapGesture { isExpanded.toggle() }
            .padding(.horizontal)
            .padding(.vertical, 3.4)
            
            // 4) Expanded weekly list
            VStack(alignment: .leading, spacing: 5) {
                if isExpanded {
                    ForEach(weeklyHours, id: \.date) { item in
                        // Determine if this day should be highlighted
                        let isHighlighted = shouldHighlight(dayLabel: item.label, date: item.date, gymStatus: gymStatus)
                        
                        dayRowView(dayName: item.label, hoursText: item.hoursText, isHighlighted: isHighlighted)
                    }
                    
                    // Link to official site
                    HStack {
                        Spacer()
                        Link("More Info",
                             destination: moreInfoURL)
                            .font(.footnote)
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                    }
                }
            }
            .padding(.horizontal)
            .transition(.opacity)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines whether a day should be highlighted based on GymStatus and current day.
    private func shouldHighlight(dayLabel: String, date: Date, gymStatus: GymStatus) -> Bool {
        let today = Date()
        
        // Check if the gym is currently open and the day is today
        if gymStatus.isOpen && calendar.isDate(date, inSameDayAs: today) {
            return true
        }
        
        // Otherwise, check if this day is the next opening day
        guard let nextOpenDay = gymStatus.nextOpenDay else { return false }
        
        var expectedDayLabel = nextOpenDay.lowercased()
        
        if nextOpenDay.lowercased() == "today" {
            expectedDayLabel = dayOfWeekFormatter.string(from: today).lowercased()
        } else if nextOpenDay.lowercased() == "tomorrow" {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
                expectedDayLabel = dayOfWeekFormatter.string(from: tomorrow).lowercased()
            }
        }
        
        return dayLabel.lowercased() == expectedDayLabel
    }
    
    // MARK: - Row Rendering
    
    @ViewBuilder
    private func dayRowView(dayName: String, hoursText: String, isHighlighted: Bool) -> some View {
        HStack {
            Text(dayName)
                .font(.footnote)
                .foregroundColor(isHighlighted ? .primary : .secondary)
            Spacer()
            Text(hoursText)
                .font(.footnote)
                .foregroundColor(isHighlighted ? .primary : .secondary)
        }
    }
}

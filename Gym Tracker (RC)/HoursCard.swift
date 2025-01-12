//
// HoursCard.swift
//
// This view displays the current gym status (open/closed) and shows a dropdown
// of gym hours for the week. It uses GymStatusHelper to determine the current status.
//
// Changes made:
// - Adjusted the highlighting logic in the dropdown:
//   * If the gym is open, highlight today.
//   * If closed and will open later today, highlight today.
//   * If closed and will not open until a future day, highlight only that next open day.

import SwiftUI

struct HoursCard: View {
    let gymHours: [(days: String, hours: String, openingTime: (Int, Int), closingTime: (Int, Int))]
    let currentTime: Date
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Get current gym status using GymStatusHelper
            let gymStatus = GymStatusHelper.getTodayGymStatus(for: gymHours, currentTime: currentTime)

            // Top row: shows "Open"/"Closed" and corresponding status
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
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .bold))
            }
            .contentShape(Rectangle())   // Makes the whole HStack tappable
            .onTapGesture {
                // Toggle dropdown on tap
                isExpanded.toggle()
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .fixedSize(horizontal: false, vertical: true)

            // Dropdown section with full schedule
            VStack(alignment: .leading, spacing: 5) {
                if isExpanded {
                    ForEach(gymHours, id: \.days) { day in
                        let isToday = day.days == GymStatusHelper.getCurrentDayOfWeek(currentTime: currentTime)
                        let isNextOpenDay = day.days == gymStatus.nextOpenDay

                        // Compute highlightCondition as a single expression or a small inline closure.
                        let highlightCondition: Bool = {
                            if gymStatus.isOpen {
                                return isToday
                            } else {
                                // Gym closed
                                if gymStatus.nextOpenDay == GymStatusHelper.getCurrentDayOfWeek(currentTime: currentTime) {
                                    // Gym will open later today
                                    return isToday
                                } else {
                                    // Gym will open on a different (future) day
                                    return isNextOpenDay
                                }
                            }
                        }()

                        // Now build the view using highlightCondition
                        HStack {
                            Text(day.days)
                                .font(.footnote)
                                .foregroundColor(highlightCondition ? .primary : .secondary)
                            Spacer()
                            Text(day.hours)
                                .font(.footnote)
                                .foregroundColor(highlightCondition ? .primary : .secondary)
                        }
                    }

                    // More info link
                    HStack {
                        Spacer()
                        Link("More Info", destination: URL(string: "https://recsports.vt.edu/facilities/hours.html")!)
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
            }
            // If not expanded, height = 0; if expanded, automatic height
            .frame(height: isExpanded ? nil : 0)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 0)
        .background(Color.clear)
        .cornerRadius(8)
    }
}

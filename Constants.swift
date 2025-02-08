//Constants.swift
//Shared File (Targets Gym Tracker RC and Gym Tracker Widget)

struct Constants {
    // Facility IDs
    static let mcComasFacilityId = "da73849e-434d-415f-975a-4f9e799b9c39"
    static let warMemorialFacilityId = "55069633-b56e-43b7-a68a-64d79364988d"
    
    // Maximum capacities
    static let mcComasMaxCapacity = 600
    static let warMemorialMaxCapacity = 1200

    // Gym hours for McComas and War Memorial using DateComponents (more efficient for time comparison)
    static let mcComasHours = [
        (days: "Sunday", hours: "10:00 AM - 8:00 PM", openingTime: (10, 00), closingTime: (20, 00)),
        (days: "Monday", hours: "6:00 AM - 11:00 PM", openingTime: (6, 00), closingTime: (23, 00)),
        (days: "Tuesday", hours: "6:00 AM - 11:00 PM", openingTime: (6, 00), closingTime: (23, 00)),
        (days: "Wednesday", hours: "6:00 AM - 11:00 PM", openingTime: (6, 00), closingTime: (23, 00)),
        (days: "Thursday", hours: "6:00 AM - 11:00 PM", openingTime: (6, 00), closingTime: (23, 00)),
        (days: "Friday", hours: "6:00 AM - 11:00 PM", openingTime: (6, 00), closingTime: (23, 00)),
        (days: "Saturday", hours: "10:00 AM - 8:00 PM", openingTime: (10, 00), closingTime: (20, 00))
    ]

    static let warMemorialHours = [
        (days: "Sunday", hours: "12:00 PM - 10:00 PM", openingTime: (12, 00), closingTime: (22, 00)),
        (days: "Monday", hours: "5:00 AM - 11:00 PM", openingTime: (5, 00), closingTime: (23, 00)),
        (days: "Tuesday", hours: "5:00 AM - 11:00 PM", openingTime: (5, 00), closingTime: (23, 00)),
        (days: "Wednesday", hours: "5:00 AM - 11:00 PM", openingTime: (5, 00), closingTime: (23, 00)),
        (days: "Thursday", hours: "5:00 AM - 11:00 PM", openingTime: (5, 00), closingTime: (23, 00)),
        (days: "Friday", hours: "5:00 AM - 11:00 PM", openingTime: (5, 00), closingTime: (23, 00)),
        (days: "Saturday", hours: "12:00 PM - 10:00 PM", openingTime: (12, 00), closingTime: (22, 00))
    ]
}

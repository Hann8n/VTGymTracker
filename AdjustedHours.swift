//
//  AdjustedHours.swift
//  Shared File (Targets Gym Tracker RC and Gym Tracker Widget)
//
//  Stores special/holiday overrides for each facility.
//

import Foundation

/// Represents an override to the normal day-of-week hours.
struct AdjustedHours {
    let facilityId: String                     // Which facility? (McComas, War Memorial, etc.)
    let startDate: DateComponents              // Start of override
    let endDate: DateComponents                // End of override (inclusive)
    let openingTime: (Int, Int)?               // e.g., (6,00) for 6:00 AM. Nil if closed.
    let closingTime: (Int, Int)?               // e.g., (18,00) for 6:00 PM. Nil if closed.
    let isClosed: Bool                         // True if completely closed during this range
}

/// Return an `AdjustedHours` entry (if any) that applies to the given facility on the given Date.
///
/// - Parameters:
///   - facilityId: e.g. `Constants.mcComasFacilityId`
///   - date: The current Date (today)
///   - overrides: The array of `AdjustedHours` to search
/// - Returns: The first matching override in which `date` falls between `startDate` and `endDate`, or nil if none.

// MARK: - McComas: Spring 2025
let mcComasSpring2025AdjustedHours: [AdjustedHours] = [
    // New Year’s, January 1: CLOSED
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 1),
        endDate: DateComponents(year: 2025, month: 1, day: 1),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
    // January 2 - 12: 6 AM - 6 PM, CLOSED on weekends -> break out weekend days or handle separately if needed
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 2),
        endDate: DateComponents(year: 2025, month: 1, day: 12),
        openingTime: (6, 0),
        closingTime: (18, 0),
        isClosed: false
    ),
    // January 13 - 19: 6 AM - 6 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 13),
        endDate: DateComponents(year: 2025, month: 1, day: 19),
        openingTime: (6, 0),
        closingTime: (18, 0),
        isClosed: false
    ),
    // MLK Day, Jan 20: 8 AM - 11 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 20),
        endDate: DateComponents(year: 2025, month: 1, day: 20),
        openingTime: (8, 0),
        closingTime: (23, 0),
        isClosed: false
    ),
    // Spring Break, March 8 - 16: CLOSED
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 3, day: 8),
        endDate: DateComponents(year: 2025, month: 3, day: 16),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
    // May 8: 6 AM - 10 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 8),
        endDate: DateComponents(year: 2025, month: 5, day: 8),
        openingTime: (6, 0),
        closingTime: (22, 0),
        isClosed: false
    ),
    // Finals Week:
    //   May 9: 6 AM - 10 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 9),
        endDate: DateComponents(year: 2025, month: 5, day: 9),
        openingTime: (6, 0),
        closingTime: (22, 0),
        isClosed: false
    ),
    //   May 10: 10 AM - 8 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 10),
        endDate: DateComponents(year: 2025, month: 5, day: 10),
        openingTime: (10, 0),
        closingTime: (20, 0),
        isClosed: false
    ),
    //   May 11: 10 AM - 8 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 11),
        endDate: DateComponents(year: 2025, month: 5, day: 11),
        openingTime: (10, 0),
        closingTime: (20, 0),
        isClosed: false
    ),
    //   May 12 - 15: 6 AM - 8 PM
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 12),
        endDate: DateComponents(year: 2025, month: 5, day: 15),
        openingTime: (6, 0),
        closingTime: (20, 0),
        isClosed: false
    ),
    // Post-Finals: May 16 - 26, CLOSED
    AdjustedHours(
        facilityId: Constants.mcComasFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 16),
        endDate: DateComponents(year: 2025, month: 5, day: 26),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
]

// MARK: - War Memorial: Spring 2025
let warMemorialSpring2025AdjustedHours: [AdjustedHours] = [
    // Jan 1 - 12: CLOSED
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 1),
        endDate: DateComponents(year: 2025, month: 1, day: 12),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
    // Jan 13 - 17: 6 AM - 6 PM
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 13),
        endDate: DateComponents(year: 2025, month: 1, day: 17),
        openingTime: (6, 0),
        closingTime: (18, 0),
        isClosed: false
    ),
    // MLK Day, Jan 20: 8 AM - 11 PM
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 1, day: 20),
        endDate: DateComponents(year: 2025, month: 1, day: 20),
        openingTime: (8, 0),
        closingTime: (23, 0),
        isClosed: false
    ),
    // March 8 - 9: CLOSED
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 3, day: 8),
        endDate: DateComponents(year: 2025, month: 3, day: 9),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
    // March 10 - 14: 6 AM - 6 PM
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 3, day: 10),
        endDate: DateComponents(year: 2025, month: 3, day: 14),
        openingTime: (6, 0),
        closingTime: (18, 0),
        isClosed: false
    ),
    // March 15: CLOSED
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 3, day: 15),
        endDate: DateComponents(year: 2025, month: 3, day: 15),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
    // May 8: 8 AM - 11 PM
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 8),
        endDate: DateComponents(year: 2025, month: 5, day: 8),
        openingTime: (8, 0),
        closingTime: (23, 0),
        isClosed: false
    ),
    // Finals Week (May 9 - 15): 8 AM - 11 PM
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 9),
        endDate: DateComponents(year: 2025, month: 5, day: 15),
        openingTime: (8, 0),
        closingTime: (23, 0),
        isClosed: false
    ),
    // Post-Finals
    //   May 16 - 18: CLOSED
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 16),
        endDate: DateComponents(year: 2025, month: 5, day: 18),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
    //   May 19 - 23: 6 AM - 6 PM
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 19),
        endDate: DateComponents(year: 2025, month: 5, day: 23),
        openingTime: (6, 0),
        closingTime: (18, 0),
        isClosed: false
    ),
    //   May 24 - 26: CLOSED
    AdjustedHours(
        facilityId: Constants.warMemorialFacilityId,
        startDate: DateComponents(year: 2025, month: 5, day: 24),
        endDate: DateComponents(year: 2025, month: 5, day: 26),
        openingTime: nil,
        closingTime: nil,
        isClosed: true
    ),
]

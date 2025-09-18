// GymFacility.swift
import Foundation

struct GymFacility: Identifiable {
    let id: String
    let name: String
    let hours: [(days: String, hours: String, openingTime: String, closingTime: String)]
    let remainingCapacity: Int
}

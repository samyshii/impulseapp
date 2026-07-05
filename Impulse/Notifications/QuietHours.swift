//
//  QuietHours.swift
//  Impulse
//
//  Nothing from Impulse should land between 9pm and 9am. This adjusts
//  a would-be delivery time so it never falls in that window.
//

import Foundation

enum QuietHours {
    private static let quietStartHour = 21 // 9pm
    private static let quietEndHour = 9    // 9am

    // If `date` falls inside quiet hours, pushes it to 9:05am instead.
    // Otherwise returns `date` unchanged.
    static func adjust(_ date: Date, calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        let isQuiet = hour >= quietStartHour || hour < quietEndHour
        guard isQuiet else { return date }

        // 9pm–midnight is "tonight", so 9:05am lands tomorrow morning.
        // Midnight–9am is "this morning", so 9:05am lands later today.
        let dayOffset = hour >= quietStartHour ? 1 : 0
        let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: date) ?? date

        var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
        components.hour = 9
        components.minute = 5
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}

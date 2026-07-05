//
//  AppStats.swift
//  Impulse
//
//  App-wide numbers that aren't tied to any single item: total money
//  saved, the current streak, and the streak "shield". There should
//  only ever be one AppStats record — StatsManager takes care of that.
//

import Foundation
import SwiftData

@Model
final class AppStats {
    // Total amount of money saved across all "let go" items, ever.
    var totalSaved: Decimal

    // How many weeks in a row the user has saved at least one item.
    var currentWeeklyStreak: Int

    // The date of the most recent "let go" win. Used to figure out
    // whether the streak continues, breaks, or needs the shield.
    var lastWinDate: Date?

    // Whether the user's one-per-month "streak shield" (which forgives
    // a single missed week) has already been used this calendar month.
    var streakShieldUsedThisMonth: Bool

    init(
        totalSaved: Decimal = 0,
        currentWeeklyStreak: Int = 0,
        lastWinDate: Date? = nil,
        streakShieldUsedThisMonth: Bool = false
    ) {
        self.totalSaved = totalSaved
        self.currentWeeklyStreak = currentWeeklyStreak
        self.lastWinDate = lastWinDate
        self.streakShieldUsedThisMonth = streakShieldUsedThisMonth
    }
}

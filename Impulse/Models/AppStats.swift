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

    // Whether the shield is ACTUALLY available right now — always ask
    // this rather than reading `streakShieldUsedThisMonth` directly.
    //
    // The stored flag is only ever cleared when a win comes in (see
    // StatsManager.updateStreak). So if the shield was used in, say,
    // February and the user hasn't won anything since, the flag is still
    // sitting at `true` all through March — even though a March win
    // would reset it and the shield really is available again. Reading
    // the raw flag would tell the user their shield is gone when it
    // isn't, exactly when they're most anxious about the streak.
    //
    // Whenever the flag is true, the shield was used on the most recent
    // win, so the month of `lastWinDate` is the month it was spent in.
    // A different month means it's back.
    func isShieldAvailable(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard streakShieldUsedThisMonth, let lastWinDate else { return true }
        return !calendar.isDate(lastWinDate, equalTo: date, toGranularity: .month)
    }
}

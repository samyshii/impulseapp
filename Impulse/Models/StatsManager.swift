//
//  StatsManager.swift
//  Impulse
//
//  Does the math for savings and streaks so the views don't have to.
//  There is only one AppStats record in the database; this manager
//  finds it (or creates it the very first time) and updates it.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
final class StatsManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // Finds the single AppStats record, creating it if this is the
    // very first time the app has needed it.
    func currentStats() -> AppStats {
        let descriptor = FetchDescriptor<AppStats>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let fresh = AppStats()
        modelContext.insert(fresh)
        return fresh
    }

    // Call this when the user "lets go" of an item: adds its price to
    // the running total and updates the weekly streak.
    func addWin(price: Decimal, on date: Date = .now) {
        let stats = currentStats()
        stats.totalSaved += price
        updateStreak(stats: stats, winDate: date)
        refreshWidget(stats: stats)
    }

    // Keeps the home screen widget's shared snapshot in sync. This is
    // the one place stats actually change, so it's the one place that
    // needs to tell the widget to refresh — no need to sprinkle this
    // call through every screen that can trigger a win.
    //
    // Done on a detached background task: WidgetCenter.reloadAllTimelines()
    // talks to a system service over XPC and is known to occasionally take
    // a noticeable moment (worse on the Simulator) — running it inline on
    // the main actor would freeze whatever triggered this (e.g. "Let it
    // go") for however long that takes. The snapshot is plain data
    // (Decimal/Int), so it's safe to hand across to the background task.
    private func refreshWidget(stats: AppStats) {
        let snapshot = WidgetSnapshot(
            totalSaved: stats.totalSaved,
            currentStreak: stats.currentWeeklyStreak,
            savedThisWeek: savedThisWeek()
        )
        Task.detached(priority: .utility) {
            snapshot.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // Adds up how much was saved from items let go during the current
    // calendar week.
    func savedThisWeek() -> Decimal {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return 0
        }
        // Narrow the fetch to items decided this week or later — ShelvedItem
        // carries its photo inline, so pulling every item ever shelved just
        // to add up this week's wins gets slower the longer the shelf's
        // history gets. (Status is checked after the fetch: SwiftData's
        // #Predicate can't compare enum cases directly.)
        let decidedRecentlyPredicate = #Predicate<ShelvedItem> { item in
            item.decidedAt != nil && item.decidedAt! >= weekStart
        }
        let descriptor = FetchDescriptor<ShelvedItem>(predicate: decidedRecentlyPredicate)
        let items = (try? modelContext.fetch(descriptor)) ?? []
        return items
            .filter { $0.status == .letGo }
            .reduce(Decimal(0)) { $0 + $1.price }
    }

    // The streak rules:
    // - First-ever win: streak starts at 1.
    // - A win in the same calendar week as the last one: streak stays put
    //   (it was already counted).
    // - A win exactly one week after the last one: streak goes up by 1.
    // - A win one week after a single missed week (a 2-week gap): the
    //   streak shield automatically covers the missed week, but only if
    //   the shield hasn't already been used this calendar month. The
    //   streak still goes up by 1, as if nothing was missed.
    // - Anything else (a bigger gap, or the shield already used this
    //   month): the streak resets to 1 — this win starts a fresh streak.
    private func updateStreak(stats: AppStats, winDate: Date) {
        let calendar = Calendar.current

        // The shield is a once-a-month perk. If the last win happened in
        // a different calendar month than this win, a new month has
        // started, so the shield is available again.
        if let lastWin = stats.lastWinDate,
           !calendar.isDate(lastWin, equalTo: winDate, toGranularity: .month) {
            stats.streakShieldUsedThisMonth = false
        }

        guard let lastWin = stats.lastWinDate else {
            stats.currentWeeklyStreak = 1
            stats.lastWinDate = winDate
            return
        }

        let weeksBetween = weeksBetween(lastWin, winDate, calendar: calendar)

        switch weeksBetween {
        case 0:
            // Same week as the last win — nothing to change.
            break
        case 1:
            // The very next week — streak continues.
            stats.currentWeeklyStreak += 1
        case 2 where !stats.streakShieldUsedThisMonth:
            // Missed exactly one week, but the shield saves the streak.
            stats.streakShieldUsedThisMonth = true
            stats.currentWeeklyStreak += 1
        default:
            // Missed too many weeks, or the shield was already used —
            // this win starts a brand new streak.
            stats.currentWeeklyStreak = 1
        }

        stats.lastWinDate = winDate
    }

    // Counts how many calendar weeks apart two dates are (by week-of-year,
    // not just a rolling 7-day count), so the streak lines up with real
    // calendar weeks.
    private func weeksBetween(_ start: Date, _ end: Date, calendar: Calendar) -> Int {
        guard let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: start)?.start,
              let startOfSecondWeek = calendar.dateInterval(of: .weekOfYear, for: end)?.start else {
            return 0
        }
        let components = calendar.dateComponents([.weekOfYear], from: startOfFirstWeek, to: startOfSecondWeek)
        return components.weekOfYear ?? 0
    }
}

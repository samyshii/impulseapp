//
//  WeeklyRecapData.swift
//  Impulse
//
//  The numbers behind one Weekly Recap screen: how much was saved, the
//  single best win, and the current streak — all for a specific week.
//  Kept separate from the view so both the real auto-trigger and the
//  Settings > Debug preview button can compute the same data for
//  whichever week they care about.
//

import Foundation
import SwiftData

struct WeeklyRecapData {
    let totalSaved: Decimal
    let bestWin: (name: String, amount: Decimal)?
    let currentStreak: Int
    let shieldAvailable: Bool

    // All-time total saved, ever — separate from `totalSaved` above
    // (which is just this week). Used by the share card, which always
    // shows the all-time figure regardless of which win it's sharing.
    let allTimeTotalSaved: Decimal

    // Whether anything happened that week at all (something shelved or
    // decided) — used to decide whether the recap is worth showing
    // automatically. Not used by the Debug preview, which always shows
    // regardless.
    let hadActivity: Bool

    @MainActor
    static func compute(context: ModelContext, from start: Date, to end: Date) -> WeeklyRecapData {
        // Only fetch items that actually touch this week (shelved or
        // decided in [start, end)) instead of every item ever shelved.
        // ShelvedItem carries its photo inline, so an unfiltered fetch
        // pulls every photo ever taken off disk just to check a date —
        // and it only gets slower the longer the shelf's history gets.
        let thisWeekPredicate = #Predicate<ShelvedItem> { item in
            (item.createdAt >= start && item.createdAt < end) ||
            (item.decidedAt != nil && item.decidedAt! >= start && item.decidedAt! < end)
        }
        let weekItems = (try? context.fetch(FetchDescriptor(predicate: thisWeekPredicate))) ?? []

        let letGoThisWeek = weekItems.filter { item in
            item.status == .letGo && (item.decidedAt.map { $0 >= start && $0 < end } ?? false)
        }
        let totalSaved = letGoThisWeek.reduce(Decimal(0)) { $0 + $1.price }
        let best = letGoThisWeek.max { $0.price < $1.price }

        // The predicate above already only matches items that were
        // shelved or decided this week, so a non-empty result *is* activity.
        let hadActivity = !weekItems.isEmpty

        let stats = StatsManager(modelContext: context).currentStats()

        return WeeklyRecapData(
            totalSaved: totalSaved,
            bestWin: best.map { (name: $0.name, amount: $0.price) },
            currentStreak: stats.currentWeeklyStreak,
            shieldAvailable: stats.isShieldAvailable(),
            allTimeTotalSaved: stats.totalSaved,
            hadActivity: hadActivity
        )
    }
}

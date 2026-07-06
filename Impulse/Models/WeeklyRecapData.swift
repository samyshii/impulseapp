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

    // Whether anything happened that week at all (something shelved or
    // decided) — used to decide whether the recap is worth showing
    // automatically. Not used by the Debug preview, which always shows
    // regardless.
    let hadActivity: Bool

    @MainActor
    static func compute(context: ModelContext, from start: Date, to end: Date) -> WeeklyRecapData {
        let allItems = (try? context.fetch(FetchDescriptor<ShelvedItem>())) ?? []

        let letGoThisWeek = allItems.filter { item in
            item.status == .letGo && (item.decidedAt.map { $0 >= start && $0 < end } ?? false)
        }
        let totalSaved = letGoThisWeek.reduce(Decimal(0)) { $0 + $1.price }
        let best = letGoThisWeek.max { $0.price < $1.price }

        let hadActivity = allItems.contains { item in
            (item.createdAt >= start && item.createdAt < end) ||
            (item.decidedAt.map { $0 >= start && $0 < end } ?? false)
        }

        let stats = StatsManager(modelContext: context).currentStats()

        return WeeklyRecapData(
            totalSaved: totalSaved,
            bestWin: best.map { (name: $0.name, amount: $0.price) },
            currentStreak: stats.currentWeeklyStreak,
            shieldAvailable: !stats.streakShieldUsedThisMonth,
            hadActivity: hadActivity
        )
    }
}

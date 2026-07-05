//
//  StreakGuardScheduler.swift
//  Impulse
//
//  Schedules a Saturday 11am nudge, but only when it's actually needed:
//  the streak is 3+ weeks long and there's no win yet this week. Frames
//  the streak shield as backup so it reduces anxiety rather than adding
//  to it — unless the shield's already been used this month, in which
//  case it's honest about that instead.
//

import Foundation
import SwiftData

@MainActor
enum StreakGuardScheduler {
    private static let identifier = "streakGuard"

    static func reconcile(context: ModelContext, enabled: Bool, reservedDays: inout Set<DateComponents>) {
        guard enabled else {
            NotificationScheduler.cancelPending(identifiers: [identifier])
            return
        }

        let statsManager = StatsManager(modelContext: context)
        let stats = statsManager.currentStats()
        let hasWinThisWeek = statsManager.savedThisWeek() > 0

        guard stats.currentWeeklyStreak >= 3, !hasWinThisWeek else {
            NotificationScheduler.cancelPending(identifiers: [identifier])
            return
        }

        var components = DateComponents()
        components.weekday = 7 // Saturday (Foundation's Gregorian calendar: 1 = Sunday)
        components.hour = 11
        components.minute = 0
        guard let nextSaturday = Calendar.current.nextDate(after: .now, matching: components, matchingPolicy: .nextTime) else { return }

        var fireDate = QuietHours.adjust(nextSaturday)
        fireDate = NotificationScheduler.nextFreeDay(startingAt: fireDate, reservedDays: &reservedDays)

        let shieldAvailable = !stats.streakShieldUsedThisMonth
        let (title, body) = NotificationCopy.streakGuard(streakWeeks: stats.currentWeeklyStreak, shieldAvailable: shieldAvailable)

        NotificationScheduler.cancelPending(identifiers: [identifier])
        NotificationScheduler.scheduleAt(identifier: identifier, title: title, body: body, date: fireDate, type: "streakGuard")
    }
}

//
//  WeeklyRecapScheduler.swift
//  Impulse
//
//  Schedules the once-a-week recap (or, if nothing happened that week,
//  a gentle check-in instead — never both). The day and time come from
//  Settings, defaulting to Sunday 6pm.
//

import Foundation
import SwiftData

@MainActor
enum WeeklyRecapScheduler {
    private static let identifier = "weeklyRecap"

    static func reconcile(context: ModelContext, enabled: Bool, reservedDays: inout Set<DateComponents>) {
        guard enabled else {
            NotificationScheduler.cancelPending(identifiers: [identifier])
            return
        }

        let defaults = UserDefaults.standard
        let weekday = defaults.object(forKey: "weeklyRecapWeekday") as? Int ?? 1 // Sunday
        let hour = defaults.object(forKey: "weeklyRecapHour") as? Int ?? 18
        let minute = defaults.object(forKey: "weeklyRecapMinute") as? Int ?? 0

        guard let nextOccurrence = nextOccurrence(weekday: weekday, hour: hour, minute: minute) else { return }
        var fireDate = QuietHours.adjust(nextOccurrence)
        fireDate = NotificationScheduler.nextFreeDay(startingAt: fireDate, reservedDays: &reservedDays)

        let (title, body) = hasActivityThisWeek(context: context)
            ? NotificationCopy.weeklyRecapActive(savedThisWeek: savedThisWeek(context: context), winsCount: winsThisWeek(context: context))
            : NotificationCopy.weeklyRecapQuiet()

        NotificationScheduler.cancelPending(identifiers: [identifier])
        NotificationScheduler.scheduleAt(identifier: identifier, title: title, body: body, date: fireDate, type: "weeklyRecap")
    }

    private static func nextOccurrence(weekday: Int, hour: Int, minute: Int) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return Calendar.current.nextDate(after: .now, matching: components, matchingPolicy: .nextTime)
    }

    private static func weekStart() -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    }

    private static func hasActivityThisWeek(context: ModelContext) -> Bool {
        let start = weekStart()
        let items = (try? context.fetch(FetchDescriptor<ShelvedItem>())) ?? []
        return items.contains { $0.createdAt >= start || ($0.decidedAt ?? .distantPast) >= start }
    }

    private static func winsThisWeek(context: ModelContext) -> Int {
        letGoItemsThisWeek(context: context).count
    }

    private static func savedThisWeek(context: ModelContext) -> Decimal {
        letGoItemsThisWeek(context: context).reduce(Decimal(0)) { $0 + $1.price }
    }

    private static func letGoItemsThisWeek(context: ModelContext) -> [ShelvedItem] {
        let start = weekStart()
        let items = (try? context.fetch(FetchDescriptor<ShelvedItem>())) ?? []
        return items.filter { $0.status == .letGo && ($0.decidedAt ?? .distantPast) >= start }
    }
}

//
//  WinBackScheduler.swift
//  Impulse
//
//  If the user disappears for a while, gives them exactly two nudges:
//  one at 10 days of inactivity, one final one at 30 days — then goes
//  silent for good until they reopen the app. Opening the app resets
//  the inactivity clock (recordAppOpen), and the actual (re)scheduling
//  happens on the very next reconcile pass.
//

import Foundation

@MainActor
enum WinBackScheduler {
    private static let id10 = "winBack10"
    private static let id30 = "winBack30"
    private static let lastOpenKey = "lastAppOpenDate"

    // Call this whenever the app becomes active (a real "open"). Just
    // stamps the moment — scheduling happens separately in reconcile(),
    // which NotificationScheduler.reconcileAll calls right after.
    static func recordAppOpen() {
        UserDefaults.standard.set(Date(), forKey: lastOpenKey)
    }

    static func reconcile(enabled: Bool, reservedDays: inout Set<DateComponents>) {
        NotificationScheduler.cancelPending(identifiers: [id10, id30])
        guard enabled, let lastOpen = UserDefaults.standard.object(forKey: lastOpenKey) as? Date else { return }

        var tenDayMark = QuietHours.adjust(lastOpen.addingTimeInterval(10 * 24 * 60 * 60))
        var thirtyDayMark = QuietHours.adjust(lastOpen.addingTimeInterval(30 * 24 * 60 * 60))
        tenDayMark = NotificationScheduler.nextFreeDay(startingAt: tenDayMark, reservedDays: &reservedDays)
        thirtyDayMark = NotificationScheduler.nextFreeDay(startingAt: thirtyDayMark, reservedDays: &reservedDays)

        if tenDayMark > .now {
            NotificationScheduler.scheduleAt(
                identifier: id10,
                title: NotificationCopy.winBack10.title,
                body: NotificationCopy.winBack10.body,
                date: tenDayMark,
                type: "winBack"
            )
        }
        if thirtyDayMark > .now {
            NotificationScheduler.scheduleAt(
                identifier: id30,
                title: NotificationCopy.winBack30.title,
                body: NotificationCopy.winBack30.body,
                date: thirtyDayMark,
                type: "winBack"
            )
        }
    }
}

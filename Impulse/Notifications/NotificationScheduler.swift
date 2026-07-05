//
//  NotificationScheduler.swift
//  Impulse
//
//  The one entry point the rest of the app calls into: reconcileAll.
//  Call it any time something happens that could change what should be
//  scheduled — an item shelved, a decision made, a setting toggled, or
//  the app coming to the foreground/background. It re-checks
//  everything from scratch and reschedules each notification type with
//  fresh, up-to-date content. This file also holds the small low-level
//  helpers (schedule/cancel/day-collision) that every notification
//  type shares.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
enum NotificationScheduler {

    static func reconcileAll(context: ModelContext) {
        let defaults = UserDefaults.standard
        let master = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true

        func categoryEnabled(_ key: String) -> Bool {
            master && (defaults.object(forKey: key) as? Bool ?? true)
        }

        let decisionEnabled = categoryEnabled("notifyDecisionTime")
        let recapEnabled = categoryEnabled("notifyWeeklyRecap")
        let guardEnabled = categoryEnabled("notifyStreakGuard")
        let winBackEnabled = categoryEnabled("notifyWinBack")

        // Decision Time is explicitly exempt from the "one per day" rule,
        // so it doesn't take part in the reserved-days bookkeeping below.
        DecisionTimeScheduler.reconcile(context: context, enabled: decisionEnabled)

        // Milestones fire immediately, straight from DecisionFlowView, at
        // the moment they're earned — not from here. But if one already
        // fired today, the routine notification types below need to know
        // so they don't also land today.
        var reservedDays: Set<DateComponents> = []
        if MilestoneNotifier.firedToday {
            reservedDays.insert(Calendar.current.dateComponents([.year, .month, .day], from: .now))
        }

        // Priority order matters: each scheduler reserves its day before
        // the next one runs, so lower-priority types get bumped instead.
        StreakGuardScheduler.reconcile(context: context, enabled: guardEnabled, reservedDays: &reservedDays)
        WeeklyRecapScheduler.reconcile(context: context, enabled: recapEnabled, reservedDays: &reservedDays)
        WinBackScheduler.reconcile(enabled: winBackEnabled, reservedDays: &reservedDays)
    }

    // MARK: - Shared low-level helpers

    // Fires almost immediately — used for milestones, which are
    // real-time celebrations rather than something scheduled ahead.
    static func fireNow(identifier: String, title: String, body: String, type: String, userInfo: [String: Any] = [:]) {
        var info = userInfo
        info["type"] = type
        add(identifier: identifier, title: title, body: body, userInfo: info, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
    }

    // Schedules for an exact future date and time.
    static func scheduleAt(identifier: String, title: String, body: String, date: Date, type: String, userInfo: [String: Any] = [:]) {
        var info = userInfo
        info["type"] = type
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        add(identifier: identifier, title: title, body: body, userInfo: info, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
    }

    private static func add(identifier: String, title: String, body: String, userInfo: [String: Any], trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // Cancels every not-yet-delivered request whose identifier starts
    // with `prefix`. Used by Decision Time, which can have any number of
    // pending notifications (one per hour-bucket) at once.
    static func cancelPending(withPrefix prefix: String) async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Cancels specific, known identifiers (the other notification types
    // each use one fixed identifier, so no lookup is needed).
    static func cancelPending(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // Nudges `date` forward a day at a time until it lands on a day not
    // already spoken for in `reservedDays`, reserves that day, and
    // returns the (possibly nudged) date. This is how we enforce "never
    // more than one non-Decision-Time notification per day."
    static func nextFreeDay(startingAt date: Date, reservedDays: inout Set<DateComponents>, calendar: Calendar = .current) -> Date {
        var candidate = date
        var key = calendar.dateComponents([.year, .month, .day], from: candidate)
        while reservedDays.contains(key) {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            key = calendar.dateComponents([.year, .month, .day], from: candidate)
        }
        reservedDays.insert(key)
        return candidate
    }
}

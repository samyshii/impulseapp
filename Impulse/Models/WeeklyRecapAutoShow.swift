//
//  WeeklyRecapAutoShow.swift
//  Impulse
//
//  Decides whether the full-screen Weekly Recap should pop up right
//  now. It should appear once — the first time the app opens after a
//  Sunday evening has passed — and only for a week that actually had
//  something happen in it.
//

import Foundation
import SwiftData

@MainActor
enum WeeklyRecapAutoShow {
    private static let lastShownWeekStartKey = "lastWeeklyRecapCardShownWeekStart"

    // Call this when the app becomes active. Returns the data to show
    // if a not-yet-seen, just-completed week is ready to be recapped —
    // nil if it's not time yet, it's already been shown, or nothing
    // happened that week.
    static func checkForNewRecap(context: ModelContext) -> WeeklyRecapData? {
        let calendar = Calendar.current

        // The most recent Sunday 6pm that has already happened.
        var cutoffComponents = DateComponents()
        cutoffComponents.weekday = 1 // Sunday
        cutoffComponents.hour = 18
        cutoffComponents.minute = 0
        guard let lastCutoff = calendar.nextDate(
            after: .now,
            matching: cutoffComponents,
            matchingPolicy: .nextTime,
            direction: .backward
        ) else {
            return nil
        }

        // The week that cutoff closed out. Sunday is the first day of
        // Calendar's week, so the week "ending" at Sunday evening is
        // actually the one before it — a date a few days back from the
        // cutoff safely lands in the middle of that week regardless of
        // exact boundary timing.
        guard let midOfRecapWeek = calendar.date(byAdding: .day, value: -3, to: lastCutoff),
              let recapWeek = calendar.dateInterval(of: .weekOfYear, for: midOfRecapWeek) else {
            return nil
        }

        // Already shown for this exact week? Don't show it twice.
        if let alreadyShown = UserDefaults.standard.object(forKey: lastShownWeekStartKey) as? Double,
           abs(alreadyShown - recapWeek.start.timeIntervalSince1970) < 1 {
            return nil
        }

        let data = WeeklyRecapData.compute(context: context, from: recapWeek.start, to: recapWeek.end)
        guard data.hadActivity else { return nil }

        UserDefaults.standard.set(recapWeek.start.timeIntervalSince1970, forKey: lastShownWeekStartKey)
        return data
    }
}

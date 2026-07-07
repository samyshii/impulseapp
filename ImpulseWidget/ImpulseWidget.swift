//
//  ImpulseWidget.swift
//  ImpulseWidget
//
//  A home screen widget showing the current weekly streak and the
//  all-time total saved — the same numbers the Wins tab shows, read
//  from a small snapshot the main app keeps updated in a shared App
//  Group container (this extension runs in its own process and can't
//  see the app's SwiftData store directly).
//

import WidgetKit
import SwiftUI

struct ImpulseWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ImpulseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ImpulseWidgetEntry {
        ImpulseWidgetEntry(
            date: .now,
            snapshot: WidgetSnapshot(totalSaved: 142.50, currentStreak: 3, savedThisWeek: 42)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ImpulseWidgetEntry) -> Void) {
        completion(ImpulseWidgetEntry(date: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ImpulseWidgetEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date.now
        let current = WidgetSnapshot.load()

        var entries = [ImpulseWidgetEntry(date: now, snapshot: current)]

        // "Saved this week" should reset to zero once the calendar week
        // rolls over, even if nothing else about the data changes — so
        // that transition is scheduled ahead of time here rather than
        // waiting for the app to be reopened and tell the widget to
        // refresh.
        if let nextWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.end {
            let rolledOver = WidgetSnapshot(
                totalSaved: current.totalSaved,
                currentStreak: current.currentStreak,
                savedThisWeek: 0
            )
            entries.append(ImpulseWidgetEntry(date: nextWeekStart, snapshot: rolledOver))
            completion(Timeline(entries: entries, policy: .after(nextWeekStart)))
        } else {
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
}

struct ImpulseWidget: Widget {
    let kind = "ImpulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ImpulseWidgetProvider()) { entry in
            ImpulseWidgetView(snapshot: entry.snapshot)
                .widgetURL(URL(string: "impulse://wins"))
        }
        .configurationDisplayName("Impulse")
        .description("Your streak and total saved, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

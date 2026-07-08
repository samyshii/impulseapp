//
//  WidgetSnapshot.swift
//  Impulse
//
//  A tiny, plain-data copy of the numbers the home screen widget shows.
//  The main app writes this to a shared App Group container every time
//  the underlying stats change; the widget extension runs in its own
//  separate process with no access to the app's SwiftData store, so it
//  reads this back instead. This file is shared between the Impulse
//  app target and the ImpulseWidget extension target — it's the only
//  thing the two processes have in common.
//

import Foundation

// Must exactly match the App Group ID in both targets' entitlements.
let widgetAppGroupID = "group.com.samshi.Impulse"

struct WidgetSnapshot: Codable {
    var totalSaved: Decimal
    var currentStreak: Int
    var savedThisWeek: Decimal

    private static let defaultsKey = "widgetSnapshot"

    // Explicitly not tied to the main actor: UserDefaults is thread-safe,
    // and this needs to be callable from a background task so writing a
    // snapshot (and nudging WidgetKit to refresh) never has a chance to
    // block the UI, no matter how slow that turns out to be.
    nonisolated static func load() -> WidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: widgetAppGroupID),
            let data = defaults.data(forKey: defaultsKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return WidgetSnapshot(totalSaved: 0, currentStreak: 0, savedThisWeek: 0)
        }
        return snapshot
    }

    nonisolated func save() {
        guard
            let defaults = UserDefaults(suiteName: widgetAppGroupID),
            let data = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}

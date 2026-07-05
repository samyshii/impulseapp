//
//  DecisionTimeScheduler.swift
//  Impulse
//
//  Schedules the "your cooldown ended" notifications. Items whose
//  cooldown ends in the same calendar hour are grouped and fire as one
//  combined notification, timed to the last item in the group so it
//  can honestly say everything in it is actually ready.
//

import Foundation
import SwiftData

@MainActor
enum DecisionTimeScheduler {
    private static let idPrefix = "decisionTime-"

    static func reconcile(context: ModelContext, enabled: Bool) {
        Task {
            // Always start from a clean slate — every still-pending
            // Decision Time notification gets rebuilt from current data.
            await NotificationScheduler.cancelPending(withPrefix: idPrefix)
            guard enabled else { return }

            let allItems = (try? context.fetch(FetchDescriptor<ShelvedItem>())) ?? []
            let waitingItems = allItems.filter { $0.status == .waiting }
            guard !waitingItems.isEmpty else { return }

            let calendar = Calendar.current
            let groups = Dictionary(grouping: waitingItems) { item in
                calendar.dateComponents([.year, .month, .day, .hour], from: item.cooldownEndsAt)
            }

            for (bucketKey, items) in groups {
                // Fire once the LAST item in the group is truly ready, so
                // a combined notification never mentions something that
                // isn't actually off cooldown yet.
                let latest = items.map(\.cooldownEndsAt).max() ?? .now
                var fireDate = QuietHours.adjust(latest, calendar: calendar)

                // If the whole group is already overdue (e.g. notifications
                // were just turned on after items became ready), fire
                // almost immediately instead of scheduling in the past.
                if fireDate <= .now {
                    fireDate = Date().addingTimeInterval(2)
                }

                let (title, body) = NotificationCopy.decisionTime(itemNames: items.map(\.name))
                var userInfo: [String: Any] = [:]
                if items.count == 1 {
                    userInfo["itemID"] = items[0].id.uuidString
                }

                let identifier = idPrefix + bucketKeyString(bucketKey)
                NotificationScheduler.scheduleAt(
                    identifier: identifier,
                    title: title,
                    body: body,
                    date: fireDate,
                    type: "decisionTime",
                    userInfo: userInfo
                )
            }
        }
    }

    private static func bucketKeyString(_ components: DateComponents) -> String {
        "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)"
    }
}

//
//  NotificationManager.swift
//  Impulse
//
//  The one place that talks to Apple's UserNotifications framework
//  directly for permission and for handling taps. Everything else in
//  the app goes through NotificationScheduler instead of touching
//  UNUserNotificationCenter for permission/delegate concerns.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {}

    // Shows Apple's real system permission popup. Only call this right
    // after the user taps "Yes, notify me" on the pre-permission screen,
    // or later if they flip the master toggle on in Settings.
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // Whether the user has already granted, denied, or not yet been
    // asked for notification permission.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // Lets notifications show as a banner even while the app is open,
    // which makes them much easier to test on the Simulator.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Runs when the user taps a delivered notification. Reads the
    // "type" (and, for a single ready item, the item's id) we stashed in
    // the notification's userInfo, and tells NotificationRouter where
    // the app should navigate.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch userInfo["type"] as? String {
        case "decisionTime":
            if let idString = userInfo["itemID"] as? String, let uuid = UUID(uuidString: idString) {
                NotificationRouter.shared.destination = .decisionItem(uuid)
            } else {
                // A combined notification covering several items — just
                // open the Shelf so the user can pick one.
                NotificationRouter.shared.destination = .shelf
            }
        case "weeklyRecap", "streakGuard", "milestone":
            NotificationRouter.shared.destination = .wins
        case "winBack":
            NotificationRouter.shared.destination = .shelf
        default:
            break
        }

        completionHandler()
    }
}

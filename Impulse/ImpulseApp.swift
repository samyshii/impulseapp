//
//  ImpulseApp.swift
//  Impulse
//
//  Created by Sam S on 2026-07-04.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ImpulseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ShelvedItem.self,
            Goal.self,
            AppStats.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // So taps on delivered notifications reach NotificationManager.
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    // The home screen widget links to "impulse://wins" —
                    // reuse the same routing notification taps already
                    // use to land on the Wins tab.
                    if url.host == "wins" {
                        NotificationRouter.shared.destination = .wins
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

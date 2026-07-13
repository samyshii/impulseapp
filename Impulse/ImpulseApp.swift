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
    // Owns everything to do with subscriptions. Created once, here, and
    // handed down to every screen that needs it. It picks its own
    // purchase backend based on the switch in PurchaseConfig.
    @StateObject private var subscriptions = SubscriptionManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ShelvedItem.self,
            Goal.self,
            AppStats.self,
        ])
        // On a fresh install the "Application Support" folder doesn't
        // exist yet. If we let SwiftData create the store there itself, its
        // first attempt fails ("parent directory missing") and CoreData
        // runs a slow recovery pass that dumps hundreds of error lines —
        // which, with the Xcode debugger attached, stalls the very first
        // launch for many seconds (the fresh-install blank-screen delay).
        // Creating the folder ourselves first lets the store be created
        // cleanly on the first try, with no error spam and no stall.
        //
        // Passing an explicit `url` in the app's own sandbox also keeps the
        // store out of the shared App Group container that the widget's
        // entitlement would otherwise pull it into — the widget reads data
        // via WidgetSnapshot (shared UserDefaults), never SwiftData.
        let appSupport = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let storeURL = appSupport.appending(path: "Impulse.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

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
                .environmentObject(subscriptions)
                .task {
                    // Work out whether this person already has premium,
                    // then load what's for sale. RootView waits on a
                    // loading screen until this settles, so a subscriber
                    // never sees a flash of the paywall.
                    await subscriptions.start()
                }
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

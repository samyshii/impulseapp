//
//  MainTabView.swift
//  Impulse
//
//  The app's root screen: the three main tabs the user switches
//  between. This is what ImpulseApp shows first.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Which tab is showing — a notification tap can switch this even
    // when the user didn't tap the tab bar themselves.
    @State private var selectedTab: Tab = .shelf

    // Watches for notification taps so we know where to navigate.
    @ObservedObject private var notificationRouter = NotificationRouter.shared

    // The full-screen Weekly Recap, shown automatically once a week.
    @State private var isShowingWeeklyRecap = false
    @State private var weeklyRecapData: WeeklyRecapData?

    private enum Tab {
        case shelf, wins, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ShelfView()
                .tabItem {
                    Label("Shelf", systemImage: "shippingbox")
                }
                .tag(Tab.shelf)

            WinsView()
                .tabItem {
                    Label("Wins", systemImage: "trophy")
                }
                .tag(Tab.wins)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // A real "open" — resets the win-back inactivity clock,
                // then rebuilds every notification from current data.
                WinBackScheduler.recordAppOpen()
                NotificationScheduler.reconcileAll(context: modelContext)

                // If a not-yet-seen week is ready to be recapped, show it.
                if let data = WeeklyRecapAutoShow.checkForNewRecap(context: modelContext) {
                    weeklyRecapData = data
                    isShowingWeeklyRecap = true
                }
            case .background:
                // Last chance to make sure everything pending reflects
                // the latest state before the app is suspended.
                NotificationScheduler.reconcileAll(context: modelContext)
            default:
                break
            }
        }
        .onChange(of: notificationRouter.destination) { _, newValue in
            switch newValue {
            case .shelf, .decisionItem:
                selectedTab = .shelf
            case .wins:
                selectedTab = .wins
                notificationRouter.destination = nil
            case .settings:
                selectedTab = .settings
                notificationRouter.destination = nil
            case .none:
                break
            }
        }
        .fullScreenCover(isPresented: $isShowingWeeklyRecap) {
            if let weeklyRecapData {
                WeeklyRecapView(data: weeklyRecapData) {
                    isShowingWeeklyRecap = false
                    selectedTab = .wins
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionManager())
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

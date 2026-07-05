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
    var body: some View {
        TabView {
            ShelfView()
                .tabItem {
                    Label("Shelf", systemImage: "shippingbox")
                }

            WinsView()
                .tabItem {
                    Label("Wins", systemImage: "trophy")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

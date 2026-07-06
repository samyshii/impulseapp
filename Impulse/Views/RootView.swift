//
//  RootView.swift
//  Impulse
//
//  The very first thing ImpulseApp shows. Picks between the one-time
//  onboarding flow and the app's normal tabs, based on whether
//  onboarding has ever been completed before.
//
//  Once RevenueCat is wired up, this is where a paywall would slot in
//  between onboarding finishing and the tabs appearing — for now,
//  finishing onboarding goes straight to MainTabView.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

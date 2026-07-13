//
//  RootView.swift
//  Impulse
//
//  The very first thing ImpulseApp shows. Decides, in order:
//
//    1. Never onboarded?          → the one-time onboarding flow
//    2. Still checking the store?  → a plain loading screen
//    3. Not subscribed?            → the paywall, and no way past it
//    4. Otherwise                  → the normal app
//
//  Step 2 matters more than it looks. Working out whether someone has
//  already paid takes a moment, and if we showed the paywall while we
//  waited, every paying customer would see a paywall flash on every
//  launch. So we hold on a neutral screen until we actually know.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }
        } else if subscriptions.hasPremiumAccess {
            // Paying, or inside the free trial. This is also what makes
            // subscribers skip straight to the app on later launches.
            MainTabView()
        } else if subscriptions.loadState == .checking {
            SubscriptionLoadingView()
        } else {
            PaywallView()
        }
    }
}

/// The brief neutral screen shown while we work out what the user has
/// already paid for. Never the paywall — see the note at the top.
private struct SubscriptionLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            ProgressView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SubscriptionManager())
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

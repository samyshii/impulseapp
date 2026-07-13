//
//  PaywallView.swift
//  Impulse
//
//  The hard paywall. Shown once onboarding is done and stays in the way
//  until the user subscribes or starts a free trial.
//
//  This file only does LAYOUT and STATE. Every visual piece is its own
//  small view in this folder (header, features, plan picker, button,
//  footer), so the Figma restyle later is a matter of editing those
//  pieces one at a time without untangling any logic.
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    /// Which plan's radio button is filled in. Starts on annual.
    @State private var selectedPlanID: String?

    var body: some View {
        switch subscriptions.loadState {
        case .checking:
            ProgressView("Loading…")

        case .failed(let message):
            PaywallErrorView(message: message) {
                Task { await subscriptions.loadPlans() }
            }

        case .ready:
            planList
        }
    }

    private var planList: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    PaywallHeaderView()
                    PaywallFeatureList()

                    PaywallPlanPicker(
                        plans: subscriptions.plans,
                        selectedPlanID: $selectedPlanID
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }

            // Pinned to the bottom so the thing we want tapped is always
            // reachable without scrolling.
            VStack(spacing: 16) {
                PaywallPurchaseButton(
                    plan: selectedPlan,
                    isWorking: subscriptions.isWorking
                ) {
                    guard let selectedPlan else { return }
                    Task { await subscriptions.purchase(selectedPlan) }
                }

                PaywallFooterView(isWorking: subscriptions.isWorking) {
                    Task { await subscriptions.restore() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(.bar)
        }
        .onAppear(perform: selectDefaultPlan)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { subscriptions.errorMessage != nil },
                set: { if !$0 { subscriptions.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { subscriptions.errorMessage = nil }
        } message: {
            Text(subscriptions.errorMessage ?? "")
        }
    }

    private var selectedPlan: SubscriptionPlan? {
        subscriptions.plans.first { $0.id == selectedPlanID }
    }

    /// Preselect annual — it's the better value, and a paywall with
    /// nothing selected has no obvious thing to tap.
    private func selectDefaultPlan() {
        guard selectedPlanID == nil else { return }
        selectedPlanID = subscriptions.plans.first { $0.period == .annual }?.id
            ?? subscriptions.plans.first?.id
    }
}

/// Shown when the store can't be reached or has nothing to sell. On a
/// hard paywall this screen is the only thing between the user and the
/// app, so it must always offer a way forward.
private struct PaywallErrorView: View {
    let message: String
    let onRetry: () -> Void

#if DEBUG
    @EnvironmentObject private var subscriptions: SubscriptionManager
#endif

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)

            Text("Couldn't load subscriptions")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)

#if DEBUG
            // Developer-only. Without this, a store failure would lock
            // you out of your own app with no way in. Xcode strips this
            // out of any real App Store build.
            Button("Skip Paywall (Debug)") {
                subscriptions.debugBypassPaywall = true
            }
            .font(.footnote)
#endif
        }
        .padding(32)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}

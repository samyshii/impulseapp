//
//  PaywallPurchaseButton.swift
//  Impulse
//
//  The main call to action, plus the small print directly under it.
//
//  The wording changes with the chosen plan: someone who can still get
//  the free trial is asked to start a trial, not to pay. Apple also
//  requires that the price and the auto-renewing nature of the
//  subscription are visible right where the user commits — that's the
//  line under the button.
//

import SwiftUI

struct PaywallPurchaseButton: View {
    let plan: SubscriptionPlan?
    let isWorking: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onPurchase) {
                Group {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text(buttonTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(plan == nil || isWorking)

            Text(smallPrint)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var buttonTitle: String {
        guard let plan else { return "Continue" }
        return plan.isEligibleForFreeTrial
            ? "Start \(PurchaseConfig.freeTrialDays)-Day Free Trial"
            : "Subscribe"
    }

    /// e.g. "7 days free, then $29.99 / year. Renews automatically.
    ///       Cancel anytime."
    private var smallPrint: String {
        guard let plan else { return " " }

        let price = plan.priceWithPeriod
        let lead = plan.isEligibleForFreeTrial
            ? "\(PurchaseConfig.freeTrialDays) days free, then \(price)."
            : "\(price)."

        return lead + " Renews automatically. Cancel anytime."
    }
}

#Preview {
    VStack(spacing: 32) {
        PaywallPurchaseButton(
            plan: SubscriptionPlan(id: "annual", period: .annual, displayPrice: "$29.99", isEligibleForFreeTrial: true),
            isWorking: false,
            onPurchase: {}
        )

        PaywallPurchaseButton(
            plan: SubscriptionPlan(id: "monthly", period: .monthly, displayPrice: "$4.99", isEligibleForFreeTrial: false),
            isWorking: false,
            onPurchase: {}
        )
    }
    .padding()
}

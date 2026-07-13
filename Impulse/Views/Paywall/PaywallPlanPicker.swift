//
//  PaywallPlanPicker.swift
//  Impulse
//
//  The monthly vs annual chooser. Two tappable rows with a radio dot.
//  `PaywallPlanOption` (one row) is split out so the Figma restyle can
//  redraw a single row without touching the selection logic.
//

import SwiftUI

struct PaywallPlanPicker: View {
    let plans: [SubscriptionPlan]

    /// The product ID of whichever row is currently chosen.
    @Binding var selectedPlanID: String?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(plans) { plan in
                PaywallPlanOption(
                    plan: plan,
                    isSelected: plan.id == selectedPlanID,
                    savingsBadge: savingsBadge(for: plan)
                ) {
                    selectedPlanID = plan.id
                }
            }
        }
    }

    /// "Save 50%" on the annual row — worked out from the real prices
    /// rather than hardcoded, so it stays honest if prices change.
    private func savingsBadge(for plan: SubscriptionPlan) -> String? {
        guard plan.period == .annual,
              let monthly = plans.first(where: { $0.period == .monthly }),
              let monthlyPrice = Self.numericPrice(monthly.displayPrice),
              let annualPrice = Self.numericPrice(plan.displayPrice),
              monthlyPrice > 0
        else { return nil }

        let yearAtMonthlyRate = monthlyPrice * 12
        guard yearAtMonthlyRate > annualPrice else { return nil }

        let saved = (yearAtMonthlyRate - annualPrice) / yearAtMonthlyRate
        return "Save \(Int((saved * 100).rounded()))%"
    }

    /// Pull the number back out of a store-formatted price like "$4.99".
    /// Strips currency symbols and handles both "4.99" and "4,99".
    private static func numericPrice(_ displayPrice: String) -> Double? {
        let digits = displayPrice.filter { $0.isNumber || $0 == "." || $0 == "," }
        return Double(digits.replacingOccurrences(of: ",", with: "."))
    }
}

/// A single selectable plan row.
struct PaywallPlanOption: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let savingsBadge: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)

                        if let savingsBadge {
                            Text(savingsBadge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.tint, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    Text(plan.priceWithPeriod)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let trial = plan.freeTrialDescription {
                        Text(trial)
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallPlanPicker(
        plans: [
            SubscriptionPlan(id: "annual", period: .annual, displayPrice: "$29.99", isEligibleForFreeTrial: true),
            SubscriptionPlan(id: "monthly", period: .monthly, displayPrice: "$4.99", isEligibleForFreeTrial: true),
        ],
        selectedPlanID: .constant("annual")
    )
    .padding()
}

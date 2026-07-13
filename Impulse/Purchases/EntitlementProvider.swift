//
//  EntitlementProvider.swift
//  Impulse
//
//  The thin contract that both purchase backends (Apple's StoreKit and
//  RevenueCat) promise to fulfil. Because they both speak this same
//  small language, the paywall screen and RootView can be written once
//  and work with either — and swapping backends can't break the UI.
//
//  This is also what keeps the paywall easy to restyle later: the
//  views only ever see a `SubscriptionPlan`, never a StoreKit `Product`
//  or a RevenueCat `Package`.
//

import Foundation

/// One thing the user can buy, described in plain terms the paywall can
/// draw directly. Deliberately knows nothing about StoreKit or
/// RevenueCat — each backend translates its own objects into this.
struct SubscriptionPlan: Identifiable, Equatable {

    enum Period {
        case monthly
        case annual
    }

    /// The product identifier, e.g. "com.samshi.Impulse.premium.monthly".
    /// Also how we ask a backend to buy this exact thing later.
    let id: String

    let period: Period

    /// Already formatted in the user's own currency by the store,
    /// e.g. "$4.99". Never build this by hand — a French user should
    /// see "4,99 €".
    let displayPrice: String

    /// True when this user would actually get the free trial if they
    /// bought right now. Apple only gives a trial once per subscription
    /// group, so someone who already trialled monthly will see this as
    /// false on annual.
    let isEligibleForFreeTrial: Bool

    /// "7 days free" — or nil when there's no trial to offer.
    var freeTrialDescription: String? {
        guard isEligibleForFreeTrial else { return nil }
        return "\(PurchaseConfig.freeTrialDays) days free"
    }

    /// "$4.99 / month" — the price with its billing period attached.
    var priceWithPeriod: String {
        switch period {
        case .monthly: return "\(displayPrice) / month"
        case .annual: return "\(displayPrice) / year"
        }
    }

    var title: String {
        switch period {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
}

/// What happened when the user tried to buy something.
enum PurchaseOutcome {
    /// They paid (or started their trial) and now have access.
    case subscribed
    /// They backed out of the purchase sheet. Not an error — say nothing.
    case cancelled
    /// Apple needs to approve it first (e.g. Ask to Buy for a child
    /// account). They don't have access yet.
    case pending
}

/// The contract. Both backends implement exactly this.
@MainActor
protocol EntitlementProvider: AnyObject {

    /// Called once at app launch, before anything else.
    func configure()

    /// Fetch the things we can sell. Throws if the store can't be
    /// reached or nothing is set up.
    func loadPlans() async throws -> [SubscriptionPlan]

    /// Does this user currently have premium? Covers both "paying" and
    /// "in their free trial" — we don't distinguish, both get in.
    func isSubscribed() async -> Bool

    /// Buy one of the plans returned by `loadPlans()`.
    func purchase(planID: String) async throws -> PurchaseOutcome

    /// Re-apply a subscription this person already bought (new phone,
    /// reinstall, etc). Apple requires we offer this. Returns whether
    /// they have premium afterwards.
    func restore() async throws -> Bool

    /// Fires whenever the subscription changes behind our back — a
    /// renewal, an expiry, a purchase made on another device.
    var onEntitlementChanged: (@MainActor (Bool) -> Void)? { get set }
}

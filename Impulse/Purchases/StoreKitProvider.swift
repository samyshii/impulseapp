//
//  StoreKitProvider.swift
//  Impulse
//
//  Buys things using Apple's own StoreKit, straight from the fake
//  products in Impulse.storekit. No accounts, no internet, no
//  RevenueCat — this is what makes the paywall fully testable in the
//  Simulator today, including Apple's real "7 days free" purchase sheet.
//
//  Active when PurchaseConfig.activeBackend == .localStoreKit.
//

import Foundation
import StoreKit

@MainActor
final class StoreKitProvider: EntitlementProvider {

    var onEntitlementChanged: (@MainActor (Bool) -> Void)?

    /// The real StoreKit products, kept so we can buy one by ID later.
    private var products: [String: Product] = [:]

    /// Watches for subscription changes that happen outside the app —
    /// a renewal overnight, an expiry, a purchase on another device.
    private var updatesTask: Task<Void, Never>?

    func configure() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                // A verified transaction arrived. Close it out and let
                // the app know their access may have changed.
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                guard let self else { return }
                let subscribed = await self.isSubscribed()
                self.onEntitlementChanged?(subscribed)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadPlans() async throws -> [SubscriptionPlan] {
        let fetched = try await Product.products(for: PurchaseConfig.allProductIDs)

        products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })

        var plans: [SubscriptionPlan] = []
        for product in fetched {
            guard let period = Self.period(for: product.id) else { continue }
            plans.append(
                SubscriptionPlan(
                    id: product.id,
                    period: period,
                    displayPrice: product.displayPrice,
                    isEligibleForFreeTrial: await Self.isEligibleForTrial(product)
                )
            )
        }
        return plans
    }

    func isSubscribed() async -> Bool {
        // Everything the user currently has a right to. StoreKit keeps
        // this cached on the device, so it works offline and returns
        // fast on launch.
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard PurchaseConfig.allProductIDs.contains(transaction.productID) else { continue }
            // A refunded or upgraded-away subscription is still listed,
            // but with a revocation date — that person has lost access.
            if transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    func purchase(planID: String) async throws -> PurchaseOutcome {
        guard let product = products[planID] else {
            throw PurchaseError.productNotFound
        }

        switch try await product.purchase() {
        case .success(let verification):
            // StoreKit signs every purchase. `.unverified` means the
            // signature didn't check out, so we refuse to grant access.
            guard case .verified(let transaction) = verification else {
                throw PurchaseError.notVerified
            }
            // Tell StoreKit we've handed over the goods, otherwise it
            // will keep re-delivering this transaction forever.
            await transaction.finish()
            return .subscribed

        case .userCancelled:
            return .cancelled

        case .pending:
            // e.g. a child account waiting on Ask to Buy approval.
            return .pending

        @unknown default:
            throw PurchaseError.unknown
        }
    }

    func restore() async throws -> Bool {
        // Pulls this Apple Account's purchases down again. May show a
        // sign-in prompt, which is why it's only ever called from an
        // explicit "Restore Purchases" tap.
        try await AppStore.sync()
        return await isSubscribed()
    }

    // MARK: - Helpers

    /// Whether this person would actually get the free trial. Apple only
    /// gives one trial per subscription group ever, so someone who
    /// already used it on monthly gets `false` here on annual.
    private static func isEligibleForTrial(_ product: Product) async -> Bool {
        guard let subscription = product.subscription,
              let offer = subscription.introductoryOffer,
              offer.paymentMode == .freeTrial
        else { return false }

        return await subscription.isEligibleForIntroOffer
    }

    private static func period(for productID: String) -> SubscriptionPlan.Period? {
        switch productID {
        case PurchaseConfig.monthlyProductID: return .monthly
        case PurchaseConfig.annualProductID: return .annual
        default: return nil
        }
    }

    enum PurchaseError: LocalizedError {
        case productNotFound
        case notVerified
        case unknown

        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "That subscription isn't available right now."
            case .notVerified:
                return "We couldn't verify that purchase with Apple."
            case .unknown:
                return "Something went wrong with the purchase."
            }
        }
    }
}

//
//  RevenueCatProvider.swift
//  Impulse
//
//  Buys things using RevenueCat. This is the backend the real, shipped
//  app will use — access is granted by RevenueCat's "premium"
//  entitlement, decided on their servers, not on the phone.
//
//  Active when PurchaseConfig.activeBackend == .revenueCat.
//
//  NOTE while testing: with a "test_" key, RevenueCat uses the Test
//  Store. It ignores Impulse.storekit entirely and sells the products
//  you set up on the RevenueCat website instead — and it cannot do free
//  trials yet, so the trial wording won't appear in this mode. That's a
//  RevenueCat limitation, not a bug here. Use .localStoreKit to see the
//  trial.
//

import Foundation
import RevenueCat

@MainActor
final class RevenueCatProvider: EntitlementProvider {

    var onEntitlementChanged: (@MainActor (Bool) -> Void)?

    /// RevenueCat's own objects for each plan, kept so we can buy one by
    /// product ID later.
    private var packages: [String: Package] = [:]

    private var updatesTask: Task<Void, Never>?

    func configure() {
        // Calling configure twice would crash, so make sure we only
        // ever do it once.
        guard !Purchases.isConfigured else { return }

#if DEBUG
        // Prints RevenueCat's reasoning to the Xcode console. Very
        // useful when products don't show up.
        Purchases.logLevel = .debug
#endif

        Purchases.configure(withAPIKey: PurchaseConfig.revenueCatAPIKey)

        // RevenueCat pushes us a fresh CustomerInfo whenever the
        // subscription changes — renewed, expired, bought elsewhere.
        updatesTask = Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                self?.onEntitlementChanged?(Self.hasPremium(customerInfo))
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadPlans() async throws -> [SubscriptionPlan] {
        // An "Offering" is the set of things RevenueCat is currently
        // told to sell. `current` is the one marked as default on the
        // RevenueCat website.
        let offerings = try await Purchases.shared.offerings()

        guard let offering = offerings.current else {
            throw PurchaseError.noOffering
        }

        packages = Dictionary(
            uniqueKeysWithValues: offering.availablePackages.map {
                ($0.storeProduct.productIdentifier, $0)
            }
        )

        return offering.availablePackages.compactMap { package in
            let product = package.storeProduct

            // Work out monthly-vs-annual from RevenueCat's PACKAGE TYPE
            // ($rc_monthly / $rc_annual), not from the product ID.
            //
            // Package type is RevenueCat's own idea of "what shape of
            // plan is this", so it keeps working no matter what the
            // products end up being called in the dashboard. Matching on
            // product IDs instead would silently show an empty paywall
            // the moment a name didn't line up.
            //
            // Anything else in the offering (a lifetime plan, say) is
            // ignored on purpose — this paywall sells two things.
            guard let period = Self.period(for: package.packageType) else {
                return nil
            }

            return SubscriptionPlan(
                id: product.productIdentifier,
                period: period,
                displayPrice: product.localizedPriceString,
                isEligibleForFreeTrial: product.introductoryDiscount?.paymentMode == .freeTrial
            )
        }
    }

    func isSubscribed() async -> Bool {
        // RevenueCat caches this on the device, so it answers instantly
        // on launch and still works with no network.
        guard let customerInfo = try? await Purchases.shared.customerInfo() else {
            return false
        }
        return Self.hasPremium(customerInfo)
    }

    func purchase(planID: String) async throws -> PurchaseOutcome {
        guard let package = packages[planID] else {
            throw PurchaseError.productNotFound
        }

        let result = try await Purchases.shared.purchase(package: package)

        if result.userCancelled {
            return .cancelled
        }

        // The single source of truth: did RevenueCat actually turn the
        // "premium" entitlement on for this customer?
        return Self.hasPremium(result.customerInfo) ? .subscribed : .pending
    }

    func restore() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        return Self.hasPremium(customerInfo)
    }

    // MARK: - Helpers

    /// The one place the "premium" entitlement is actually checked.
    private static func hasPremium(_ customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements[PurchaseConfig.premiumEntitlementID]?.isActive == true
    }

    private static func period(for packageType: PackageType) -> SubscriptionPlan.Period? {
        switch packageType {
        case .monthly: return .monthly
        case .annual: return .annual
        default: return nil
        }
    }

    enum PurchaseError: LocalizedError {
        case noOffering
        case productNotFound

        var errorDescription: String? {
            switch self {
            case .noOffering:
                return "RevenueCat has no current Offering. Create one and mark it as default."
            case .productNotFound:
                return "That subscription isn't available right now."
            }
        }
    }
}

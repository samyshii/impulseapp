//
//  SubscriptionManager.swift
//  Impulse
//
//  The one object the rest of the app talks to about money. RootView
//  asks it "does this person have premium?", and the paywall asks it to
//  buy or restore. It hands the actual work to whichever backend
//  PurchaseConfig picked, and never lets that choice leak out.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {

    /// Where we are in loading what's for sale.
    enum LoadState: Equatable {
        /// Still working out whether this person has already paid. We
        /// show a plain "loading" screen here — crucially NOT the
        /// paywall, so a paying customer never sees a paywall flash.
        case checking
        /// Ready — `plans` is populated.
        case ready
        /// Couldn't reach the store / nothing is set up to sell.
        case failed(String)
    }

    @Published private(set) var loadState: LoadState = .checking

    /// What the user can buy. Empty until loadState == .ready.
    @Published private(set) var plans: [SubscriptionPlan] = []

    /// True when the user is paying OR inside their free trial.
    @Published private(set) var isSubscribed = false

    /// True while a purchase or restore is in flight, so the paywall can
    /// disable its buttons and show a spinner.
    @Published private(set) var isWorking = false

    /// Set when a purchase or restore fails, for the paywall to show.
    @Published var errorMessage: String?

#if DEBUG
    /// ESCAPE HATCH. A hard paywall means that if the store ever fails
    /// to load, you'd be locked out of your own app with no way in.
    /// This lets you skip the paywall while developing.
    ///
    /// It is wrapped in `#if DEBUG`, which means Xcode physically
    /// deletes it from a real App Store build — it cannot ship.
    @Published var debugBypassPaywall = false
#endif

    /// The single question the rest of the app asks. RootView shows the
    /// main shelf when this is true, and the paywall when it's false.
    var hasPremiumAccess: Bool {
#if DEBUG
        return isSubscribed || debugBypassPaywall
#else
        return isSubscribed
#endif
    }

    private let provider: EntitlementProvider

    init() {
        // The switch in PurchaseConfig decides who does the real work.
        switch PurchaseConfig.activeBackend {
        case .localStoreKit:
            provider = StoreKitProvider()
        case .revenueCat:
            provider = RevenueCatProvider()
        }

        provider.configure()

        // Subscriptions can change without the user touching the
        // paywall — a renewal, an expiry, a purchase on their iPad. The
        // backend tells us, and the UI follows automatically.
        provider.onEntitlementChanged = { [weak self] subscribed in
            self?.isSubscribed = subscribed
        }
    }

    /// Called once when the app launches. Works out whether this person
    /// already has premium, then loads what's for sale.
    func start() async {
        // Check entitlement FIRST. This is the fast, offline-friendly
        // check (both backends cache it locally), so a subscriber gets
        // waved through to the app even if the store is slow or the
        // network is down.
        isSubscribed = await provider.isSubscribed()

        if isSubscribed {
            // Already paid — they're going straight to the shelf, so
            // don't make them wait on a product list they'll never see.
            loadState = .ready
            return
        }

        await loadPlans()
    }

    /// Fetch what's for sale. Also used by the paywall's "Try again".
    func loadPlans() async {
        loadState = .checking

        do {
            let loaded = try await provider.loadPlans()

            guard !loaded.isEmpty else {
                loadState = .failed(Self.noProductsMessage)
                return
            }

            // Annual first — it's the better deal, so it's the one we
            // want the eye to land on.
            plans = loaded.sorted { Self.displayRank($0.period) < Self.displayRank($1.period) }
            loadState = .ready
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Buy a plan. Returns quietly if the user simply changed their mind.
    func purchase(_ plan: SubscriptionPlan) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            switch try await provider.purchase(planID: plan.id) {
            case .subscribed:
                isSubscribed = true
            case .cancelled:
                // They tapped Cancel. That's not a failure — say nothing.
                break
            case .pending:
                errorMessage = "Your purchase needs approval before it can finish. You'll get access as soon as it's approved."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Re-apply a subscription bought earlier (reinstall, new phone).
    func restore() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let restored = try await provider.restore()
            isSubscribed = restored

            if !restored {
                errorMessage = "We couldn't find a previous subscription for this Apple Account."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The order plans appear in on the paywall. Annual first.
    private static func displayRank(_ period: SubscriptionPlan.Period) -> Int {
        switch period {
        case .annual: return 0
        case .monthly: return 1
        }
    }

    /// Shown when the store connects fine but has nothing to sell —
    /// almost always a setup problem, so the message says what to fix.
    private static var noProductsMessage: String {
        switch PurchaseConfig.activeBackend {
        case .localStoreKit:
            return "No products found. Check that Impulse.storekit is selected under Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration."
        case .revenueCat:
            return "No products found. In RevenueCat, check that your current Offering has a Monthly ($rc_monthly) and an Annual ($rc_annual) package, and that both are attached to the \"premium\" entitlement."
        }
    }
}

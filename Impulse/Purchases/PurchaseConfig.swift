//
//  PurchaseConfig.swift
//  Impulse
//
//  Every knob for the paywall lives here, so nothing is hardcoded
//  somewhere awkward. If you only ever open one purchases file, open
//  this one.
//
//  WHY THERE ARE TWO BACKENDS
//  --------------------------
//  We can buy things two different ways, and which one is switched on
//  is decided by `activeBackend` below.
//
//  1. .localStoreKit — Apple's own StoreKit, reading the fake products
//     in Impulse.storekit. This needs NO accounts and NO internet. It
//     shows Apple's REAL purchase sheet, including the real
//     "7 days free, then $4.99/month" trial. This is the only way to
//     see the free trial until you have an Apple Developer account.
//
//  2. .revenueCat — the real RevenueCat SDK, talking to RevenueCat's
//     Test Store. This proves the actual "premium" entitlement works
//     end to end. BUT RevenueCat's Test Store cannot do free trials
//     yet (their words, not ours), and it ignores Impulse.storekit
//     completely — it uses the products you set up on their website.
//
//  Same paywall screen either way. The screen never knows or cares
//  which one is running.
//

import Foundation

enum PurchaseBackend {
    case localStoreKit
    case revenueCat
}

enum PurchaseConfig {

    // ---------------------------------------------------------------
    // THE SWITCH. Change this one line to swap backends.
    // ---------------------------------------------------------------
    //
    // Right now: .localStoreKit, so the app just works when you hit
    // Cmd+R — no setup, and you get to see the real 7-day free trial.
    //
    // Change it to .revenueCat once you've done the four setup steps
    // on the RevenueCat website (create the two products, create the
    // "premium" entitlement, put both products in it, and put both
    // products in an offering). Until those exist, .revenueCat will
    // correctly report that it found no products to sell.
    static let activeBackend: PurchaseBackend = .localStoreKit

    // Your RevenueCat Test Store key. Only used when activeBackend is
    // .revenueCat. This is a *public* key — it's designed to ship
    // inside the app, so it is not a secret and it's safe here.
    //
    // The "test_" prefix is what tells RevenueCat to use the Test
    // Store. A key starting with "appl_" would talk to the real App
    // Store instead, which you can't use until you have an Apple
    // Developer account.
    static let revenueCatAPIKey = "test_WWLFenTdSdxdZShpRCBtvBqhOoU"

    // The RevenueCat entitlement that means "this person has paid".
    // The whole app is gated on this one string.
    static let premiumEntitlementID = "premium"

    // The two things we sell. These IDs must match, exactly:
    //   - the products in Impulse.storekit  (for .localStoreKit)
    //   - the products on the RevenueCat website (for .revenueCat)
    static let monthlyProductID = "com.samshi.Impulse.premium.monthly"
    static let annualProductID = "com.samshi.Impulse.premium.annual"

    static let allProductIDs: Set<String> = [monthlyProductID, annualProductID]

    // How long the free trial is. Used only for the words on screen —
    // the real trial length comes from Impulse.storekit / RevenueCat.
    static let freeTrialDays = 7

    // TODO: Swap these for the real pages before shipping. Apple
    // requires both to be reachable from the paywall.
    static let termsURL = URL(string: "https://example.com/impulse/terms")!
    static let privacyURL = URL(string: "https://example.com/impulse/privacy")!
}

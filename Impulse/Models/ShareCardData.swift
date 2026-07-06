//
//  ShareCardData.swift
//  Impulse
//
//  The numbers behind one shareable win card — kept separate from the
//  view so both the decision flow (this one win) and the Weekly Recap
//  (the week's best win) can build the same card from their own data.
//

import Foundation

struct ShareCardData {
    let headline: String
    let winAmount: Decimal
    let totalSaved: Decimal
    let weeklyStreak: Int
}

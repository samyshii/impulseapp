//
//  Goal.swift
//  Impulse
//
//  A savings goal the user is working toward, e.g. "New laptop — $1200".
//

import Foundation
import SwiftData

@Model
final class Goal {
    // What the user is saving up for.
    var name: String

    // How much money the user wants to save in total.
    var targetAmount: Decimal

    // When the goal was created.
    var createdAt: Date

    // A small head start added automatically when the goal is created,
    // equal to 5% of the target amount. Gives the progress bar a little
    // motivating nudge right from the start.
    //
    // This is always 5% of whatever the CURRENT target is, so it has to
    // be recalculated any time the target changes — see `update` below.
    var starterBoost: Decimal

    private static let boostFraction: Decimal = 0.05

    init(name: String, targetAmount: Decimal, createdAt: Date = .now) {
        self.name = name
        self.targetAmount = targetAmount
        self.createdAt = createdAt
        self.starterBoost = targetAmount * Self.boostFraction
    }

    // The only way the Edit Goal screen should change a goal. Setting
    // `targetAmount` on its own would leave `starterBoost` stuck at 5%
    // of the OLD target, which throws the progress bar off — and if the
    // new target were lower than the old boost, the bar would jump
    // straight to "Goal reached!" with nothing actually saved.
    func update(name: String, targetAmount: Decimal) {
        self.name = name
        self.targetAmount = targetAmount
        self.starterBoost = targetAmount * Self.boostFraction
    }
}

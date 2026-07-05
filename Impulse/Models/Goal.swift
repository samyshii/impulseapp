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
    var starterBoost: Decimal

    init(name: String, targetAmount: Decimal, createdAt: Date = .now) {
        self.name = name
        self.targetAmount = targetAmount
        self.createdAt = createdAt
        self.starterBoost = targetAmount * 0.05
    }
}

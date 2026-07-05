//
//  NotificationCopy.swift
//  Impulse
//
//  All the friendly wording for notifications lives here, in one spot,
//  so tone stays consistent. Where a moment repeats often (Decision
//  Time, the weekly recap), we keep a few variations and pick one at
//  random each time so it doesn't feel like a robot sending the same
//  line over and over.
//

import Foundation

enum NotificationCopy {

    // MARK: - Decision Time

    private static let singleItemTemplates = [
        "Your cooldown on %@ just ended. Ready to decide?",
        "Time's up on %@ — buy it or let it go?",
        "%@ is off the shelf and waiting on your call.",
        "Decision time: %@ is ready for you."
    ]

    private static let multiItemTemplates = [
        "%d items just came off the shelf. Time to decide.",
        "%d things are ready for your verdict.",
        "Your shelf has %d decisions waiting.",
        "%d cooldowns just ended — go take a look."
    ]

    static func decisionTime(itemNames: [String]) -> (title: String, body: String) {
        if itemNames.count == 1, let name = itemNames.first {
            let body = String(format: singleItemTemplates.randomElement()!, name)
            return ("Ready to decide", body)
        }
        let body = String(format: multiItemTemplates.randomElement()!, itemNames.count)
        return ("Ready to decide", body)
    }

    // MARK: - Weekly Recap

    static func weeklyRecapActive(savedThisWeek: Decimal, winsCount: Int) -> (title: String, body: String) {
        let amount = savedThisWeek.formatted(.currency(code: "USD"))
        let plural = winsCount == 1 ? "thing" : "things"
        let templates = [
            "This week you let go of \(winsCount) \(plural) and saved \(amount). Nice work.",
            "Your week in review: \(amount) saved, \(winsCount) win\(winsCount == 1 ? "" : "s") on the board.",
            "\(amount) saved this week. Future you says thanks."
        ]
        return ("Your weekly recap", templates.randomElement()!)
    }

    static func weeklyRecapQuiet() -> (title: String, body: String) {
        let templates = [
            "Anything tempting you lately? The shelf is open.",
            "Quiet week. The shelf's ready whenever something catches your eye.",
            "No activity this week — that's fine too. The shelf's here when you need it."
        ]
        return ("Just checking in", templates.randomElement()!)
    }

    // MARK: - Streak Guard

    static func streakGuard(streakWeeks: Int, shieldAvailable: Bool) -> (title: String, body: String) {
        if shieldAvailable {
            let templates = [
                "No win yet this week, but your \(streakWeeks)-week streak is covered — the streak shield has you if you don't make it in time.",
                "No stress: no win logged yet, and your streak shield can cover this week if needed."
            ]
            return ("Streak check-in", templates.randomElement()!)
        } else {
            let templates = [
                "Your \(streakWeeks)-week streak needs a win before the week's out — the shield's already been used this month.",
                "Heads up: no shield left this month. One win today keeps your \(streakWeeks)-week streak alive."
            ]
            return ("Streak check-in", templates.randomElement()!)
        }
    }

    // MARK: - Milestones

    static func milestone(reached: [MilestoneKind]) -> (title: String, body: String) {
        guard reached.count > 1 else {
            return reached.first?.soloCopy() ?? ("Milestone", "You reached a milestone.")
        }
        let joined = reached.map(\.shortLabel).joined(separator: " and ")
        return ("Huge milestone!", "You just hit \(joined) — all in one go. Amazing.")
    }

    // MARK: - Win-back

    static let winBack10 = (title: "We miss you", body: "Your shelf misses you. Even one shelved item counts.")
    static let winBack30 = (title: "See you around", body: "We'll be here next time something tempting shows up.")
}

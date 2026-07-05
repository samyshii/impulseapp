//
//  MilestoneNotifier.swift
//  Impulse
//
//  Fires an immediate, real-time notification the moment the user
//  earns a genuine milestone: their first-ever win, $100 saved, $500
//  saved, halfway to their goal, or the goal fully completed. Called
//  directly from DecisionFlowView right when a "let go" win is
//  recorded, with the before/after totals from that exact moment —
//  that's what lets it detect a threshold being crossed, rather than
//  just being past it.
//

import Foundation

enum MilestoneKind {
    case firstWin
    case saved100
    case saved500
    case goalHalfway
    case goalComplete

    var shortLabel: String {
        switch self {
        case .firstWin: return "your first win"
        case .saved100: return "$100 saved"
        case .saved500: return "$500 saved"
        case .goalHalfway: return "halfway to your goal"
        case .goalComplete: return "your goal"
        }
    }

    func soloCopy() -> (title: String, body: String) {
        switch self {
        case .firstWin:
            return ("First win!", "You just let your first item go. That's how the streak starts.")
        case .saved100:
            return ("$100 saved", "You've saved $100 by letting things go. Keep it up.")
        case .saved500:
            return ("$500 saved", "$500 saved and counting. That's a real number.")
        case .goalHalfway:
            return ("Halfway there", "You're 50% of the way to your goal.")
        case .goalComplete:
            return ("Goal reached!", "You did it — your savings goal is complete.")
        }
    }
}

@MainActor
enum MilestoneNotifier {
    private static let lastFiredKey = "lastMilestoneFiredAt"
    private static let halfwayNotifiedKey = "goalHalfwayNotifiedGoalKey"
    private static let completeNotifiedKey = "goalCompleteNotifiedGoalKey"

    // Whether a milestone notification has already gone out today — the
    // routine schedulers check this so they don't also land today.
    static var firedToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: lastFiredKey) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    static func checkAndNotify(
        isFirstWinEver: Bool,
        totalBefore: Decimal,
        totalAfter: Decimal,
        goal: Goal?,
        enabled: Bool
    ) {
        guard enabled else { return }

        var reached: [MilestoneKind] = []

        if isFirstWinEver {
            reached.append(.firstWin)
        }
        if totalBefore < 100, totalAfter >= 100 {
            reached.append(.saved100)
        }
        if totalBefore < 500, totalAfter >= 500 {
            reached.append(.saved500)
        }
        if let goal, goal.targetAmount > 0 {
            let goalKey = "\(goal.name)-\(goal.targetAmount)"
            let fractionBefore = fraction(total: totalBefore, goal: goal)
            let fractionAfter = fraction(total: totalAfter, goal: goal)

            if fractionBefore < 0.5, fractionAfter >= 0.5, UserDefaults.standard.string(forKey: halfwayNotifiedKey) != goalKey {
                reached.append(.goalHalfway)
                UserDefaults.standard.set(goalKey, forKey: halfwayNotifiedKey)
            }
            if fractionBefore < 1.0, fractionAfter >= 1.0, UserDefaults.standard.string(forKey: completeNotifiedKey) != goalKey {
                reached.append(.goalComplete)
                UserDefaults.standard.set(goalKey, forKey: completeNotifiedKey)
            }
        }

        guard !reached.isEmpty else { return }

        let (title, body) = NotificationCopy.milestone(reached: reached)
        NotificationScheduler.fireNow(identifier: "milestone-\(UUID().uuidString)", title: title, body: body, type: "milestone")
        UserDefaults.standard.set(Date(), forKey: lastFiredKey)
    }

    private static func fraction(total: Decimal, goal: Goal) -> Double {
        let progress = min(total + goal.starterBoost, goal.targetAmount)
        return NSDecimalNumber(decimal: progress / goal.targetAmount).doubleValue
    }
}

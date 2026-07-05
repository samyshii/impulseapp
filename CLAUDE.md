# Impulse

An iOS app (iOS 17+, iPhone only) that helps users curb impulse buying.

## What the app does

1. User "shelves" an item they're tempted to buy (name + price).
2. A cooldown timer runs on that item.
3. When the cooldown ends, the user decides:
   - **Buy guilt-free** — they still want it, no penalty.
   - **Let it go** — they skip the purchase, and the item's price is added to:
     - A running **Saved** total.
     - A **Goal** progress bar (savings goal the user sets).
     - Their **weekly streak** (consecutive weeks of letting at least one item go, or similar streak logic — refine as features are built).

## Working rules

- **Stack**: SwiftUI + SwiftData only. No third-party packages, with one exception: RevenueCat, and only once the user explicitly says to add it later. Do not add any other dependency without asking.
- **File size & comments**: Keep every file small and focused (one view/model/responsibility per file). Add plain-English comments explaining what each part does — the user cannot code and reads comments to follow along.
- **User workflow**: The user is a complete beginner who cannot write or read code fluently. They run the app in Xcode and report back what they see. After finishing any task, always tell them exactly what to do in Xcode to see the result (e.g., which file/scheme to select, Cmd+R, which screen or button to check, what output to expect).
- **Build verification**: Before telling the user a task is done, run `xcodebuild` to confirm the project compiles. Only report completion after a clean build.
- **Git**: Use git. Commit after each working feature with a clear, descriptive commit message.

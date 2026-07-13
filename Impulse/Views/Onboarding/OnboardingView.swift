//
//  OnboardingView.swift
//  Impulse
//
//  The 3-page, swipeable flow shown only the very first time the app
//  is ever launched (RootView decides that part). Holds the goal name
//  and target the user types on page 2, and creates that Goal — if
//  they actually filled one in — once they finish on page 3.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    // Called once onboarding is done, either way — RootView flips the
    // "onboarding complete" flag and swaps in the normal tabs.
    var onFinished: () -> Void

    @State private var currentPage = 0

    @State private var goalName = ""
    @State private var goalTarget: Decimal = 0
    // True only when the user explicitly tapped "Skip for now" — lets
    // us tell "deliberately skipped" apart from "just hasn't typed
    // anything yet", so a half-filled draft isn't silently saved.
    @State private var isSkippingGoal = false

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingWelcomePage(onNext: goToGoalPage)
                .tag(0)

            OnboardingGoalPage(
                goalName: $goalName,
                goalTarget: $goalTarget,
                onNext: goToHowItWorksPage,
                onSkip: skipGoalAndContinue
            )
            .tag(1)

            OnboardingHowItWorksPage(onStart: finish)
                .tag(2)
        }
        // The system's dots are hidden because each page now draws its own
        // (OnboardingPageDots), sitting just above the button where the
        // eye already is. Swiping between pages still works exactly as before.
        .tabViewStyle(.page(indexDisplayMode: .never))
        // A TabView won't let its pages paint under the status bar, which
        // otherwise leaves a white strip along the top edge. Painting the
        // paper behind the whole TabView fills it.
        .background(OnboardingTheme.Palette.paper.ignoresSafeArea())
        .animation(.easeInOut, value: currentPage)
        // Editing the goal fields after skipping means the user changed
        // their mind — un-skip so a valid goal gets created after all.
        .onChange(of: goalName) { _, _ in isSkippingGoal = false }
        .onChange(of: goalTarget) { _, _ in isSkippingGoal = false }
    }

    private func goToGoalPage() {
        currentPage = 1
    }

    private func goToHowItWorksPage() {
        isSkippingGoal = false
        currentPage = 2
    }

    private func skipGoalAndContinue() {
        isSkippingGoal = true
        currentPage = 2
    }

    private func finish() {
        let trimmedName = goalName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !isSkippingGoal, !trimmedName.isEmpty, goalTarget > 0 {
            modelContext.insert(Goal(name: trimmedName, targetAmount: goalTarget))
        }
        onFinished()
    }
}

#Preview {
    OnboardingView(onFinished: {})
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

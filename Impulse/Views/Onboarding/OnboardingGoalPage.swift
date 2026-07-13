//
//  OnboardingGoalPage.swift
//  Impulse
//
//  Onboarding page 2: an optional first savings goal. Not required —
//  "Skip for now" moves on without setting one.
//
//  Styled to "Cobalt on Paper". The fields, their bindings, the keyboard
//  type, the focus state and the "can I continue yet?" rule are all
//  exactly as they were — only the paint changed.
//

import SwiftUI

struct OnboardingGoalPage: View {
    @Binding var goalName: String
    @Binding var goalTarget: Decimal
    var onNext: () -> Void
    var onSkip: () -> Void

    @FocusState private var isNameFieldFocused: Bool

    private var canContinue: Bool {
        !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && goalTarget > 0
    }

    var body: some View {
        CenteredScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                OnboardingHeadline("Set your first goal")

                OnboardingBodyText("What are you saving toward? You can always change this later.")
                    .padding(.top, OnboardingTheme.Metrics.textGap)

                OnboardingIllustration(symbol: "target")
                    .padding(.top, OnboardingTheme.Metrics.blockGap)

                VStack(alignment: .leading, spacing: 18) {
                    OnboardingField(label: "What are you saving for?") {
                        TextField("e.g. Concert tickets", text: $goalName)
                            .focused($isNameFieldFocused)
                    }

                    OnboardingField(label: "Target amount") {
                        TextField("0.00", value: $goalTarget, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                .padding(.top, OnboardingTheme.Metrics.blockGap)

                Spacer(minLength: 32)

                OnboardingPageDots(current: 1)
                    .padding(.bottom, 24)

                OnboardingPrimaryButton(title: "Next", isEnabled: canContinue, action: onNext)

                OnboardingSubtleButton(title: "Skip for now", action: onSkip)
                    .padding(.top, 8)
            }
            .padding(.horizontal, OnboardingTheme.Metrics.screenPadding)
            .padding(.bottom, 32)
        }
        .background(OnboardingTheme.Palette.paper.ignoresSafeArea())
    }
}

#Preview {
    OnboardingGoalPage(goalName: .constant(""), goalTarget: .constant(0), onNext: {}, onSkip: {})
}

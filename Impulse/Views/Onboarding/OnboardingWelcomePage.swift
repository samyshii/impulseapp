//
//  OnboardingWelcomePage.swift
//  Impulse
//
//  Onboarding page 1: the core idea in one line.
//
//  Styled to the "Cobalt on Paper" direction — near-white page, one blue
//  ink, a line drawing in the middle. Every value comes from
//  OnboardingTheme; nothing visual is decided here.
//

import SwiftUI

struct OnboardingWelcomePage: View {
    var onNext: () -> Void

    var body: some View {
        CenteredScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                OnboardingHeadline("Before you buy it, shelve it")

                Spacer(minLength: 32)

                OnboardingIllustration(symbol: "shippingbox")

                Spacer(minLength: 32)

                OnboardingBodyText(
                    "Impulses get a cooldown instead of an instant purchase — so you decide with a clear head, not a hot one."
                )

                Spacer(minLength: 32)

                OnboardingPageDots(current: 0)
                    .padding(.bottom, 24)

                OnboardingPrimaryButton(title: "Next", action: onNext)
            }
            .padding(.horizontal, OnboardingTheme.Metrics.screenPadding)
            .padding(.bottom, 32)
        }
        .background(OnboardingTheme.Palette.paper.ignoresSafeArea())
    }
}

#Preview {
    OnboardingWelcomePage(onNext: {})
}

//
//  OnboardingHowItWorksPage.swift
//  Impulse
//
//  Onboarding page 3: the three-step mental model, then off you go.
//
//  Styled to "Cobalt on Paper". The steps stay numbered because they
//  genuinely are a sequence — shelve, wait, decide.
//

import SwiftUI

struct OnboardingHowItWorksPage: View {
    var onStart: () -> Void

    var body: some View {
        CenteredScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                OnboardingHeadline("How it works")

                // "timer" is drawn as strokes; "hourglass" is a solid glyph
                // and rendered as a heavy blue blob that broke the line-art
                // language the other two pages establish.
                OnboardingIllustration(symbol: "timer")
                    .padding(.top, OnboardingTheme.Metrics.blockGap)

                VStack(alignment: .leading, spacing: 22) {
                    step(
                        number: "1",
                        title: "Shelve it",
                        detail: "See something you want? Put it on the shelf instead of buying it right away."
                    )
                    step(
                        number: "2",
                        title: "Wait it out",
                        detail: "A cooldown runs in the background — no pressure, no timer to watch."
                    )
                    step(
                        number: "3",
                        title: "Then decide",
                        detail: "When it's up, buy it guilt-free or let it go and bank the savings."
                    )
                }
                .padding(.top, OnboardingTheme.Metrics.blockGap)

                Spacer(minLength: 32)

                OnboardingPageDots(current: 2)
                    .padding(.bottom, 24)

                OnboardingPrimaryButton(title: "Start", action: onStart)
            }
            .padding(.horizontal, OnboardingTheme.Metrics.screenPadding)
            .padding(.bottom, 32)
        }
        .background(OnboardingTheme.Palette.paper.ignoresSafeArea())
    }

    private func step(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // An outlined circle rather than a filled one — it keeps the
            // page reading as a line drawing rather than a solid block.
            Text(number)
                .font(OnboardingTheme.Typography.label(14))
                .foregroundStyle(OnboardingTheme.Palette.cobalt)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .strokeBorder(OnboardingTheme.Palette.cobalt, lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(OnboardingTheme.Typography.label())
                    .foregroundStyle(OnboardingTheme.Palette.cobalt)

                Text(detail)
                    .font(OnboardingTheme.Typography.body(14))
                    .lineSpacing(OnboardingTheme.Metrics.bodyLineSpacing)
                    .foregroundStyle(OnboardingTheme.Palette.cobaltSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingHowItWorksPage(onStart: {})
}

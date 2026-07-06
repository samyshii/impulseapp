//
//  OnboardingWelcomePage.swift
//  Impulse
//
//  Onboarding page 1: the core idea in one line.
//

import SwiftUI

struct OnboardingWelcomePage: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shippingbox.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Before you buy it, shelve it")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Impulses get a cooldown instead of an instant purchase — so you decide with a clear head, not a hot one.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()

            Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    OnboardingWelcomePage(onNext: {})
}

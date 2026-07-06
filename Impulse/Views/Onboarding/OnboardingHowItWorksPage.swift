//
//  OnboardingHowItWorksPage.swift
//  Impulse
//
//  Onboarding page 3: the three-step mental model, then off you go.
//

import SwiftUI

struct OnboardingHowItWorksPage: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How it works")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 20) {
                step(number: "1", title: "Shelve it", detail: "See something you want? Put it on the shelf instead of buying it right away.")
                step(number: "2", title: "Wait it out", detail: "A cooldown runs in the background — no pressure, no timer to watch.")
                step(number: "3", title: "Then decide", detail: "When it's up, buy it guilt-free or let it go and bank the savings.")
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()

            Button(action: onStart) {
                Text("Start")
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

    private func step(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingHowItWorksPage(onStart: {})
}

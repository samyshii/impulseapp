//
//  WeeklyRecapSavedCard.swift
//  Impulse
//
//  Weekly Recap card 1: the total saved this week.
//

import SwiftUI

struct WeeklyRecapSavedCard: View {
    let totalSaved: Decimal

    private var hasSavings: Bool { totalSaved > 0 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.55, blue: 0.45), Color(red: 0.05, green: 0.3, blue: 0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("This week you saved")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Text(totalSaved.formatted(.currency(code: "USD")))
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 24)

                Text(hasSavings
                     ? "That's real money back in your pocket."
                     : "Nothing banked yet this week — the shelf's still working its magic.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    WeeklyRecapSavedCard(totalSaved: 142.50)
}

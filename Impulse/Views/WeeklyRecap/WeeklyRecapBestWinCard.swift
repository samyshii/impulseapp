//
//  WeeklyRecapBestWinCard.swift
//  Impulse
//
//  Weekly Recap card 2: the single most expensive item let go this
//  week — the week's biggest win.
//

import SwiftUI

struct WeeklyRecapBestWinCard: View {
    let bestWin: (name: String, amount: Decimal)?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.4, blue: 0.25), Color(red: 0.7, green: 0.2, blue: 0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                if let bestWin {
                    Text("Your best win this week")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.yellow)

                    Text(bestWin.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text(bestWin.amount.formatted(.currency(code: "USD")))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 24)
                } else {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("No wins yet this week")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("That's alright — the shelf's still doing its job.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    WeeklyRecapBestWinCard(bestWin: (name: "Noise-cancelling headphones", amount: 89))
}

#Preview("No win") {
    WeeklyRecapBestWinCard(bestWin: nil)
}

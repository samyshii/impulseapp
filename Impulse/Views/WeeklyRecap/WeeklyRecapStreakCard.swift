//
//  WeeklyRecapStreakCard.swift
//  Impulse
//
//  Weekly Recap card 3: current streak status plus a short
//  encouraging line, followed by the closing actions.
//

import SwiftUI

struct WeeklyRecapStreakCard: View {
    let streak: Int
    let shieldAvailable: Bool
    var onShare: () -> Void
    var onDone: () -> Void

    private var encouragingLine: String {
        switch streak {
        case 0:
            return "Every streak starts with one week. This could be it."
        case 1...2:
            return "You're building momentum — keep it going."
        default:
            return shieldAvailable
                ? "You're on a roll, and your streak shield has your back if you ever need it."
                : "You're on a roll — one of the strongest habits you've built."
        }
    }

    private var streakColor: Color { Color(red: 0.3, green: 0.15, blue: 0.55) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [streakColor, Color(red: 0.15, green: 0.15, blue: 0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)

                Text(streak == 1 ? "1 week streak" : "\(streak) week streak")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(encouragingLine)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
                Spacer()

                VStack(spacing: 12) {
                    Button(action: onShare) {
                        Label("Share this win", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white)
                            .foregroundStyle(streakColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    WeeklyRecapStreakCard(streak: 4, shieldAvailable: true, onShare: {}, onDone: {})
}

//
//  WeeklyRecapEmptyState.swift
//  Impulse
//
//  Shown instead of the 3-card flow when there's genuinely nothing to
//  recap — no items shelved or decided at all in that week. Mainly hit
//  via Settings > Debug > Preview Weekly Recap on a fresh/empty shelf;
//  the real auto-triggered recap never shows up for an empty week in
//  the first place.
//

import SwiftUI

struct WeeklyRecapEmptyState: View {
    var onDone: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.45, blue: 0.38), Color(red: 0.02, green: 0.16, blue: 0.19)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "shippingbox")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.85))

                Text("Nothing to recap yet")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Shelve something this week, and there'll be a recap waiting for you.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                Spacer()

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundStyle(Color(red: 0.04, green: 0.45, blue: 0.38))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    WeeklyRecapEmptyState(onDone: {})
}

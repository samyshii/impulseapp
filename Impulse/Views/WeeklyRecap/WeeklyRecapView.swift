//
//  WeeklyRecapView.swift
//  Impulse
//
//  A full-screen, swipeable 3-card summary of the week — a mini
//  "Spotify Wrapped" for the shelf. Shown automatically (see
//  WeeklyRecapAutoShow) or on demand from Settings > Debug.
//

import SwiftUI

struct WeeklyRecapView: View {
    let data: WeeklyRecapData
    var onDone: () -> Void

    @State private var currentPage = 0
    @State private var isShowingShareComingSoon = false

    var body: some View {
        TabView(selection: $currentPage) {
            WeeklyRecapSavedCard(totalSaved: data.totalSaved)
                .tag(0)

            WeeklyRecapBestWinCard(bestWin: data.bestWin)
                .tag(1)

            WeeklyRecapStreakCard(
                streak: data.currentStreak,
                shieldAvailable: data.shieldAvailable,
                onShare: { isShowingShareComingSoon = true },
                onDone: onDone
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)
        .alert("Sharing is on the way", isPresented: $isShowingShareComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You'll be able to share your wins in a future update.")
        }
    }
}

#Preview {
    WeeklyRecapView(
        data: WeeklyRecapData(
            totalSaved: 142.50,
            bestWin: (name: "Noise-cancelling headphones", amount: 89),
            currentStreak: 4,
            shieldAvailable: true,
            hadActivity: true
        ),
        onDone: {}
    )
}

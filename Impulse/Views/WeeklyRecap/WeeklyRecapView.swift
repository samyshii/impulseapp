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
    @State private var shareImage: UIImage?
    @State private var isShowingShareSheet = false

    var body: some View {
        TabView(selection: $currentPage) {
            WeeklyRecapSavedCard(totalSaved: data.totalSaved)
                .tag(0)

            WeeklyRecapBestWinCard(bestWin: data.bestWin)
                .tag(1)

            WeeklyRecapStreakCard(
                streak: data.currentStreak,
                shieldAvailable: data.shieldAvailable,
                onShare: shareWin,
                onDone: onDone
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage])
            }
        }
    }

    // Shares the week's best win if there was one, otherwise falls back
    // to the week's total — either way, the all-time total and current
    // streak underneath are always the real, current figures.
    private func shareWin() {
        let cardData = ShareCardData(
            headline: "I didn't buy it",
            winAmount: data.bestWin?.amount ?? data.totalSaved,
            totalSaved: data.allTimeTotalSaved,
            weeklyStreak: data.currentStreak
        )
        shareImage = ShareCardRenderer.render(cardData)
        isShowingShareSheet = true
    }
}

#Preview {
    WeeklyRecapView(
        data: WeeklyRecapData(
            totalSaved: 142.50,
            bestWin: (name: "Noise-cancelling headphones", amount: 89),
            currentStreak: 4,
            shieldAvailable: true,
            allTimeTotalSaved: 1842,
            hadActivity: true
        ),
        onDone: {}
    )
}

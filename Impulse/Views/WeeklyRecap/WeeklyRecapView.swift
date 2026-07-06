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
    @State private var isShowingShareError = false

    var body: some View {
        Group {
            if data.hadActivity {
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
            } else {
                // Nothing shelved or decided that week — no cards worth
                // swiping through, just a clear, friendly heads-up.
                WeeklyRecapEmptyState(onDone: onDone)
            }
        }
        .background {
            if let shareImage {
                ActivityShareSheet(isPresented: $isShowingShareSheet, items: [shareImage])
            }
        }
        .alert("Couldn't create the share image", isPresented: $isShowingShareError) {
            Button("OK", role: .cancel) {}
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
        guard let image = ShareCardRenderer.render(cardData) else {
            isShowingShareError = true
            return
        }
        shareImage = image
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

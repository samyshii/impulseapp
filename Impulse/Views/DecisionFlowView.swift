//
//  DecisionFlowView.swift
//  Impulse
//
//  Shown full-screen when a shelved item's cooldown is over: asks
//  "Still want it?", then shows either a calm "bought" confirmation
//  or a "let it go" celebration and updated savings summary. Buying
//  is treated as a completely valid outcome, never a failure.
//

import SwiftUI
import SwiftData

struct DecisionFlowView: View {
    let item: ShelvedItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var goals: [Goal]

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifyMilestones") private var notifyMilestones = true

    @State private var stage: Stage = .asking
    @State private var savedTotalAfter: Decimal = 0
    @State private var displayedTotal: Decimal = 0
    @State private var streakAfter: Int = 0

    @State private var shareImage: UIImage?
    @State private var isShowingShareSheet = false

    private enum Stage {
        case asking
        case bought
        case celebrating
        case summary
    }

    var body: some View {
        Group {
            switch stage {
            case .asking:
                askingView
            case .bought:
                boughtView
            case .celebrating:
                celebratingView
            case .summary:
                summaryView
            }
        }
    }

    // MARK: - Asking

    private var askingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let data = item.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                VStack(spacing: 8) {
                    Text(item.name)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(item.price.formatted(.currency(code: "USD")))
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                if let note = item.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Why you wanted it")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(note)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                }

                Spacer(minLength: 12)

                Text("Still want it?")
                    .font(.title3.bold())

                VStack(spacing: 12) {
                    Button(action: buyGuiltFree) {
                        Text("Yes — buy it guilt-free")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button(action: letGo) {
                        Text("Let it go")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
    }

    private func buyGuiltFree() {
        item.status = .bought
        item.decidedAt = .now

        // Buying still counts as "activity" for the weekly recap.
        NotificationScheduler.reconcileAll(context: modelContext)

        stage = .bought
    }

    private func letGo() {
        // Captured before this decision changes anything, so we know
        // whether this win is truly the user's first one ever.
        let priorLetGoCount = (try? modelContext.fetch(FetchDescriptor<ShelvedItem>()))?
            .filter { $0.status == .letGo }.count ?? 0
        let isFirstWinEver = priorLetGoCount == 0

        item.status = .letGo
        item.decidedAt = .now

        let statsManager = StatsManager(modelContext: modelContext)
        let totalBefore = statsManager.currentStats().totalSaved
        displayedTotal = totalBefore
        statsManager.addWin(price: item.price)
        savedTotalAfter = statsManager.currentStats().totalSaved
        streakAfter = statsManager.currentStats().currentWeeklyStreak

        MilestoneNotifier.checkAndNotify(
            isFirstWinEver: isFirstWinEver,
            totalBefore: totalBefore,
            totalAfter: savedTotalAfter,
            goal: goals.first,
            enabled: notificationsEnabled && notifyMilestones
        )
        NotificationScheduler.reconcileAll(context: modelContext)

        stage = .celebrating
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Bought (a valid, neutral outcome — not a failure)

    private var boughtView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 56))
                .foregroundStyle(.pink)
            Text("Enjoy it.")
                .font(.largeTitle.bold())
            Text("Wanting things is human.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Back to Shelf")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
    }

    // MARK: - Celebrating (let it go)

    private var celebratingView: some View {
        ZStack {
            ConfettiView()

            VStack(spacing: 16) {
                Spacer()
                Text("Nice.")
                    .font(.largeTitle.bold())
                VStack(spacing: 4) {
                    Text("Total saved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(displayedTotal.formatted(.currency(code: "USD")))
                        .font(.system(size: 44, weight: .bold))
                        .contentTransition(.numericText(value: (displayedTotal as NSDecimalNumber).doubleValue))
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                displayedTotal = savedTotalAfter
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                stage = .summary
            }
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("You let it go.")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            VStack(spacing: 4) {
                Text("Total saved")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(savedTotalAfter.formatted(.currency(code: "USD")))
                    .font(.system(size: 44, weight: .bold))
            }
            Spacer()

            VStack(spacing: 12) {
                Button(action: shareWin) {
                    Label("Share this win", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage])
            }
        }
    }

    private func shareWin() {
        let data = ShareCardData(
            headline: "I didn't buy it",
            winAmount: item.price,
            totalSaved: savedTotalAfter,
            weeklyStreak: streakAfter
        )
        shareImage = ShareCardRenderer.render(data)
        isShowingShareSheet = true
    }
}

#Preview {
    DecisionFlowView(
        item: ShelvedItem(
            name: "Noise-cancelling headphones",
            price: 249.99,
            note: "My old ones broke and I miss silence on the train.",
            cooldownEndsAt: .now.addingTimeInterval(-10)
        )
    )
    .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

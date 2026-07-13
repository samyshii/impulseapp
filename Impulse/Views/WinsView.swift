//
//  WinsView.swift
//  Impulse
//
//  The "Wins" tab: total saved, goal progress, streak, this week's
//  activity, and the full history of decided items.
//

import SwiftUI
import SwiftData

struct WinsView: View {
    @Query private var statsList: [AppStats]
    @Query private var goals: [Goal]
    @Query(sort: \ShelvedItem.createdAt, order: .reverse) private var allItems: [ShelvedItem]

    @State private var isShowingSetGoal = false

    private var stats: AppStats? { statsList.first }
    private var goal: Goal? { goals.first }
    private var totalSaved: Decimal { stats?.totalSaved ?? 0 }
    private var shieldAvailable: Bool { stats?.isShieldAvailable() ?? true }

    private var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    }

    private var itemsShelvedThisWeek: Int {
        allItems.filter { $0.createdAt >= weekStart }.count
    }

    private var winsThisWeek: [ShelvedItem] {
        allItems.filter { $0.status == .letGo && ($0.decidedAt ?? .distantPast) >= weekStart }
    }

    private var savedThisWeekAmount: Decimal {
        winsThisWeek.reduce(Decimal(0)) { $0 + $1.price }
    }

    private var historyItems: [ShelvedItem] {
        allItems
            .filter { $0.status == .letGo || $0.status == .bought }
            .sorted { ($0.decidedAt ?? $0.createdAt) > ($1.decidedAt ?? $1.createdAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    goalSection
                    streakCard
                    thisWeekSection
                    historySection
                }
                .padding()
            }
            .navigationTitle("Wins")
            .sheet(isPresented: $isShowingSetGoal) {
                SetGoalSheet()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 4) {
            Text("Total Saved")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(totalSaved.formatted(.currency(code: "USD")))
                .font(.system(size: 48, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Goal

    @ViewBuilder
    private var goalSection: some View {
        if let goal {
            goalCard(for: goal)
        } else {
            noGoalPrompt
        }
    }

    private func goalCard(for goal: Goal) -> some View {
        let progressAmount = min(totalSaved + goal.starterBoost, goal.targetAmount)
        let remaining = max(0, goal.targetAmount - progressAmount)
        let fraction: Double = {
            guard goal.targetAmount > 0 else { return 0 }
            return NSDecimalNumber(decimal: progressAmount / goal.targetAmount).doubleValue
        }()

        return VStack(alignment: .leading, spacing: 12) {
            Text(goal.name)
                .font(.headline)

            ProgressView(value: fraction)
                .tint(.green)

            HStack {
                Text("\(progressAmount.formatted(.currency(code: "USD"))) saved")
                Spacer()
                Text(remaining > 0 ? "\(remaining.formatted(.currency(code: "USD"))) to go" : "Goal reached!")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var noGoalPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No goal yet")
                .font(.headline)
            Text("Set a savings goal to see your progress here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                isShowingSetGoal = true
            } label: {
                Text("Set a Goal")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak

    private var streakCard: some View {
        // ViewThatFits keeps the streak and shield side by side normally,
        // but drops them onto separate lines once larger accessibility
        // text sizes make the single row too wide to fit — so nothing
        // gets clipped or overlaps.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                streakLabel
                Spacer()
                shieldLabel
            }
            VStack(alignment: .leading, spacing: 10) {
                streakLabel
                shieldLabel
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(stats?.currentWeeklyStreak ?? 0) week streak")
                .font(.headline)
        }
    }

    private var shieldLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: shieldAvailable ? "shield.fill" : "shield.slash")
                .foregroundStyle(shieldAvailable ? .blue : .secondary)
            Text(shieldAvailable ? "Shield ready" : "Shield used")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - This week

    private var thisWeekSection: some View {
        HStack(spacing: 12) {
            weekTile(value: "\(itemsShelvedThisWeek)", label: "Shelved")
            weekTile(value: "\(winsThisWeek.count)", label: "Wins")
            weekTile(value: savedThisWeekAmount.formatted(.currency(code: "USD")), label: "Saved")
        }
    }

    private func weekTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)

            if historyItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No decisions yet")
                        .font(.subheadline.weight(.medium))
                    Text("Once a cooldown ends and you decide, every buy and every win shows up here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(Array(historyItems.enumerated()), id: \.element.id) { index, item in
                    HistoryRow(item: item)
                    if index < historyItems.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview {
    WinsView()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}

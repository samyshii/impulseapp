//
//  ImpulseWidgetView.swift
//  ImpulseWidget
//
//  What the widget actually looks like — compact for small, with one
//  extra line of context ("X saved this week") for medium.
//

import SwiftUI
import WidgetKit

struct ImpulseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .containerBackground(for: .widget) { backgroundGradient }
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            streakLine
                .font(.headline)

            Spacer()

            totalSavedBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium

    private var mediumView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                streakLine
                    .font(.headline)

                Spacer()

                totalSavedBlock
            }

            Spacer()

            VStack {
                Spacer()
                Text(weekText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared pieces

    private var streakLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text(streakText)
                .foregroundStyle(.white)
        }
    }

    private var totalSavedBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TOTAL SAVED")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(snapshot.totalSaved.formatted(.currency(code: "USD")))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    private var streakText: String {
        snapshot.currentStreak == 1 ? "1 week" : "\(snapshot.currentStreak) weeks"
    }

    private var weekText: String {
        "\(snapshot.savedThisWeek.formatted(.currency(code: "USD"))) saved this week"
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.45, blue: 0.38), Color(red: 0.02, green: 0.16, blue: 0.19)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview(as: .systemSmall) {
    ImpulseWidget()
} timeline: {
    ImpulseWidgetEntry(date: .now, snapshot: WidgetSnapshot(totalSaved: 142.50, currentStreak: 3, savedThisWeek: 42))
}

#Preview(as: .systemMedium) {
    ImpulseWidget()
} timeline: {
    ImpulseWidgetEntry(date: .now, snapshot: WidgetSnapshot(totalSaved: 142.50, currentStreak: 3, savedThisWeek: 42))
}

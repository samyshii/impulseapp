//
//  HistoryRow.swift
//  Impulse
//
//  One row in the Wins history list. "Let go" items are styled
//  positively (green, with a plus sign); "bought" items are styled
//  plainly and neutrally — buying is a valid outcome, not a failure.
//

import SwiftUI

struct HistoryRow: View {
    let item: ShelvedItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                if let decidedAt = item.decidedAt {
                    Text(decidedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if item.status == .letGo {
                Text("+\(item.price.formatted(.currency(code: "USD")))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            } else {
                Text(item.price.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack {
        HistoryRow(item: ShelvedItem(name: "Vintage jacket", price: 89, cooldownEndsAt: .now, status: .letGo, decidedAt: .now))
        HistoryRow(item: ShelvedItem(name: "New keyboard", price: 129, cooldownEndsAt: .now, status: .bought, decidedAt: .now))
    }
    .padding()
}

//
//  ShelvedItemCard.swift
//  Impulse
//
//  One row on the Shelf screen: an item's photo, name, price, and
//  either a live countdown or a "ready to decide" badge.
//

import SwiftUI

struct ShelvedItemCard: View {
    let item: ShelvedItem
    let now: Date

    private var isReady: Bool {
        item.cooldownEndsAt <= now
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(item.price.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if isReady {
                    readyBadge
                } else {
                    Text("\(countdownText) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var thumbnail: some View {
        Group {
            if let data = item.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.15))
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var readyBadge: some View {
        Text("Ready to decide")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.15), in: Capsule())
            .foregroundStyle(.green)
    }

    // Formats the time left as "18h 22m", "22m 05s", or "5s".
    private var countdownText: String {
        let remaining = max(0, item.cooldownEndsAt.timeIntervalSince(now))
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ShelvedItemCard(
            item: ShelvedItem(
                name: "Noise-cancelling headphones",
                price: 249.99,
                cooldownEndsAt: .now.addingTimeInterval(66_000)
            ),
            now: .now
        )
        ShelvedItemCard(
            item: ShelvedItem(
                name: "Vintage jacket",
                price: 89,
                cooldownEndsAt: .now.addingTimeInterval(-10)
            ),
            now: .now
        )
    }
    .padding()
}

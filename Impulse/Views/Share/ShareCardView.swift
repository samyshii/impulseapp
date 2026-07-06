//
//  ShareCardView.swift
//  Impulse
//
//  The shareable win card itself: clean text and numbers only (no
//  photos, no personal info) so it looks good as a public screenshot.
//  Laid out at exactly 1080x1920 — standard Instagram/TikTok story
//  size — so ShareCardRenderer can turn it into a pixel-perfect image
//  without any extra scaling math.
//

import SwiftUI

struct ShareCardView: View {
    let data: ShareCardData

    static let pixelSize = CGSize(width: 1080, height: 1920)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.45, blue: 0.38), Color(red: 0.02, green: 0.16, blue: 0.19)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Text("IMPULSE")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 120)

                Spacer()

                Text(data.headline)
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.horizontal, 80)

                Text(data.winAmount.formatted(.currency(code: "USD")))
                    .font(.system(size: 168, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("TOTAL SAVED")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(data.totalSaved.formatted(.currency(code: "USD")))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding(.top, 64)

                Spacer()

                HStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.orange)
                    Text(data.weeklyStreak == 1 ? "1 week streak" : "\(data.weeklyStreak) week streak")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 120)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: Self.pixelSize.width, height: Self.pixelSize.height)
    }
}

#Preview {
    ShareCardView(data: ShareCardData(headline: "I didn't buy it", winAmount: 249.99, totalSaved: 1842, weeklyStreak: 4))
}

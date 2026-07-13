//
//  PaywallFeatureList.swift
//  Impulse
//
//  The "here's what you get" bullets. Edit the `features` array to
//  change the selling points — no layout changes needed.
//

import SwiftUI

struct PaywallFeatureList: View {

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
    }

    private let features: [Feature] = [
        Feature(icon: "clock.arrow.circlepath", text: "Shelf any purchase and cool off before you buy"),
        Feature(icon: "banknote", text: "Track every dollar you didn't spend"),
        Feature(icon: "target", text: "Put your savings toward a goal that matters"),
        Feature(icon: "flame", text: "Build a streak and keep it alive"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 28)

                    Text(feature.text)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    PaywallFeatureList()
        .padding()
}

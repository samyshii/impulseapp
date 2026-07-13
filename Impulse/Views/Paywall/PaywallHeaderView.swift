//
//  PaywallHeaderView.swift
//  Impulse
//
//  The title block at the top of the paywall. Deliberately plain —
//  this is a prime candidate for the Figma restyle.
//

import SwiftUI

struct PaywallHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Impulse Premium")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Stop buying things you don't need.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PaywallHeaderView()
}

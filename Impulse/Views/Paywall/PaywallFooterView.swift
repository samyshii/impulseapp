//
//  PaywallFooterView.swift
//  Impulse
//
//  Restore Purchases, plus the Terms and Privacy links.
//
//  All three are App Store review requirements — Apple rejects apps
//  whose paywall doesn't offer a way to restore an existing
//  subscription, and doesn't link the legal terms. Don't delete these
//  during the Figma restyle; restyle them.
//
//  The URLs are placeholders and live in PurchaseConfig.
//

import SwiftUI

struct PaywallFooterView: View {
    let isWorking: Bool
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button("Restore Purchases", action: onRestore)
                .disabled(isWorking)

            Text("·")
                .foregroundStyle(.secondary)

            Link("Terms", destination: PurchaseConfig.termsURL)

            Text("·")
                .foregroundStyle(.secondary)

            Link("Privacy", destination: PurchaseConfig.privacyURL)
        }
        .font(.footnote)
    }
}

#Preview {
    PaywallFooterView(isWorking: false, onRestore: {})
}

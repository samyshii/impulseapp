//
//  ActivityShareSheet.swift
//  Impulse
//
//  A thin SwiftUI wrapper around UIActivityViewController — Apple's
//  native share sheet — so a rendered image can be sent to Messages,
//  Instagram, AirDrop, saved to Photos, and so on.
//

import SwiftUI
import UIKit

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

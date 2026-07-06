//
//  ActivityShareSheet.swift
//  Impulse
//
//  A transparent helper that imperatively presents Apple's native
//  UIActivityViewController via the classic present(_:animated:) API.
//  UIActivityViewController is built to be presented modally — trying
//  to hand it to SwiftUI's .sheet as if it were ordinary content (an
//  earlier version of this file did that) renders as a blank card with
//  no preview and no app icons. Attaching this as a .background() puts
//  a real, live UIViewController in the hierarchy to present *from*,
//  while staying invisible itself.
//

import SwiftUI
import UIKit

struct ActivityShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        // Harmless on iPhone, but keeps this safe if it's ever run on iPad.
        activityViewController.popoverPresentationController?.sourceView = uiViewController.view

        uiViewController.present(activityViewController, animated: true)
    }
}

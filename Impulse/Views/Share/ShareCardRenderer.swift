//
//  ShareCardRenderer.swift
//  Impulse
//
//  Turns a ShareCardView into an actual UIImage so it can be handed to
//  the system share sheet. ShareCardView is already laid out at exactly
//  1080x1920 points, so rendering at scale 1 gives a pixel-perfect
//  1080x1920 image without any extra math.
//
//  Uses UIHostingController + drawHierarchy instead of ImageRenderer:
//  ShareCardView is never actually displayed anywhere on screen (it
//  only ever exists to be turned into an image), and ImageRenderer's
//  `.uiImage` is well known to silently return nil for a view like
//  that on its first render. Forcing a real layout pass and drawing
//  the hosting controller's view directly avoids that entirely.
//

import SwiftUI
import UIKit

@MainActor
enum ShareCardRenderer {
    static func render(_ data: ShareCardData) -> UIImage? {
        let targetSize = ShareCardView.pixelSize
        let hostingController = UIHostingController(rootView: ShareCardView(data: data))

        hostingController.view.bounds = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = .clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let imageRenderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return imageRenderer.image { _ in
            hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
    }
}

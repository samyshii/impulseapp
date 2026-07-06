//
//  ShareCardRenderer.swift
//  Impulse
//
//  Turns a ShareCardView into an actual UIImage so it can be handed to
//  the system share sheet. ShareCardView is already laid out at exactly
//  1080x1920 points, so rendering at scale 1 gives a pixel-perfect
//  1080x1920 image without any extra math.
//

import SwiftUI

@MainActor
enum ShareCardRenderer {
    static func render(_ data: ShareCardData) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(data: data))
        renderer.scale = 1
        return renderer.uiImage
    }
}

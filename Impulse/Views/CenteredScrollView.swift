//
//  CenteredScrollView.swift
//  Impulse
//
//  A container that keeps its content vertically centered (the way a
//  VStack with Spacers does) on a normal-sized screen, but automatically
//  starts scrolling once the content is taller than the screen — for
//  example on a small iPhone, or when a large accessibility text size is
//  turned on. This means full-screen pages never clip their content or
//  push a button off the bottom edge.
//

import SwiftUI

struct CenteredScrollView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    // Fill the screen so inner Spacers still center the
                    // content when there's room to spare...
                    .frame(minHeight: proxy.size.height)
                    // ...but let it grow past the screen (and scroll)
                    // when the content genuinely needs more space.
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

//
//  ConfettiView.swift
//  Impulse
//
//  A simple falling-confetti effect built from plain SwiftUI shapes
//  (no third-party packages needed) for celebration moments like
//  successfully letting an item go.
//

import SwiftUI

struct ConfettiView: View {
    private let pieces: [Piece]
    @State private var animate = false

    init(pieceCount: Int = 60) {
        let colors: [Color] = [.green, .blue, .yellow, .orange, .pink, .purple, .mint]
        pieces = (0..<pieceCount).map { _ in
            Piece(
                x: .random(in: 0...1),
                color: colors.randomElement() ?? .green,
                width: .random(in: 6...11),
                height: .random(in: 8...16),
                delay: .random(in: 0...0.4),
                duration: .random(in: 1.4...2.2),
                rotation: .random(in: 0...360)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.height)
                        .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
                        .position(
                            x: piece.x * geo.size.width,
                            y: animate ? geo.size.height + 40 : -40
                        )
                        .animation(
                            .easeIn(duration: piece.duration).delay(piece.delay),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }

    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let color: Color
        let width: CGFloat
        let height: CGFloat
        let delay: Double
        let duration: Double
        let rotation: Double
    }
}

#Preview {
    ConfettiView()
}

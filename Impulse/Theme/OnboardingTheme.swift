//
//  OnboardingTheme.swift
//  Impulse
//
//  Every colour, font, and measurement used by the onboarding screens.
//  Nothing visual is hardcoded inside the onboarding views themselves —
//  they all read from here. To change how onboarding looks, this is the
//  only file you need to open.
//
//  DIRECTION: "Cobalt on Paper"
//  One near-white page, one strong blue. Everything — headline, body,
//  illustration, button, dots — is drawn in that single blue, the way a
//  ballpoint sketch on printer paper is. The friendliness comes from the
//  round, chunky lowercase type and the line-art drawings, not from
//  colour. Restraint is the whole point: one ink, one paper.
//
//  ---------------------------------------------------------------------
//  REDESIGNING THIS IN FIGMA LATER
//  ---------------------------------------------------------------------
//  Everything you'd want to change lives in the three enums below. Hand
//  me a Figma export and I only need four things from it:
//
//    1. The hex codes            -> Palette
//    2. The font name and sizes  -> Typography
//    3. The spacing and radii    -> Metrics
//    4. The illustrations, as SVG or PNG (see Illustration below)
//
//  The page views themselves almost certainly won't need to change.
//

import SwiftUI

enum OnboardingTheme {

    // MARK: - Colour

    enum Palette {
        /// The paper. A hair off pure white so the blue doesn't vibrate.
        static let paper = Color(hex: 0xF7F7F8)

        /// The ink. Every mark on the page is this colour.
        static let cobalt = Color(hex: 0x1E3AD9)

        /// Body copy — the same ink, just quieter. Using a separate grey
        /// here would break the one-ink idea and look muddy.
        static let cobaltSoft = Color(hex: 0x1E3AD9).opacity(0.62)

        /// Inactive page dots and field borders.
        static let cobaltFaint = Color(hex: 0x1E3AD9).opacity(0.18)

        /// Text sitting on top of a filled cobalt button.
        static let onCobalt = Color(hex: 0xFFFFFF)

        /// Text field fills.
        static let fieldFill = Color(hex: 0xFFFFFF)
    }

    // MARK: - Type
    //
    // Fredoka, a rounded geometric sans. Google Fonts, Open Font License,
    // so it's free to ship in a paid app. The .ttf files live in
    // Impulse/Fonts and are listed in Info.plist under UIAppFonts.
    //
    // Headlines are set lowercase on purpose — that's what makes it read
    // as friendly rather than shouty, and it's what the reference does.
    //
    // `relativeTo:` is what keeps these growing when someone turns up the
    // text size in iOS Settings. Custom fonts don't do that for free.

    enum Typography {
        /// Page headlines. Chunky, tight, centred.
        static func headline(_ size: CGFloat = 30) -> Font {
            .custom("Fredoka-SemiBold", size: size, relativeTo: .largeTitle)
        }

        /// Supporting copy. Deliberately small and quiet.
        static func body(_ size: CGFloat = 15) -> Font {
            .custom("Fredoka-Regular", size: size, relativeTo: .body)
        }

        /// Button labels, field labels, step titles.
        static func label(_ size: CGFloat = 17) -> Font {
            .custom("Fredoka-Medium", size: size, relativeTo: .headline)
        }
    }

    // MARK: - Metrics

    enum Metrics {
        static let screenPadding: CGFloat = 32

        static let buttonHeight: CGFloat = 56
        /// Half the height, which is what makes it a true pill.
        static let buttonRadius: CGFloat = 28

        static let fieldRadius: CGFloat = 14
        static let fieldPadding: CGFloat = 14

        /// How big the line-art drawing sits on the page.
        static let illustrationSize: CGFloat = 96

        static let textGap: CGFloat = 14
        static let blockGap: CGFloat = 28

        static let headlineTracking: CGFloat = -0.4
        static let headlineLineSpacing: CGFloat = 1
        static let bodyLineSpacing: CGFloat = 4
    }
}

// MARK: - Reusable pieces

/// The line-art drawing at the centre of a page.
///
/// These are SF Symbols in outline form, standing in for the hand-drawn
/// doodles in the reference. When you have the real artwork, drop the
/// assets into Assets.xcassets and change this one view to use
/// `Image("shelf-doodle")` — no page needs to change.
struct OnboardingIllustration: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: OnboardingTheme.Metrics.illustrationSize, weight: .light))
            .foregroundStyle(OnboardingTheme.Palette.cobalt)
            .frame(maxWidth: .infinity)
    }
}

/// A page headline. Centred, lowercase, chunky.
struct OnboardingHeadline: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(OnboardingTheme.Typography.headline())
            .kerning(OnboardingTheme.Metrics.headlineTracking)
            .lineSpacing(OnboardingTheme.Metrics.headlineLineSpacing)
            .foregroundStyle(OnboardingTheme.Palette.cobalt)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

/// The quiet paragraph under a headline.
struct OnboardingBodyText: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(OnboardingTheme.Typography.body())
            .lineSpacing(OnboardingTheme.Metrics.bodyLineSpacing)
            .foregroundStyle(OnboardingTheme.Palette.cobaltSoft)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

/// The full-width cobalt pill. "Next" on pages 1 and 2, "Start" on page 3.
struct OnboardingPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingTheme.Typography.label())
                .foregroundStyle(OnboardingTheme.Palette.onCobalt)
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingTheme.Metrics.buttonHeight)
                .background(
                    // A disabled button fades the ink rather than going
                    // grey — grey would introduce a second colour.
                    OnboardingTheme.Palette.cobalt.opacity(isEnabled ? 1 : 0.3),
                    in: RoundedRectangle(cornerRadius: OnboardingTheme.Metrics.buttonRadius)
                )
        }
        .disabled(!isEnabled)
    }
}

/// The quiet text-only action. Currently just "Skip for now".
struct OnboardingSubtleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingTheme.Typography.body())
                .foregroundStyle(OnboardingTheme.Palette.cobaltSoft)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
        }
    }
}

/// The "you are here" dots. The active one stretches into a pill rather
/// than just changing colour — it reads at a glance, which matters more
/// than it sounds for an ADHD-facing app.
struct OnboardingPageDots: View {
    let current: Int
    var total: Int = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(
                        index == current
                            ? OnboardingTheme.Palette.cobalt
                            : OnboardingTheme.Palette.cobaltFaint
                    )
                    .frame(width: index == current ? 22 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// A white text field on the paper ground. Wraps whatever field you give
/// it, so the real TextField — and its binding, keyboard, and focus — is
/// untouched. This only changes how it looks.
struct OnboardingField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(OnboardingTheme.Typography.label(15))
                .foregroundStyle(OnboardingTheme.Palette.cobalt)

            content
                .font(OnboardingTheme.Typography.body(16))
                .foregroundStyle(OnboardingTheme.Palette.cobalt)
                .tint(OnboardingTheme.Palette.cobalt)
                .padding(OnboardingTheme.Metrics.fieldPadding)
                .background(
                    OnboardingTheme.Palette.fieldFill,
                    in: RoundedRectangle(cornerRadius: OnboardingTheme.Metrics.fieldRadius)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OnboardingTheme.Metrics.fieldRadius)
                        .strokeBorder(OnboardingTheme.Palette.cobaltFaint, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Hex helper

extension Color {
    /// Lets us write colours the way a design file does —
    /// Color(hex: 0x1E3AD9) instead of fiddling with 0–1 decimals.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

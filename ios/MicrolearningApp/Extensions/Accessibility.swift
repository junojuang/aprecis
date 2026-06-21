import SwiftUI
import UIKit

// MARK: - Accessibility foundation
//
// Shared helpers that let the app meet the App Store accessibility
// nutrition-label criteria without rewriting the bespoke editorial design:
//
//   • `scaledFont`  — Dynamic Type for the app's many fixed-size fonts.
//   • `motionAware` — Reduce Motion aware animations/transitions.
//   • contrast helpers — honor Increase Contrast for custom palette colors.
//
// The app uses `.font(.system(size:))` with hand-tuned pixel sizes in a
// hundred-plus places. Those do not scale with the user's text-size setting.
// `scaledFont` is a drop-in replacement: at the default text size it renders
// the exact same size, but it now grows and shrinks with Larger Text.

// MARK: - Dynamic Type

/// Picks a sensible Dynamic Type text style to scale a fixed pixel size
/// against, so display text and captions scale proportionally rather than
/// every size scaling off `.body`. Keeps very small UI chrome from ballooning.
private func defaultTextStyle(forSize size: CGFloat) -> Font.TextStyle {
    switch size {
    case ..<11:   return .caption2
    case ..<13:   return .caption
    case ..<15:   return .footnote
    case ..<17:   return .subheadline
    case ..<20:   return .body
    case ..<23:   return .title3
    case ..<28:   return .title2
    case ..<34:   return .title
    default:      return .largeTitle
    }
}

private struct ScaledFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, textStyle: Font.TextStyle) {
        self._size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// Dynamic Type aware replacement for `.font(.system(size:weight:design:))`.
    ///
    /// At the default content size this is visually identical to the fixed-size
    /// font it replaces; with Larger Text enabled the size scales relative to
    /// `textStyle` (auto-chosen from the size when omitted).
    ///
    ///     Text("Hello").scaledFont(size: 17, weight: .semibold, design: .serif)
    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle? = nil
    ) -> some View {
        modifier(ScaledFontModifier(
            size: size,
            weight: weight,
            design: design,
            textStyle: textStyle ?? defaultTextStyle(forSize: size)
        ))
    }
}

/// A Dynamic Type aware `Font` value (not a view modifier) for the rare cases
/// where `.scaledFont` cannot be used: `Text(...) + Text(...)` concatenations,
/// where each `.font(_:)` must return `Text`. Scales `size` against `textStyle`
/// using `UIFontMetrics`, so it grows with Larger Text like the modifier does.
func scaledSystemFont(
    _ size: CGFloat,
    weight: Font.Weight = .regular,
    design: Font.Design = .default,
    relativeTo textStyle: UIFont.TextStyle = .body
) -> Font {
    let scaled = UIFontMetrics(forTextStyle: textStyle).scaledValue(for: size)
    return .system(size: scaled, weight: weight, design: design)
}

// MARK: - Reduce Motion

extension View {
    /// Applies `animation` unless the user has Reduce Motion enabled, in which
    /// case the change is applied without a movement animation. Use for spring,
    /// slide, and scale animations that move content across the screen.
    ///
    ///     .motionAware(.spring(response: 0.36, dampingFraction: 0.86), value: showTrashDock)
    func motionAware<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(MotionAwareAnimation(animation: animation, value: value))
    }
}

private struct MotionAwareAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// A transition that crossfades instead of moving when Reduce Motion is on.
/// Pass the movement transition you would normally use; it degrades to
/// `.opacity` under Reduce Motion.
func motionAwareTransition(_ moving: AnyTransition) -> AnyTransition {
    UIAccessibility.isReduceMotionEnabled ? .opacity : moving
}

// MARK: - Increase Contrast

extension Color {
    /// Returns `highContrast` when the user has Increase Contrast enabled,
    /// otherwise `self`. Use for custom palette colors that sit close to their
    /// background (muted text, hairline borders, subtle accents).
    func contrastAware(_ highContrast: Color, when contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? highContrast : self
    }
}

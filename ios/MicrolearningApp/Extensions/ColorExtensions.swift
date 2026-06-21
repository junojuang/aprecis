import SwiftUI

// MARK: - Brand Palette (Light Editorial)

/// Cream paper background
let paperBg     = Color(hex: "f7f4ef")
/// Dark ink, primary text
let inkColor    = Color(hex: "0f1117")
/// Primary teal accent
let tealAccent  = Color(hex: "1a8a8a")
/// Light teal, tag backgrounds, tinted areas
let tealLight   = Color(hex: "e8f5f5")
/// Mid teal
let tealMid     = Color(hex: "2db8b8")
/// Amber accent
let amberAccent = Color(hex: "e8a020")
/// Muted text. Darkened from the original `#8a8f9a` to `#6b7078` so secondary
/// copy clears WCAG AA (~4.5:1) on the cream paper background — the old value
/// sat near 2.9:1, failing contrast for the many places muted text is used.
let mutedText   = Color(hex: "6b7078")
/// Card surface
let cardBg      = Color.white
/// Border
let borderColor = Color(hex: "0f1117").opacity(0.1)

/// Green used when a read-progress bar is near 100% (success cue).
let progressGreen = Color(hex: "2a7a4a")

/// Color for the reading-progress top bar. Stays teal for most of the page,
/// warms to amber above 70%, lands on green above 95%, a subtle "nearly there"
/// → "done" cue. Used by HomeView, PaperDetailView, BundleDetailView.
func progressBarColor(_ progress: Double) -> Color {
    switch progress {
    case ..<0.7:  return tealAccent
    case ..<0.95: return amberAccent
    default:      return progressGreen
    }
}

// MARK: - Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255)
    }
}

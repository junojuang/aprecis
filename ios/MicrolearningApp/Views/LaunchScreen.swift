import SwiftUI

// First-paint loading screen. Holds for ~1.6s. Restrained and layered: a
// warm paper wash, a soft vignette, and one slow teal halo behind the mark.
// The mark springs in with weight; a slim hairline sweeps below the wordmark
// as the single, calm loading cue.

struct LaunchScreen: View {
    @State private var markOpacity: Double     = 0
    @State private var markScale: Double       = 0.72
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkLift: CGFloat   = 10
    @State private var haloBreath: Double      = 0
    @State private var sweep: CGFloat          = 0

    private let trackWidth: CGFloat   = 132
    private let segmentWidth: CGFloat = 46

    var body: some View {
        ZStack {
            // Base paper, with a faint vertical warmth and an edge vignette
            // so the centre lifts forward.
            paperBg.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "5fd4d4").opacity(0.05), .clear,
                         Color(hex: "0e3434").opacity(0.04)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [.clear, inkColor.opacity(0.07)],
                center: .center, startRadius: 180, endRadius: 560
            )
            .ignoresSafeArea()

            // One teal halo behind the mark, slowly breathing.
            RadialGradient(
                colors: [Color(hex: "5fd4d4").opacity(0.14 + haloBreath * 0.05), .clear],
                center: .center, startRadius: 0, endRadius: 300
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
            .scaleEffect(0.97 + haloBreath * 0.06)

            VStack(spacing: 22) {
                AprecisMark(76)
                    .scaleEffect(markScale)
                    .opacity(markOpacity)
                    .shadow(color: Color(hex: "0e3434").opacity(0.18 * markOpacity),
                            radius: 22, x: 0, y: 12)

                HStack(spacing: 0) {
                    Text("aprecis")
                        .scaledFont(size: 26, weight: .semibold, design: .serif)
                        .foregroundStyle(tealAccent)
                    Text(".")
                        .scaledFont(size: 26, weight: .semibold, design: .serif)
                        .italic()
                        .foregroundStyle(inkColor)
                }
                .opacity(wordmarkOpacity)
                .offset(y: wordmarkLift)

                // Indeterminate hairline: a teal segment easing back and
                // forth along a faint track.
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(inkColor.opacity(0.08))
                        .frame(width: trackWidth, height: 2)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.clear, tealAccent, .clear],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: segmentWidth, height: 2)
                        .offset(x: sweep * (trackWidth - segmentWidth))
                }
                .opacity(wordmarkOpacity * 0.9)
                .padding(.top, 8)
            }
        }
        .onAppear { runIntro() }
    }

    private func runIntro() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) {
            markOpacity = 1
            markScale   = 1
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.22)) {
            wordmarkOpacity = 1
            wordmarkLift    = 0
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            haloBreath = 1
        }
        withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)
            .delay(0.3)) {
            sweep = 1
        }
    }
}

#Preview {
    LaunchScreen()
}

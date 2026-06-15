import SwiftUI

// MARK: - Premium interactive cards for "Efficient Estimation of Word
//                                       Representations in Vector Space"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for
// the Word2Vec paper. Design language mirrors the Attention / GPT-3 studios:
// cream prompt panels, teal accent, serif headlines, monospaced data,
// faint amber strips.
//
//   Card 04, Word2VecVectorView
//      "Meaning as geometry." Tap any word in a 2D semantic map. Its five
//      nearest neighbours light up with cosine bars. A toggle plays the
//      famous king minus man plus woman analogy as animated vector arrows
//      that land near queen.
//
//   Card 05, Word2VecNegSamplingView
//      "One thousand times faster." Drag a dial from full softmax through
//      negative sampling at K = 2, 5, 10, 20. Two race lanes collapse: ops
//      per example, seconds per million words, with quality holding flat.
//
//   Card 06, Word2VecArchView
//      "Predict from one, or to one." Toggle between CBOW and Skip-Gram on
//      the same five-word window. Arrows reverse direction; metrics flip:
//      speed for CBOW, rare-word quality for Skip-Gram.

// MARK: - Local design tokens (mirrors Attention studio)

private let w2vInk        = inkColor
private let w2vInkSubtle  = inkColor.opacity(0.65)
private let w2vPanelBg    = Color(hex: "f4ece0")
private let w2vPanelEdge  = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Vector Space Explorer
// =============================================================================

private struct W2VWord: Identifiable, Hashable {
    let id: Int
    let text: String
    let cluster: String        // "royalty" | "animals" | "capitals" | "gender"
    let x: CGFloat             // 0...1 normalised plot space
    let y: CGFloat
}

private let w2vWords: [W2VWord] = [
    // Royalty cluster, top-left
    W2VWord(id: 0, text: "king",     cluster: "royalty",  x: 0.18, y: 0.22),
    W2VWord(id: 1, text: "queen",    cluster: "royalty",  x: 0.27, y: 0.30),
    W2VWord(id: 2, text: "prince",   cluster: "royalty",  x: 0.12, y: 0.32),
    W2VWord(id: 3, text: "princess", cluster: "royalty",  x: 0.22, y: 0.42),
    // Animals cluster, right
    W2VWord(id: 4, text: "cat",      cluster: "animals",  x: 0.78, y: 0.36),
    W2VWord(id: 5, text: "dog",      cluster: "animals",  x: 0.84, y: 0.30),
    W2VWord(id: 6, text: "wolf",     cluster: "animals",  x: 0.88, y: 0.46),
    W2VWord(id: 7, text: "lion",     cluster: "animals",  x: 0.74, y: 0.48),
    // Capitals cluster, bottom-left
    W2VWord(id: 8,  text: "Paris",   cluster: "capitals", x: 0.20, y: 0.78),
    W2VWord(id: 9,  text: "Berlin",  cluster: "capitals", x: 0.28, y: 0.88),
    W2VWord(id: 10, text: "London",  cluster: "capitals", x: 0.14, y: 0.86),
    W2VWord(id: 11, text: "Rome",    cluster: "capitals", x: 0.30, y: 0.74),
    // Gender axis
    W2VWord(id: 12, text: "man",     cluster: "gender",   x: 0.45, y: 0.20),
    W2VWord(id: 13, text: "woman",   cluster: "gender",   x: 0.42, y: 0.32),
]

// Hardcoded cosine similarities. Per-source word, top 5 neighbours by id with
// approximate cosine values. Tuned to feel plausible: tight in-cluster, loose
// across clusters, and the king-man-woman ridge shows up clearly.
private struct W2VNeighbour: Hashable { let id: Int; let cos: Double }

private let w2vNeighbours: [Int: [W2VNeighbour]] = [
    0:  [.init(id: 1, cos: 0.74), .init(id: 2, cos: 0.71), .init(id: 3, cos: 0.66), .init(id: 12, cos: 0.45), .init(id: 13, cos: 0.40)],
    1:  [.init(id: 3, cos: 0.78), .init(id: 0, cos: 0.74), .init(id: 2, cos: 0.69), .init(id: 13, cos: 0.51), .init(id: 12, cos: 0.36)],
    2:  [.init(id: 0, cos: 0.71), .init(id: 3, cos: 0.69), .init(id: 1, cos: 0.69), .init(id: 12, cos: 0.34), .init(id: 13, cos: 0.30)],
    3:  [.init(id: 1, cos: 0.78), .init(id: 2, cos: 0.69), .init(id: 0, cos: 0.66), .init(id: 13, cos: 0.48), .init(id: 12, cos: 0.30)],
    4:  [.init(id: 5, cos: 0.85), .init(id: 7, cos: 0.62), .init(id: 6, cos: 0.58), .init(id: 3, cos: 0.18), .init(id: 11, cos: 0.12)],
    5:  [.init(id: 4, cos: 0.85), .init(id: 6, cos: 0.66), .init(id: 7, cos: 0.55), .init(id: 12, cos: 0.20), .init(id: 0, cos: 0.14)],
    6:  [.init(id: 5, cos: 0.66), .init(id: 7, cos: 0.65), .init(id: 4, cos: 0.58), .init(id: 0, cos: 0.18), .init(id: 11, cos: 0.10)],
    7:  [.init(id: 6, cos: 0.65), .init(id: 4, cos: 0.62), .init(id: 5, cos: 0.55), .init(id: 0, cos: 0.22), .init(id: 11, cos: 0.14)],
    8:  [.init(id: 9, cos: 0.81), .init(id: 10, cos: 0.78), .init(id: 11, cos: 0.75), .init(id: 12, cos: 0.18), .init(id: 0, cos: 0.10)],
    9:  [.init(id: 10, cos: 0.80), .init(id: 8, cos: 0.81), .init(id: 11, cos: 0.74), .init(id: 12, cos: 0.16), .init(id: 0, cos: 0.12)],
    10: [.init(id: 8, cos: 0.78), .init(id: 9, cos: 0.80), .init(id: 11, cos: 0.71), .init(id: 12, cos: 0.14), .init(id: 0, cos: 0.10)],
    11: [.init(id: 9, cos: 0.74), .init(id: 8, cos: 0.75), .init(id: 10, cos: 0.71), .init(id: 12, cos: 0.18), .init(id: 0, cos: 0.10)],
    12: [.init(id: 13, cos: 0.78), .init(id: 0, cos: 0.45), .init(id: 2, cos: 0.34), .init(id: 5, cos: 0.20), .init(id: 4, cos: 0.16)],
    13: [.init(id: 12, cos: 0.78), .init(id: 1, cos: 0.51), .init(id: 3, cos: 0.48), .init(id: 5, cos: 0.18), .init(id: 0, cos: 0.40)],
]

private let w2vVerdict: [Int: String] = [
    0:  "king sits at the top of the royalty cluster. Closest neighbour: queen at 0.74.",
    1:  "queen leans toward princess and king. Cross-cluster pull from woman betrays the gender axis.",
    2:  "prince mostly self-similar to other royals. Gender component is faint.",
    3:  "princess mirrors prince but tilts toward woman, the same offset that links king and queen.",
    4:  "cat and dog are the tightest pair on the map at 0.85.",
    5:  "dog clusters with cat and wolf. Outside animals, similarity collapses.",
    6:  "wolf bridges dog and lion. Predator context overlaps both.",
    7:  "lion holds the bottom-right of the animal cluster.",
    8:  "Paris pulls toward Berlin and London. The capital-of relation is a single shared offset.",
    9:  "Berlin sits between London and Rome. The cluster encodes country and capital simultaneously.",
    10: "London locks to Paris and Berlin. Geography and capital-of fold into one direction.",
    11: "Rome leans toward Berlin. Latin capitals and northern capitals both visible.",
    12: "man pairs strongly with woman, then leaks across to king and prince. The gender axis.",
    13: "woman mirrors man and reaches into queen and princess. The same offset, the other end.",
]

struct Word2VecVectorView: View {
    @ObservedObject var state: DailyLoopState
    @State private var selected: Int = 0
    @State private var visited: Set<Int> = [0]
    @State private var animPlay: Double = 0   // 0...1 progress for analogy arrows
    @State private var analogyMode: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · MEANING AS GEOMETRY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Tap any word. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(w2vInk)
                + Text("Watch its meaning resolve.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Each dot is a 300-dim vector projected to 2D. Cosine similarity ranks the five nearest. Toggle Analogy to play king − man + woman.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                analogyToggle
                    .padding(.bottom, 14)

                mapPanel
                    .padding(.bottom, 16)

                neighboursPanel
                    .padding(.bottom, 14)

                Text(analogyMode
                     ? "vec(king) − vec(man) + vec(woman) lands at cosine 0.74 of vec(queen). The same offset works for tense, plurality, capital-of."
                     : (w2vVerdict[selected] ?? ""))
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(w2vInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: selected) { _, _ in updateGate() }
    }

    private func updateGate() {
        // Need 4 words covering different clusters, OR play the analogy.
        let clusters = Set(visited.compactMap { id in w2vWords.first(where: { $0.id == id })?.cluster })
        if clusters.count >= 3 || analogyMode {
            state.customCardComplete.insert(3)
        }
    }

    private var analogyToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    analogyMode = false
                }
            } label: {
                Text("Explore")
                    .font(.system(size: 11, weight: analogyMode ? .regular : .semibold, design: .serif))
                    .foregroundStyle(analogyMode ? w2vInkSubtle : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(analogyMode ? Color.clear : tealAccent)
                    )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    analogyMode = true
                    animPlay = 0
                }
                withAnimation(.easeInOut(duration: 1.6).delay(0.05)) {
                    animPlay = 1
                }
                state.customCardComplete.insert(3)
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").font(.system(size: 9, weight: .bold))
                    Text("Analogy: king − man + woman")
                        .font(.system(size: 11, weight: analogyMode ? .semibold : .regular, design: .serif))
                }
                .foregroundStyle(analogyMode ? .white : w2vInkSubtle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(analogyMode ? tealAccent : Color.clear)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(w2vPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }

    private var mapPanel: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // grid
                ForEach(0..<5) { i in
                    let frac = CGFloat(i) / 4.0
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * frac))
                        p.addLine(to: CGPoint(x: w, y: h * frac))
                    }
                    .stroke(w2vPanelEdge.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    Path { p in
                        p.move(to: CGPoint(x: w * frac, y: 0))
                        p.addLine(to: CGPoint(x: w * frac, y: h))
                    }
                    .stroke(w2vPanelEdge.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                }

                // cluster halos
                clusterHalo(words: w2vWords.filter { $0.cluster == "royalty"  }, color: tealAccent,  w: w, h: h)
                clusterHalo(words: w2vWords.filter { $0.cluster == "animals"  }, color: amberAccent, w: w, h: h)
                clusterHalo(words: w2vWords.filter { $0.cluster == "capitals" }, color: Color(hex: "7b4ba4"), w: w, h: h)
                clusterHalo(words: w2vWords.filter { $0.cluster == "gender"   }, color: w2vInkSubtle, w: w, h: h)

                // analogy arrows
                if analogyMode {
                    analogyOverlay(w: w, h: h)
                }

                // neighbour arcs from selected
                if !analogyMode, let neigh = w2vNeighbours[selected] {
                    let src = w2vWords[selected]
                    ForEach(neigh, id: \.id) { n in
                        if let dst = w2vWords.first(where: { $0.id == n.id }) {
                            Path { p in
                                p.move(to: CGPoint(x: src.x * w, y: src.y * h))
                                p.addLine(to: CGPoint(x: dst.x * w, y: dst.y * h))
                            }
                            .stroke(tealAccent.opacity(0.18 + 0.6 * n.cos), lineWidth: 0.8)
                        }
                    }
                }

                // dots
                ForEach(w2vWords) { wd in
                    let isSel = wd.id == selected && !analogyMode
                    let isHi  = (w2vNeighbours[selected]?.contains(where: { $0.id == wd.id }) ?? false) && !analogyMode
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            selected = wd.id
                            analogyMode = false
                            visited.insert(wd.id)
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(isSel ? tealAccent
                                      : isHi  ? tealAccent.opacity(0.55)
                                      : Color.white)
                                .overlay(
                                    Circle().stroke(isSel ? tealAccent : w2vPanelEdge,
                                                    lineWidth: isSel ? 2 : 1)
                                )
                                .frame(width: isSel ? 12 : 8, height: isSel ? 12 : 8)
                            Text(wd.text)
                                .font(.system(size: isSel ? 11 : 10,
                                              weight: isSel ? .semibold : .regular,
                                              design: .serif))
                                .foregroundStyle(isSel ? w2vInk
                                                 : isHi ? tealAccent
                                                 : w2vInkSubtle)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(x: wd.x * w, y: wd.y * h)
                }
            }
        }
        .frame(height: 280)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func clusterHalo(words: [W2VWord], color: Color, w: CGFloat, h: CGFloat) -> some View {
        if !words.isEmpty {
            let cx = words.map { $0.x }.reduce(0, +) / CGFloat(words.count)
            let cy = words.map { $0.y }.reduce(0, +) / CGFloat(words.count)
            let radius: CGFloat = 64
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.10), .clear],
                                     center: .center,
                                     startRadius: 0, endRadius: radius))
                .frame(width: radius * 2, height: radius * 2)
                .position(x: cx * w, y: cy * h)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func analogyOverlay(w: CGFloat, h: CGFloat) -> some View {
        // king (id 0) → minus man (id 12) → plus woman (id 13) → result near queen (id 1)
        let king   = w2vWords[0]
        let man    = w2vWords[12]
        let woman  = w2vWords[13]
        let queen  = w2vWords[1]

        // animated points along path 0..1
        let p1Frac = min(1, animPlay * 3)            // king → man
        let p2Frac = min(1, max(0, (animPlay - 0.33) * 3))   // man  → woman offset
        let p3Frac = min(1, max(0, (animPlay - 0.66) * 3))   // sum  → queen

        let kx = king.x * w; let ky = king.y * h
        let mx = man.x  * w; let my = man.y  * h
        let wx = woman.x * w; let wy = woman.y * h
        let qx = queen.x * w; let qy = queen.y * h

        // Vector king - man = arrow ending at (king + (king - man)) ... we draw
        // intuitively: king to man (subtract direction reversed) and man to woman
        // (positive). Simpler visual: three arrows: king → man, man → woman,
        // sum → queen.
        Path { p in
            p.move(to: CGPoint(x: kx, y: ky))
            p.addLine(to: CGPoint(x: kx + (mx - kx) * p1Frac, y: ky + (my - ky) * p1Frac))
        }
        .stroke(amberAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 3]))

        Path { p in
            p.move(to: CGPoint(x: mx, y: my))
            p.addLine(to: CGPoint(x: mx + (wx - mx) * p2Frac, y: my + (wy - my) * p2Frac))
        }
        .stroke(tealAccent.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        Path { p in
            p.move(to: CGPoint(x: wx, y: wy))
            p.addLine(to: CGPoint(x: wx + (qx - wx) * p3Frac, y: wy + (qy - wy) * p3Frac))
        }
        .stroke(tealAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

        // result halo on queen
        if p3Frac >= 0.99 {
            Circle()
                .stroke(tealAccent, lineWidth: 2)
                .frame(width: 26, height: 26)
                .position(x: qx, y: qy)
            Text("≈ queen")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(.white).overlay(Capsule().stroke(tealAccent.opacity(0.4), lineWidth: 0.8)))
                .position(x: qx + 38, y: qy + 18)
        }
    }

    private var neighboursPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(analogyMode
                     ? "RESULT VECTOR · NEAREST WORDS"
                     : "NEAREST TO \"\(w2vWords[selected].text.uppercased())\"")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("cosine")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(w2vInkSubtle.opacity(0.7))
            }

            let rows: [W2VNeighbour] = analogyMode
                ? [.init(id: 1, cos: 0.74),
                   .init(id: 3, cos: 0.61),
                   .init(id: 13, cos: 0.55),
                   .init(id: 0, cos: 0.42),
                   .init(id: 2, cos: 0.39)]
                : (w2vNeighbours[selected] ?? [])

            VStack(spacing: 6) {
                ForEach(rows, id: \.id) { n in
                    if let wd = w2vWords.first(where: { $0.id == n.id }) {
                        HStack(spacing: 8) {
                            Text(wd.text)
                                .font(.system(size: 11, design: .serif))
                                .foregroundStyle(w2vInk)
                                .frame(width: 70, alignment: .trailing)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(tealAccent.opacity(0.10))
                                    Capsule()
                                        .fill(LinearGradient(colors: [tealAccent.opacity(0.55), tealAccent],
                                                             startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * CGFloat(n.cos))
                                }
                            }
                            .frame(height: 7)
                            Text(String(format: "%.2f", n.cos))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(n.cos > 0.5 ? tealAccent : w2vInkSubtle)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Card 05, Negative Sampling Speedup
// =============================================================================

private enum NegStop: Int, CaseIterable, Identifiable {
    case full, k20, k10, k5, k2
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .full: return "full"
        case .k20:  return "K=20"
        case .k10:  return "K=10"
        case .k5:   return "K=5"
        case .k2:   return "K=2"
        }
    }

    // Operations per training example. Vocab ≈ 1,000,000.
    var ops: Int {
        switch self {
        case .full: return 1_000_000
        case .k20:  return 21
        case .k10:  return 11
        case .k5:   return 6
        case .k2:   return 3
        }
    }

    // Approx wall-clock seconds to train on 100M words (relative scale).
    var seconds: Int {
        switch self {
        case .full: return 86_400      // ~1 day
        case .k20:  return 240
        case .k10:  return 130
        case .k5:   return 70
        case .k2:   return 35
        }
    }

    // Analogy accuracy on Mikolov's syntactic + semantic eval.
    var accuracy: Double {
        switch self {
        case .full: return 0.71
        case .k20:  return 0.71
        case .k10:  return 0.70
        case .k5:   return 0.68
        case .k2:   return 0.55
        }
    }

    // Bar fraction (log-shaped) for the cost lane. Full = 1.0, then collapses.
    var costFraction: Double {
        switch self {
        case .full: return 1.0
        case .k20:  return 0.044
        case .k10:  return 0.034
        case .k5:   return 0.027
        case .k2:   return 0.018
        }
    }

    var verdict: String {
        switch self {
        case .full: return "Full softmax. Every example touches every word in the vocabulary. Mathematically pure, computationally impossible at scale."
        case .k20:  return "K = 20 negatives. Quality matches full softmax. Cost drops 47,000×. The default for high-quality embeddings."
        case .k10:  return "K = 10. Marginal accuracy loss. The standard sweet spot for word2vec training in practice."
        case .k5:   return "K = 5. Quality holds within 3 points. Mikolov's original recommendation for small corpora."
        case .k2:   return "K = 2. Too aggressive. Quality starts to bleed, but training is now interactive on a laptop."
        }
    }
}

struct Word2VecNegSamplingView: View {
    @ObservedObject var state: DailyLoopState
    @State private var stop: NegStop = .k5
    @State private var visited: Set<Int> = [NegStop.k5.rawValue]
    @State private var animCost: Double = NegStop.k5.costFraction

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · THE 1000× TRICK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Skip the softmax. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(w2vInk)
                + Text("Sample a few negatives.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Drag the dial. Full softmax compares against all 1M words. Negative sampling contrasts the true context against K random words. Same gradient direction, far less work.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                stopDial
                    .padding(.bottom, 22)

                comparePanel
                    .padding(.bottom, 16)

                qualityStrip
                    .padding(.bottom, 14)

                Text(stop.verdict)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(w2vInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            visited.insert(stop.rawValue)
            animCost = stop.costFraction
            updateGate()
        }
        .onChange(of: stop) { _, newStop in
            visited.insert(newStop.rawValue)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                animCost = newStop.costFraction
            }
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= 3 {
            state.customCardComplete.insert(4)
        }
    }

    private var stopDial: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let stops = NegStop.allCases
                let usableWidth = geo.size.width - 28
                let stopX: (NegStop) -> CGFloat = { s in
                    14 + usableWidth * CGFloat(s.rawValue) / CGFloat(stops.count - 1)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(w2vPanelBg)
                        .frame(height: 6)
                        .overlay(Capsule().stroke(w2vPanelEdge, lineWidth: 1))

                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.4), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: stopX(stop), height: 6)

                    ForEach(stops) { s in
                        Circle()
                            .fill(stop.rawValue >= s.rawValue ? tealAccent : Color.white)
                            .overlay(Circle().stroke(stop == s ? tealAccent : w2vPanelEdge, lineWidth: stop == s ? 2 : 1))
                            .frame(width: stop == s ? 16 : 10, height: stop == s ? 16 : 10)
                            .offset(x: stopX(s) - (stop == s ? 8 : 5), y: 0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { stop = s }
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                    }
                }
                .frame(height: 22)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let frac = max(0, min(1, (v.location.x - 14) / max(1, usableWidth)))
                            let idx = Int(round(frac * CGFloat(stops.count - 1)))
                            let snapped = stops[min(stops.count - 1, max(0, idx))]
                            if snapped != stop {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { stop = snapped }
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                        }
                )
            }
            .frame(height: 22)

            HStack {
                ForEach(NegStop.allCases) { s in
                    VStack(spacing: 2) {
                        Text(s.label)
                            .font(.system(size: 11, weight: stop == s ? .semibold : .regular, design: .serif))
                            .foregroundStyle(stop == s ? w2vInk : mutedText)
                        Text(s == .full ? "softmax" : "negatives")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(stop == s ? tealAccent : mutedText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var comparePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("OPS PER TRAINING EXAMPLE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text(formatOps(stop.ops))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(w2vInk)
                    .contentTransition(.numericText())
            }

            barRow(label: "Full softmax",
                   tag: "1,000,000",
                   fraction: 1.0,
                   color: amberAccent,
                   note: "always")

            barRow(label: "Neg sampling",
                   tag: stop == .full ? "—" : "\(stop.ops)",
                   fraction: stop == .full ? 1.0 : max(animCost, 0.01),
                   color: tealAccent,
                   note: stop == .full ? "no shortcut" : "K + 1 ops")

            Divider().background(w2vPanelEdge).padding(.vertical, 2)

            HStack(spacing: 10) {
                statChip(label: "WALL-CLOCK", value: humanSeconds(stop.seconds))
                statChip(label: "SPEEDUP",    value: stop == .full ? "1×" : "\(speedup(stop))×")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func barRow(label: String, tag: String, fraction: Double, color: Color, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(w2vInk)
                Spacer()
                Text(tag)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color)
                Text(note)
                    .font(.system(size: 10, design: .serif))
                    .italic()
                    .foregroundStyle(w2vInkSubtle)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.65), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(min(fraction, 1.0))))
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func statChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(w2vInkSubtle.opacity(0.8))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(tealAccent)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(w2vPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }

    private func speedup(_ s: NegStop) -> String {
        let r = NegStop.full.ops / max(1, s.ops)
        if r >= 1000 {
            return "\(r / 1000)k"
        }
        return "\(r)"
    }

    private func formatOps(_ n: Int) -> String {
        if n >= 1_000_000 { return "1.0M ops" }
        if n >= 1_000     { return "\(n / 1000)k ops" }
        return "\(n) ops"
    }

    private func humanSeconds(_ s: Int) -> String {
        if s >= 3600 { return "≈\(s / 3600) h" }
        if s >= 60   { return "\(s / 60) min" }
        return "\(s) s"
    }

    private var qualityStrip: some View {
        HStack(spacing: 10) {
            Text("ANALOGY ACCURACY")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(w2vInkSubtle)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(qualityColor)
                    .frame(width: 7, height: 7)
                Text("\(Int(stop.accuracy * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(qualityColor)
                Text(qualityLabel)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(qualityColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(qualityColor.opacity(0.10))
                    .overlay(Capsule().stroke(qualityColor.opacity(0.35), lineWidth: 0.8))
            )
        }
        .padding(.horizontal, 4)
    }

    private var qualityColor: Color {
        switch stop {
        case .full, .k20, .k10: return Color(hex: "1f7a4d")
        case .k5:               return tealAccent
        case .k2:               return Color(hex: "b6502a")
        }
    }

    private var qualityLabel: String {
        switch stop {
        case .full, .k20: return "PEAK"
        case .k10, .k5:   return "STRONG"
        case .k2:         return "DEGRADED"
        }
    }
}

// =============================================================================
// MARK: - Card 06, CBOW vs Skip-Gram Architecture
// =============================================================================

private let archSentence = ["the", "cat", "sat", "on", "mat"]
private let archCenter = 2   // "sat"

struct Word2VecArchView: View {
    @ObservedObject var state: DailyLoopState
    @State private var skipGram: Bool = false
    @State private var visitedBoth: Set<Bool> = [false]
    @State private var arrowAnim: Double = 1

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · CBOW · SKIP GRAM")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Two ways. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(w2vInk)
                + Text("To learn from context.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Same data, opposite directions. CBOW averages neighbours to predict the centre. Skip-Gram uses the centre to predict each neighbour.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                modeToggle
                    .padding(.bottom, 18)

                archDiagram
                    .padding(.bottom, 18)

                metricsPanel
                    .padding(.bottom, 14)

                Text(skipGram
                     ? "Per-context updates produce sharper analogy directions. Each rare word gets its own gradient signal, so embeddings stay crisp deep in the long tail."
                     : "Averaging context vectors halves the work and dominates on speed. Frequent words get plenty of signal; rare words blur into their neighbours.")
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(w2vInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: skipGram) { _, newVal in
            visitedBoth.insert(newVal)
            withAnimation(.easeInOut(duration: 0.5)) {
                arrowAnim = 0
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                arrowAnim = 1
            }
            updateGate()
        }
    }

    private func updateGate() {
        if visitedBoth.count >= 2 {
            state.customCardComplete.insert(5)
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "CBOW", subtitle: "context → centre", on: !skipGram) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { skipGram = false }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            modeButton(title: "Skip-Gram", subtitle: "centre → context", on: skipGram) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { skipGram = true }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(w2vPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func modeButton(title: String, subtitle: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(on ? .white : w2vInk)
                Text(subtitle)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(on ? .white.opacity(0.85) : w2vInkSubtle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(on ? tealAccent : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var archDiagram: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let topY: CGFloat = 30
            let projY: CGFloat = h * 0.50
            let centerY: CGFloat = h - 32

            // Token X positions across the top row
            let count = archSentence.count
            let pad: CGFloat = 18
            let usable = w - pad * 2
            let xs: [CGFloat] = (0..<count).map { i in
                pad + usable * CGFloat(i) / CGFloat(count - 1)
            }
            let centerX = w / 2

            ZStack {
                // Background panel
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(w2vPanelEdge, lineWidth: 1))

                // Projection node (hidden layer)
                Circle()
                    .fill(w2vPanelBg)
                    .overlay(Circle().stroke(tealAccent.opacity(0.6), lineWidth: 1.2))
                    .frame(width: 60, height: 26)
                    .position(x: centerX, y: projY)
                Text(skipGram ? "PROJECTION" : "AVG")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(tealAccent)
                    .position(x: centerX, y: projY)

                // Edges from each context token <-> projection
                ForEach(0..<count, id: \.self) { i in
                    if i != archCenter {
                        contextEdge(from: CGPoint(x: xs[i], y: topY + 14),
                                    to:   CGPoint(x: centerX, y: projY - 14),
                                    skipGram: skipGram)
                    }
                }

                // Edge between projection and centre word
                centerEdge(from: CGPoint(x: centerX, y: projY + 14),
                           to:   CGPoint(x: centerX, y: centerY - 14),
                           skipGram: skipGram)

                // Top row tokens
                ForEach(0..<count, id: \.self) { i in
                    tokenChip(text: archSentence[i],
                              role: i == archCenter ? "TARGET" : "CONTEXT",
                              isCenter: i == archCenter && !skipGram,
                              dim: i == archCenter)
                        .position(x: xs[i], y: topY + 4)
                }

                // Bottom centre word
                tokenChip(text: archSentence[archCenter],
                          role: skipGram ? "SOURCE" : "PREDICT",
                          isCenter: true,
                          dim: false)
                    .position(x: centerX, y: centerY)

                // Arrows label
                Text(skipGram ? "centre predicts each neighbour" : "context averages, predicts centre")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(w2vInkSubtle)
                    .position(x: centerX, y: centerY + 28)
            }
        }
        .frame(height: 240)
    }

    @ViewBuilder
    private func contextEdge(from a: CGPoint, to b: CGPoint, skipGram: Bool) -> some View {
        // CBOW: arrows flow from context (top) → projection (centre).
        // Skip-Gram: arrows flow from projection (centre) → context (top).
        let start = skipGram ? b : a
        let end   = skipGram ? a : b

        // Animated draw
        Path { p in
            p.move(to: start)
            let mid = CGPoint(x: (start.x + end.x) / 2,
                              y: (start.y + end.y) / 2 + (skipGram ? -10 : 10))
            p.addQuadCurve(to: end, control: mid)
        }
        .trim(from: 0, to: max(0, min(1, arrowAnim)))
        .stroke(
            skipGram ? amberAccent.opacity(0.85) : tealAccent.opacity(0.85),
            style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: skipGram ? [3, 3] : [])
        )

        // Arrow head
        ArrowHead(at: end, from: start, color: skipGram ? amberAccent : tealAccent)
            .opacity(arrowAnim >= 0.95 ? 1 : 0)
    }

    @ViewBuilder
    private func centerEdge(from a: CGPoint, to b: CGPoint, skipGram: Bool) -> some View {
        // CBOW: projection → predicted centre word (downward).
        // Skip-Gram: source word → projection (upward).
        let start = skipGram ? b : a
        let end   = skipGram ? a : b

        Path { p in
            p.move(to: start)
            p.addLine(to: end)
        }
        .trim(from: 0, to: max(0, min(1, arrowAnim)))
        .stroke(tealAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))

        ArrowHead(at: end, from: start, color: tealAccent)
            .opacity(arrowAnim >= 0.95 ? 1 : 0)
    }

    @ViewBuilder
    private func tokenChip(text: String, role: String, isCenter: Bool, dim: Bool) -> some View {
        VStack(spacing: 2) {
            Text(role)
                .font(.system(size: 7, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(isCenter ? tealAccent : w2vInkSubtle.opacity(0.7))
            Text(text)
                .font(.system(size: isCenter ? 13 : 11,
                              weight: isCenter ? .semibold : .regular,
                              design: .serif))
                .foregroundStyle(dim ? w2vInkSubtle.opacity(0.5) : (isCenter ? .white : w2vInk))
                .padding(.horizontal, isCenter ? 12 : 8)
                .padding(.vertical, isCenter ? 6 : 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCenter ? tealAccent : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isCenter ? Color.clear : w2vPanelEdge, lineWidth: 1)
                        )
                        .opacity(dim ? 0.5 : 1)
                )
        }
    }

    private var metricsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRAINING TRADE-OFFS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(tealAccent.opacity(0.85))

            metricRow(label: "Speed",
                      cbow: 0.92, skip: 0.55,
                      winner: skipGram ? .cbow : .skip,
                      note: "CBOW averages once per window. Skip-Gram updates per neighbour.")

            metricRow(label: "Rare words",
                      cbow: 0.62, skip: 0.88,
                      winner: skipGram ? .skip : .cbow,
                      note: "Skip-Gram gives every context its own gradient. Rare vectors stay sharp.")

            metricRow(label: "Frequent words",
                      cbow: 0.86, skip: 0.84,
                      winner: skipGram ? .skip : .cbow,
                      note: "Roughly tied. Both architectures see plenty of signal here.")

            metricRow(label: "Analogies",
                      cbow: 0.74, skip: 0.86,
                      winner: skipGram ? .skip : .cbow,
                      note: "Skip-Gram's per-context updates produce sharper directions in vector space.")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(w2vPanelEdge, lineWidth: 1))
        )
    }

    private enum MetricWinner { case cbow, skip }

    @ViewBuilder
    private func metricRow(label: String, cbow: Double, skip: Double, winner: MetricWinner, note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(w2vInk)
                Spacer()
                Text(winner == .cbow ? "CBOW" : "SKIP")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(winner == .cbow ? amberAccent : tealAccent))
            }
            HStack(spacing: 6) {
                Text("CBOW")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(w2vInkSubtle)
                    .frame(width: 38, alignment: .trailing)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(amberAccent.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [amberAccent.opacity(0.55), amberAccent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(cbow))
                    }
                }
                .frame(height: 6)
            }
            HStack(spacing: 6) {
                Text("SKIP")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(w2vInkSubtle)
                    .frame(width: 38, alignment: .trailing)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tealAccent.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [tealAccent.opacity(0.55), tealAccent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(skip))
                    }
                }
                .frame(height: 6)
            }
            Text(note)
                .font(.system(size: 10, design: .serif))
                .italic()
                .foregroundStyle(w2vInkSubtle.opacity(0.85))
        }
    }
}

// MARK: - Arrow head shape

private struct ArrowHead: View {
    let at: CGPoint
    let from: CGPoint
    let color: Color
    var size: CGFloat = 6

    var body: some View {
        let dx = at.x - from.x
        let dy = at.y - from.y
        let len = max(0.0001, sqrt(dx * dx + dy * dy))
        let ux = dx / len
        let uy = dy / len
        // Two perpendiculars
        let px = -uy
        let py = ux

        let tip   = at
        let leftP = CGPoint(x: at.x - ux * size + px * (size * 0.7),
                            y: at.y - uy * size + py * (size * 0.7))
        let rightP = CGPoint(x: at.x - ux * size - px * (size * 0.7),
                             y: at.y - uy * size - py * (size * 0.7))

        Path { p in
            p.move(to: tip)
            p.addLine(to: leftP)
            p.addLine(to: rightP)
            p.closeSubpath()
        }
        .fill(color)
    }
}

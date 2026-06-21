import SwiftUI

// MARK: - Premium interactive cards for "Attention Is All You Need"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for the
// Transformer paper. Design language mirrors the GPT-3 studio: cream prompt
// panels, teal accent, serif headlines, monospaced data, light amber strips.
//
//   Card 04, AttentionFlowView
//      "Every word is rebuilt." Tap any token to make it the query. The Q · Kᵀ
//      scores resolve through softmax into a weighted blend of V. Bars below
//      animate per query.
//
//   Card 05, AttentionCorefView
//      "It points to the animal." The canonical coreference demonstration.
//      Tap any word; see what it pays attention to. Selecting "it" surfaces
//      the famous peak on "animal".
//
//   Card 06, AttentionPathLengthView
//      "One step, any distance." A scrub dial sweeps sequence length. Two
//      capsules race: Transformer holds at 1 step; RNN scales linearly. A
//      gradient-health badge collapses from "alive" to "dead" past n≈100.

// MARK: - Local design tokens (mirrors GPT-3 studio)

private let attInk        = inkColor
private let attInkSubtle  = inkColor.opacity(0.65)
private let attPanelBg    = Color(hex: "f4ece0")
private let attPanelEdge  = Color(hex: "e2d8c6")
private let attCorrect    = Color(hex: "1f7a4d")
private let attWrong      = Color(hex: "b6502a")

// =============================================================================
// MARK: - Card 04, Self-Attention Flow
// =============================================================================

private struct AttToken: Identifiable, Hashable {
    let id: Int
    let text: String
}

private let flowSentence: [AttToken] = [
    AttToken(id: 0, text: "The"),
    AttToken(id: 1, text: "cat"),
    AttToken(id: 2, text: "that"),
    AttToken(id: 3, text: "I"),
    AttToken(id: 4, text: "saw"),
    AttToken(id: 5, text: "was"),
    AttToken(id: 6, text: "tired"),
]

// Hardcoded attention distributions per query token. Sums ≈ 1.0. Designed to
// feel plausible: subjects bind to verbs across long spans, copulas reach back
// to their nominal subject, determiners stay local.
private let flowWeights: [Int: [Double]] = [
    0: [0.62, 0.22, 0.04, 0.02, 0.03, 0.04, 0.03],   // "The"  → mostly self + cat
    1: [0.10, 0.45, 0.06, 0.04, 0.10, 0.09, 0.16],   // "cat"  → self + tired
    2: [0.04, 0.28, 0.18, 0.12, 0.30, 0.04, 0.04],   // "that" → cat / saw bridge
    3: [0.03, 0.06, 0.10, 0.32, 0.42, 0.04, 0.03],   // "I"    → saw
    4: [0.03, 0.18, 0.08, 0.30, 0.30, 0.05, 0.06],   // "saw"  → I + cat
    5: [0.05, 0.40, 0.04, 0.04, 0.06, 0.18, 0.23],   // "was"  → cat (subject) + tired
    6: [0.04, 0.34, 0.02, 0.02, 0.04, 0.20, 0.34],   // "tired"→ self + cat + was
]

private let flowVerdict: [Int: String] = [
    0: "A determiner. Most attention stays on itself; a sliver leaks to its noun.",
    1: "The subject. Reaches forward to \"tired\", the predicate that defines it.",
    2: "A relative pronoun. Bridges the noun \"cat\" to the embedded clause.",
    3: "The embedded subject. Locks onto its verb, \"saw\".",
    4: "The embedded verb. Attends to its subject \"I\" and its object \"cat\".",
    5: "The copula. Reaches back across the relative clause to \"cat\".",
    6: "The predicate. Resolves to the head noun \"cat\" and the copula \"was\".",
]

struct AttentionFlowView: View {
    @ObservedObject var state: DailyLoopState
    @State private var query: Int = 1
    @State private var animatedWeights: [Double] = Array(repeating: 0, count: 7)
    @State private var visited: Set<Int> = [1]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · SELF ATTENTION")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Every word. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(attInk)
                + Text("Rebuilt from the rest.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap a token to make it the query. Q · Kᵀ scores who matters. Softmax turns scores into weights. The output is a weighted blend of V.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                tokenStrip
                    .padding(.bottom, 16)

                formulaPanel
                    .padding(.bottom, 16)

                weightsPanel
                    .padding(.bottom, 14)

                Text(flowVerdict[query] ?? "")
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(attInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            animateTo(query)
            updateGate()
        }
        .onChange(of: query) { _, newQ in
            visited.insert(newQ)
            animateTo(newQ)
            updateGate()
        }
    }

    private func animateTo(_ q: Int) {
        let target = flowWeights[q] ?? Array(repeating: 0, count: 7)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            animatedWeights = target
        }
    }

    private func updateGate() {
        if visited.count >= flowSentence.count {
            state.customCardComplete.insert(3)
        }
    }

    private var tokenStrip: some View {
        HStack(spacing: 6) {
            ForEach(flowSentence) { tok in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        query = tok.id
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        Text(query == tok.id ? "Q" : " ")
                            .font(scaledSystemFont(8, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(tealAccent)
                            .frame(height: 9)
                        Text(tok.text)
                            .font(scaledSystemFont(12, weight: query == tok.id ? .semibold : .regular, design: .serif))
                            .foregroundStyle(query == tok.id ? .white : attInk.opacity(0.78))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 9)
                            .frame(minWidth: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(query == tok.id ? tealAccent : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(query == tok.id ? Color.clear : attPanelEdge, lineWidth: 1)
                                    )
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formulaPanel: some View {
        HStack(spacing: 10) {
            Text("softmax")
                .font(scaledSystemFont(11, weight: .semibold, design: .serif))
                .foregroundStyle(attInkSubtle)
                .italic()
            Text("(")
                .font(scaledSystemFont(14, design: .serif))
                .foregroundStyle(attInkSubtle)
            VStack(spacing: 1) {
                Text("Q · Kᵀ")
                    .font(scaledSystemFont(11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(tealAccent)
                Rectangle().fill(attPanelEdge).frame(height: 0.6)
                Text("√dₖ")
                    .font(scaledSystemFont(10, design: .monospaced))
                    .foregroundStyle(attInkSubtle)
            }
            .fixedSize()
            Text(")")
                .font(scaledSystemFont(14, design: .serif))
                .foregroundStyle(attInkSubtle)
            Text("V")
                .font(scaledSystemFont(13, weight: .semibold, design: .monospaced))
                .foregroundStyle(amberAccent)
            Spacer(minLength: 0)
            Text("EQ. 1")
                .font(scaledSystemFont(8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(attInkSubtle.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(attPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(attPanelEdge, lineWidth: 1))
        )
    }

    private var weightsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ATTENTION FROM \"\(flowSentence[query].text.uppercased())\"")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("Σ = 1.0")
                    .font(scaledSystemFont(8, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(attInkSubtle.opacity(0.7))
            }

            VStack(spacing: 6) {
                ForEach(flowSentence) { tok in
                    let w = animatedWeights[tok.id]
                    let isSelf = tok.id == query
                    HStack(spacing: 8) {
                        Text(tok.text)
                            .font(scaledSystemFont(11, design: .serif))
                            .foregroundStyle(isSelf ? attInk : attInkSubtle)
                            .frame(width: 50, alignment: .trailing)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(tealAccent.opacity(0.10))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [tealAccent.opacity(0.55), tealAccent],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(w))
                            }
                        }
                        .frame(height: 7)
                        Text(String(format: "%.2f", w))
                            .font(scaledSystemFont(10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(w > 0.25 ? tealAccent : attInkSubtle)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(attPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Card 05, Coreference
// =============================================================================

private let corefSentence: [AttToken] = [
    AttToken(id: 0, text: "The"),
    AttToken(id: 1, text: "animal"),
    AttToken(id: 2, text: "didn't"),
    AttToken(id: 3, text: "cross"),
    AttToken(id: 4, text: "the"),
    AttToken(id: 5, text: "street"),
    AttToken(id: 6, text: "because"),
    AttToken(id: 7, text: "it"),
    AttToken(id: 8, text: "was"),
    AttToken(id: 9, text: "tired"),
]

// Per-query attention distributions. The headline is row 7 ("it") → animal.
private let corefWeights: [Int: [Double]] = [
    0: [0.55, 0.30, 0.03, 0.03, 0.02, 0.03, 0.01, 0.01, 0.01, 0.01],
    1: [0.12, 0.38, 0.08, 0.10, 0.02, 0.06, 0.02, 0.04, 0.05, 0.13],
    2: [0.04, 0.22, 0.18, 0.36, 0.02, 0.06, 0.02, 0.02, 0.04, 0.04],
    3: [0.03, 0.18, 0.14, 0.25, 0.05, 0.28, 0.02, 0.01, 0.02, 0.02],
    4: [0.10, 0.04, 0.02, 0.04, 0.45, 0.32, 0.01, 0.01, 0.01, 0.01],
    5: [0.04, 0.20, 0.04, 0.20, 0.10, 0.32, 0.04, 0.02, 0.02, 0.02],
    6: [0.02, 0.10, 0.06, 0.10, 0.02, 0.16, 0.20, 0.10, 0.10, 0.14],
    7: [0.04, 0.43, 0.04, 0.06, 0.02, 0.06, 0.04, 0.04, 0.10, 0.17],   // "it" → animal
    8: [0.03, 0.30, 0.04, 0.04, 0.02, 0.04, 0.04, 0.18, 0.10, 0.21],
    9: [0.03, 0.36, 0.04, 0.04, 0.02, 0.04, 0.04, 0.16, 0.16, 0.11],
]

private let corefVerdict: [Int: String] = [
    0: "Determiner. Locks onto its noun and itself.",
    1: "Head noun. Reaches forward to \"tired\" through the long causal clause.",
    2: "Negation. Pulls in its verb \"cross\" and the subject it negates.",
    3: "Verb of motion. Splits between subject \"animal\" and object \"street\".",
    4: "Article. Almost entirely local; ties to \"street\" with a glance back at the prior \"the\".",
    5: "The detoured object. Holds its determiner and the subject doing the not-crossing.",
    6: "Causal hinge. Spreads attention across both clauses, the bridge between cause and effect.",
    7: "The pronoun. 43% of its attention lands on \"animal\". Coreference, learned without a rule.",
    8: "Copula. Reaches back across the clause to its true subject, \"animal\".",
    9: "Predicate. Resolves through \"was\" to the antecedent \"animal\".",
]

struct AttentionCorefView: View {
    @ObservedObject var state: DailyLoopState
    @State private var query: Int = 7
    @State private var animatedWeights: [Double] = Array(repeating: 0, count: 10)
    @State private var visited: Set<Int> = [7]
    @State private var pulse: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · COREFERENCE EMERGES")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("It points. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(attInk)
                + Text("To the animal.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Famous self-attention pattern from Vaswani et al. Tap any token; the bars are the weights it pays to every other word. No rule was written for coreference, the model learns it from data.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                sentencePanel
                    .padding(.bottom, 14)

                heatmapPanel
                    .padding(.bottom, 12)

                Text(corefVerdict[query] ?? "")
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(query == 7 ? tealAccent : attInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            animateTo(query)
            updateGate()
            pulseHeadline()
        }
        .onChange(of: query) { _, newQ in
            visited.insert(newQ)
            animateTo(newQ)
            updateGate()
            if newQ == 7 { pulseHeadline() }
        }
    }

    private func animateTo(_ q: Int) {
        let target = corefWeights[q] ?? Array(repeating: 0, count: 10)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            animatedWeights = target
        }
    }

    private func updateGate() {
        if visited.count >= 5 {
            state.customCardComplete.insert(4)
        }
    }

    private func pulseHeadline() {
        pulse = false
        withAnimation(.easeInOut(duration: 0.35).repeatCount(2, autoreverses: true).delay(0.1)) {
            pulse = true
        }
    }

    private var sentencePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SENTENCE")
                    .font(scaledSystemFont(8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(attInkSubtle)
                Spacer()
                Text("TAP TO QUERY")
                    .font(scaledSystemFont(8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
            }

            FlowLayout(spacing: 5, runSpacing: 8) {
                ForEach(corefSentence) { tok in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            query = tok.id
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Text(tok.text)
                            .font(scaledSystemFont(13, weight: query == tok.id ? .semibold : .regular, design: .serif))
                            .foregroundStyle(query == tok.id ? .white : attInk.opacity(0.78))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(query == tok.id ? tealAccent : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(query == tok.id ? Color.clear : attPanelEdge, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(attPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(attPanelEdge, lineWidth: 1))
        )
    }

    private var heatmapPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ATTENTION WEIGHTS")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("FROM \"\(corefSentence[query].text.uppercased())\"")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(attInkSubtle)
            }

            VStack(spacing: 5) {
                ForEach(corefSentence) { tok in
                    let w = animatedWeights[tok.id]
                    let isAnimal = (query == 7 && tok.id == 1)
                    HStack(spacing: 8) {
                        Text(tok.text)
                            .font(scaledSystemFont(11, weight: isAnimal ? .semibold : .regular, design: .serif))
                            .foregroundStyle(isAnimal ? tealAccent : attInkSubtle)
                            .frame(width: 60, alignment: .trailing)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(tealAccent.opacity(0.10))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [tealAccent.opacity(0.55), tealAccent],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(w))
                                    .scaleEffect(x: isAnimal && pulse ? 1.0 : 1.0, y: 1.0)
                                if isAnimal {
                                    Capsule()
                                        .stroke(tealAccent, lineWidth: 1)
                                        .opacity(pulse ? 0.6 : 0)
                                        .frame(width: geo.size.width * CGFloat(w), height: 7)
                                }
                            }
                        }
                        .frame(height: 7)
                        Text(String(format: "%.2f", w))
                            .font(scaledSystemFont(10, weight: w > 0.30 ? .semibold : .regular, design: .monospaced))
                            .foregroundStyle(w > 0.30 ? tealAccent : attInkSubtle)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(attPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Card 06, Path Length
// =============================================================================

private enum SeqStop: Int, CaseIterable, Identifiable {
    case n10, n50, n100, n500, n1k
    var id: Int { rawValue }
    var n: Int {
        switch self {
        case .n10: return 10
        case .n50: return 50
        case .n100: return 100
        case .n500: return 500
        case .n1k: return 1000
        }
    }
    var label: String {
        switch self {
        case .n10: return "10"
        case .n50: return "50"
        case .n100: return "100"
        case .n500: return "500"
        case .n1k: return "1k"
        }
    }
    var sublabel: String {
        switch self {
        case .n10: return "short"
        case .n50: return "para"
        case .n100: return "page"
        case .n500: return "essay"
        case .n1k: return "long"
        }
    }
    /// 0...1 fraction of the longest scale, used to size the RNN bar.
    var rnnFraction: Double { Double(n) / 1000.0 }
    var gradientHealth: GradientHealth {
        switch self {
        case .n10, .n50: return .alive
        case .n100: return .fading
        case .n500, .n1k: return .dead
        }
    }
    var verdict: String {
        switch self {
        case .n10:  return "Short context. RNN copes; gradients still pass cleanly through 10 hops."
        case .n50:  return "A paragraph. Vanishing starts to bite, but training survives."
        case .n100: return "A page. RNN gradients shrink to noise. Training stalls. Transformer unaffected."
        case .n500: return "Essay length. RNN is effectively dead. Transformer pays in compute, not depth."
        case .n1k:  return "Long context. RNNs cannot learn dependencies this far apart. Transformers can."
        }
    }
}

private enum GradientHealth: String {
    case alive, fading, dead
    var label: String {
        switch self {
        case .alive:  return "ALIVE"
        case .fading: return "FADING"
        case .dead:   return "VANISHED"
        }
    }
    var color: Color {
        switch self {
        case .alive:  return attCorrect
        case .fading: return amberAccent
        case .dead:   return attWrong
        }
    }
}

struct AttentionPathLengthView: View {
    @ObservedObject var state: DailyLoopState
    @State private var stop: SeqStop = .n50
    @State private var rnnAnim: Double = 0.05
    @State private var visited: Set<Int> = [SeqStop.n50.rawValue]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · WHY ATTENTION WON")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("One step. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(attInk)
                + Text("Any distance.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Drag the dial. Transformer connects any two tokens in 1 hop. RNN walks the whole sequence, and the gradient travels every step.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                seqDial
                    .padding(.bottom, 22)

                comparePanel
                    .padding(.bottom, 16)

                gradientStrip
                    .padding(.bottom, 14)

                Text(stop.verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(stop.gradientHealth.color)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            rnnAnim = stop.rnnFraction
            visited.insert(stop.rawValue)
            updateGate()
        }
        .onChange(of: stop) { _, newStop in
            visited.insert(newStop.rawValue)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                rnnAnim = newStop.rnnFraction
            }
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= SeqStop.allCases.count {
            state.customCardComplete.insert(5)
        }
    }

    private var seqDial: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let stops = SeqStop.allCases
                let usableWidth = geo.size.width - 28
                let stopX: (SeqStop) -> CGFloat = { s in
                    14 + usableWidth * CGFloat(s.rawValue) / CGFloat(stops.count - 1)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(attPanelBg)
                        .frame(height: 6)
                        .overlay(Capsule().stroke(attPanelEdge, lineWidth: 1))

                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.4), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: stopX(stop), height: 6)

                    ForEach(stops) { s in
                        Circle()
                            .fill(stop.rawValue >= s.rawValue ? tealAccent : Color.white)
                            .overlay(Circle().stroke(stop == s ? tealAccent : attPanelEdge, lineWidth: stop == s ? 2 : 1))
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
                ForEach(SeqStop.allCases) { s in
                    VStack(spacing: 2) {
                        Text("n=\(s.label)")
                            .font(scaledSystemFont(11, weight: stop == s ? .semibold : .regular, design: .serif))
                            .foregroundStyle(stop == s ? attInk : mutedText)
                        Text(s.sublabel.uppercased())
                            .font(scaledSystemFont(8, weight: .semibold))
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
                Text("STEPS BETWEEN ANY TWO TOKENS")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("n=\(stop.n)")
                    .font(scaledSystemFont(11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(attInk)
                    .contentTransition(.numericText())
            }

            barRow(label: "Transformer",
                   tag: "1",
                   fraction: 0.06,
                   color: tealAccent,
                   note: "constant")

            barRow(label: "RNN",
                   tag: "\(stop.n)",
                   fraction: max(rnnAnim, 0.05),
                   color: amberAccent,
                   note: "= n hops")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(attPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func barRow(label: String, tag: String, fraction: Double, color: Color, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(scaledSystemFont(12, weight: .semibold, design: .serif))
                    .foregroundStyle(attInk)
                Spacer()
                Text(tag)
                    .font(scaledSystemFont(11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color)
                Text(note)
                    .font(scaledSystemFont(10, design: .serif))
                    .italic()
                    .foregroundStyle(attInkSubtle)
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

    private var gradientStrip: some View {
        HStack(spacing: 10) {
            Text("RNN GRADIENT")
                .font(scaledSystemFont(9, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(attInkSubtle)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(stop.gradientHealth.color)
                    .frame(width: 7, height: 7)
                Text(stop.gradientHealth.label)
                    .font(scaledSystemFont(10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(stop.gradientHealth.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(stop.gradientHealth.color.opacity(0.10))
                    .overlay(Capsule().stroke(stop.gradientHealth.color.opacity(0.35), lineWidth: 0.8))
            )
        }
        .padding(.horizontal, 4)
    }
}

// =============================================================================
// MARK: - FlowLayout (wraps tokens to multiple lines)
// =============================================================================

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var runSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widest: CGFloat = 0

        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 {
                totalHeight += rowHeight + runSpacing
                widest = max(widest, x - spacing)
                x = 0
                rowHeight = 0
            }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        totalHeight += rowHeight
        widest = max(widest, x - spacing)
        return CGSize(width: min(maxWidth, widest), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: s.width, height: s.height))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

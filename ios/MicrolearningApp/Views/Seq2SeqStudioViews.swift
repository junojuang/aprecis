import SwiftUI

// MARK: - Premium interactive cards for "Sequence to Sequence Learning with
//                                       Neural Networks"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for
// the Seq2Seq paper. Design language mirrors the Word2Vec / AlexNet
// studios: cream prompt panels, teal accent, serif headlines, monospaced
// data, faint amber strips.
//
//   Card 04, Seq2SeqPipelineView
//      "One sticky note, two languages." Step through the encode-decode
//      pipeline. Source tokens get consumed left to right (reversed),
//      crushed into a single thought vector, then expanded into target
//      tokens one at a time.
//
//   Card 05, Seq2SeqLengthView
//      "The thought vector has a length limit." Drag the dial across
//      sentence length 5 → 60 tokens. Two curves diverge: seq2seq
//      crashes past 20, phrase-based MT holds flat. The thought vector
//      capacity gauge fills, then overflows.
//
//   Card 06, Seq2SeqReverseView
//      "Reverse the source, gain five BLEU." Toggle forward vs reversed
//      source. The unrolled gradient path between matching tokens shrinks
//      from O(n) hops to O(1).

// MARK: - Local design tokens

private let s2sInk        = inkColor
private let s2sInkSubtle  = inkColor.opacity(0.65)
private let s2sPanelBg    = Color(hex: "f4ece0")
private let s2sPanelEdge  = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Encode-Decode Pipeline
// =============================================================================

private enum S2SStage: Int, CaseIterable, Identifiable {
    case source, encoder, context, decoder, target
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .source:  return "SOURCE"
        case .encoder: return "ENCODER"
        case .context: return "THOUGHT"
        case .decoder: return "DECODER"
        case .target:  return "TARGET"
        }
    }

    var caption: String {
        switch self {
        case .source:
            return "Source tokenised and reversed. \"I love cats\" → [cats, love, I]. Reversal shortens the gradient path between early source and early target tokens."
        case .encoder:
            return "An LSTM consumes the reversed source one token at a time, updating its hidden state. Every intermediate state is discarded; only the final state survives."
        case .context:
            return "A single 1000-dim vector. The whole sentence, reduced to one point. The bottleneck that motivated attention three years later."
        case .decoder:
            return "A second LSTM, initialised with the thought vector, predicts target tokens one step at a time. Each prediction conditions the next."
        case .target:
            return "Target sentence emerges left to right, ending at <EOS>. Beam search at decode time keeps the top-k candidate sequences alive."
        }
    }
}

private let s2sSource = ["I", "love", "cats"]              // input order
private let s2sReversed = ["cats", "love", "I"]            // fed to encoder
private let s2sTarget = ["J'aime", "les", "chats"]

struct Seq2SeqPipelineView: View {
    @ObservedObject var state: DailyLoopState
    @State private var stage: S2SStage = .source
    @State private var visited: Set<S2SStage> = [.source]
    @State private var pulse: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · COMPRESS, EXPAND")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("One sticky note. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(s2sInk)
                + Text("Two languages.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap each stage to see how a sentence becomes a single vector and back again. The thought vector in the middle is the bottleneck.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                pipelinePanel
                    .padding(.bottom, 16)

                stagePicker
                    .padding(.bottom, 14)

                Text(stage.caption)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(s2sInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            updateGate()
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
        .onChange(of: stage) { _, _ in updateGate() }
    }

    private func updateGate() {
        if visited.count >= S2SStage.allCases.count {
            state.customCardComplete.insert(3)
        }
    }

    private var pipelinePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("EN → FR · \"I love cats\"")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("LSTM · 1000 dim")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(s2sInkSubtle.opacity(0.7))
            }

            // Source row, reversed
            VStack(alignment: .leading, spacing: 6) {
                Text("SOURCE (reversed in)")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(stage == .source ? tealAccent : s2sInkSubtle.opacity(0.7))
                HStack(spacing: 6) {
                    ForEach(Array(s2sReversed.enumerated()), id: \.offset) { (_, t) in
                        tokenChip(text: t, on: stage == .source, color: tealAccent)
                    }
                    Spacer()
                }
            }

            // Encoder row, three LSTM cells with hidden state arrow
            VStack(alignment: .leading, spacing: 6) {
                Text("ENCODER · LSTM CELLS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(stage == .encoder ? tealAccent : s2sInkSubtle.opacity(0.7))
                HStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        cellChip(label: "h\(i+1)", color: amberAccent, active: stage == .encoder)
                        if i < 2 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(stage == .encoder ? amberAccent : s2sInkSubtle.opacity(0.5))
                                .frame(width: 18)
                        }
                    }
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(stage == .encoder || stage == .context ? amberAccent : s2sInkSubtle.opacity(0.5))
                        .frame(width: 18)
                    Spacer()
                }
            }

            // Context: single thought vector node
            HStack(spacing: 10) {
                Text("THOUGHT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(stage == .context ? tealAccent : s2sInkSubtle.opacity(0.7))
                ZStack {
                    Circle()
                        .fill(stage == .context ? tealAccent : tealAccent.opacity(0.18))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(tealAccent, lineWidth: stage == .context ? 2 : 1)
                                .scaleEffect(1 + 0.18 * (stage == .context ? pulse : 0))
                                .opacity(stage == .context ? 1 - pulse * 0.7 : 0)
                        )
                    Text("c")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(stage == .context ? .white : tealAccent)
                }
                Text("1×1000")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(s2sInkSubtle)
                Spacer()
                Text("← bottleneck")
                    .font(.system(size: 9, design: .serif))
                    .italic()
                    .foregroundStyle(stage == .context ? tealAccent : s2sInkSubtle.opacity(0.7))
            }
            .padding(.vertical, 4)

            // Decoder row
            VStack(alignment: .leading, spacing: 6) {
                Text("DECODER · LSTM CELLS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(stage == .decoder ? tealAccent : s2sInkSubtle.opacity(0.7))
                HStack(spacing: 0) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(stage == .decoder || stage == .context ? amberAccent : s2sInkSubtle.opacity(0.5))
                        .frame(width: 18)
                    ForEach(0..<3) { i in
                        cellChip(label: "h'\(i+1)", color: amberAccent, active: stage == .decoder)
                        if i < 2 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(stage == .decoder ? amberAccent : s2sInkSubtle.opacity(0.5))
                                .frame(width: 18)
                        }
                    }
                    Spacer()
                }
            }

            // Target row
            VStack(alignment: .leading, spacing: 6) {
                Text("TARGET (left to right)")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(stage == .target ? tealAccent : s2sInkSubtle.opacity(0.7))
                HStack(spacing: 6) {
                    ForEach(Array(s2sTarget.enumerated()), id: \.offset) { (_, t) in
                        tokenChip(text: t, on: stage == .target, color: tealAccent)
                    }
                    tokenChip(text: "<EOS>", on: stage == .target, color: s2sInkSubtle, mono: true)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(s2sPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func tokenChip(text: String, on: Bool, color: Color, mono: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 11,
                          weight: on ? .semibold : .regular,
                          design: mono ? .monospaced : .serif))
            .foregroundStyle(on ? .white : s2sInk)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(on ? color : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(on ? Color.clear : s2sPanelEdge, lineWidth: 1)
                    )
            )
    }

    @ViewBuilder
    private func cellChip(label: String, color: Color, active: Bool) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(active ? .white : color)
            .frame(width: 38, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(active ? color : color.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(color.opacity(active ? 0 : 0.5), lineWidth: 1))
            )
    }

    private var stagePicker: some View {
        HStack(spacing: 6) {
            ForEach(S2SStage.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        stage = s
                    }
                    visited.insert(s)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Text(s.label)
                        .font(.system(size: 9, weight: stage == s ? .bold : .semibold))
                        .tracking(1.0)
                        .foregroundStyle(stage == s ? .white : s2sInkSubtle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(stage == s ? tealAccent : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(stage == s ? Color.clear : s2sPanelEdge, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// =============================================================================
// MARK: - Card 05, Length Cliff
// =============================================================================

private enum S2SLength: Int, CaseIterable, Identifiable {
    case n5, n10, n20, n30, n45, n60
    var id: Int { rawValue }

    var n: Int {
        switch self {
        case .n5:  return 5
        case .n10: return 10
        case .n20: return 20
        case .n30: return 30
        case .n45: return 45
        case .n60: return 60
        }
    }

    var s2sBLEU: Double {
        // Seq2Seq drops past ~20 tokens; clean curve.
        switch self {
        case .n5:  return 36.5
        case .n10: return 35.2
        case .n20: return 32.0
        case .n30: return 27.4
        case .n45: return 21.8
        case .n60: return 16.5
        }
    }

    var phraseBLEU: Double {
        // Phrase based stays roughly flat.
        switch self {
        case .n5:  return 28.4
        case .n10: return 29.2
        case .n20: return 30.1
        case .n30: return 30.8
        case .n45: return 30.4
        case .n60: return 29.5
        }
    }

    // Capacity gauge 0...1.5: 1.0 = the thought vector is "full".
    var capacity: Double {
        switch self {
        case .n5:  return 0.18
        case .n10: return 0.35
        case .n20: return 0.72
        case .n30: return 0.98
        case .n45: return 1.22
        case .n60: return 1.45
        }
    }

    var verdict: String {
        switch self {
        case .n5:  return "Five tokens. Trivially fits in a 1000-dim vector. Seq2Seq dominates by 8 BLEU."
        case .n10: return "Ten tokens. Still well under capacity. Neural translation cleanly ahead."
        case .n20: return "Twenty tokens. The crossover begins. The thought vector is roughly 70% full."
        case .n30: return "Thirty tokens. Phrase-based catches and overtakes. Compression starts costing meaning."
        case .n45: return "Forty-five tokens. Seq2Seq drops below 22 BLEU. Information is being lost in the bottleneck."
        case .n60: return "Sixty tokens. The cliff. Seq2Seq is now half the quality of phrase-based MT. Attention will fix this two years later."
        }
    }
}

struct Seq2SeqLengthView: View {
    @ObservedObject var state: DailyLoopState
    @State private var stop: S2SLength = .n20
    @State private var visited: Set<Int> = [S2SLength.n20.rawValue]
    @State private var s2sAnim: Double = S2SLength.n20.s2sBLEU
    @State private var phraseAnim: Double = S2SLength.n20.phraseBLEU
    @State private var capAnim: Double = S2SLength.n20.capacity

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · LENGTH CLIFF")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("One vector. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(s2sInk)
                + Text("Finite capacity.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Drag the dial. The thought vector is fixed at 1000 dimensions; the sentence is not. Past twenty tokens, compression starts losing the thread.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                lengthDial
                    .padding(.bottom, 22)

                bleuPanel
                    .padding(.bottom, 16)

                capacityGauge
                    .padding(.bottom, 14)

                Text(stop.verdict)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(s2sInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            visited.insert(stop.rawValue)
            s2sAnim = stop.s2sBLEU
            phraseAnim = stop.phraseBLEU
            capAnim = stop.capacity
            updateGate()
        }
        .onChange(of: stop) { _, newStop in
            visited.insert(newStop.rawValue)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                s2sAnim = newStop.s2sBLEU
                phraseAnim = newStop.phraseBLEU
                capAnim = newStop.capacity
            }
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= 3 {
            state.customCardComplete.insert(4)
        }
    }

    private var lengthDial: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let stops = S2SLength.allCases
                let usableWidth = geo.size.width - 28
                let stopX: (S2SLength) -> CGFloat = { s in
                    14 + usableWidth * CGFloat(s.rawValue) / CGFloat(stops.count - 1)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(s2sPanelBg)
                        .frame(height: 6)
                        .overlay(Capsule().stroke(s2sPanelEdge, lineWidth: 1))

                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.4), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: stopX(stop), height: 6)

                    ForEach(stops) { s in
                        Circle()
                            .fill(stop.rawValue >= s.rawValue ? tealAccent : Color.white)
                            .overlay(Circle().stroke(stop == s ? tealAccent : s2sPanelEdge, lineWidth: stop == s ? 2 : 1))
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
                ForEach(S2SLength.allCases) { s in
                    VStack(spacing: 2) {
                        Text("\(s.n)")
                            .font(.system(size: 11, weight: stop == s ? .semibold : .regular, design: .serif))
                            .foregroundStyle(stop == s ? s2sInk : mutedText)
                        Text("tokens")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(stop == s ? tealAccent : mutedText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var bleuPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BLEU SCORE · WMT'14 EN→FR")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                let lead = s2sAnim - phraseAnim
                Text(lead >= 0 ? "+\(String(format: "%.1f", lead)) BLEU" : "\(String(format: "%.1f", lead)) BLEU")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(lead >= 0 ? tealAccent : amberAccent)
                    .contentTransition(.numericText(value: lead))
            }

            barRow(label: "Seq2Seq",
                   tag: String(format: "%.1f", s2sAnim),
                   value: s2sAnim,
                   color: tealAccent,
                   note: "neural")

            barRow(label: "Phrase based",
                   tag: String(format: "%.1f", phraseAnim),
                   value: phraseAnim,
                   color: amberAccent,
                   note: "Moses")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(s2sPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func barRow(label: String, tag: String, value: Double, color: Color, note: String) -> some View {
        let yMax: Double = 40
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(s2sInk)
                Spacer()
                Text(tag)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: value))
                Text(note)
                    .font(.system(size: 10, design: .serif))
                    .italic()
                    .foregroundStyle(s2sInkSubtle)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.55), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(value / yMax)))
                }
            }
            .frame(height: 8)
        }
    }

    private var capacityGauge: some View {
        let cap = capAnim
        let isOver = cap > 1.0
        let displayFrac = min(cap, 1.0)
        let overFrac = max(0, cap - 1.0)
        let gaugeColor: Color = isOver ? amberAccent : tealAccent

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("THOUGHT VECTOR CAPACITY")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(s2sInkSubtle)
                Spacer()
                Text(isOver ? "OVERFLOW" : "\(Int(cap * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(gaugeColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(s2sPanelBg)
                        .overlay(Capsule().stroke(s2sPanelEdge, lineWidth: 1))
                    Capsule()
                        .fill(LinearGradient(colors: [gaugeColor.opacity(0.55), gaugeColor], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(displayFrac))
                    if overFrac > 0 {
                        // Overflow stripes peeking past the cap line
                        Rectangle()
                            .fill(amberAccent.opacity(0.4))
                            .frame(width: min(geo.size.width * CGFloat(overFrac * 0.5), geo.size.width * 0.25),
                                   height: 6)
                            .offset(x: geo.size.width - 6, y: -2)
                            .blur(radius: 1.5)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 4)
    }
}

// =============================================================================
// MARK: - Card 06, Reverse the Source
// =============================================================================

struct Seq2SeqReverseView: View {
    @ObservedObject var state: DailyLoopState
    @State private var reversed: Bool = true
    @State private var visited: Set<Bool> = [true]
    @State private var pathAnim: Double = 1

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · REVERSE THE SOURCE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Five BLEU. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(s2sInk)
                + Text("From a one line change.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Same model, same data. Feed the source backwards and the gradient path between matching tokens collapses from O(n) hops to O(1).")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                modeToggle
                    .padding(.bottom, 18)

                graphPanel
                    .padding(.bottom, 18)

                bleuTile
                    .padding(.bottom, 14)

                Text(reversed
                     ? "Reversed. Source token \"I\" sits adjacent to target token \"J'aime\" in the unrolled graph. Gradients have a direct path between them. +4.7 BLEU, no architecture change."
                     : "Forward. Source token \"I\" must travel six LSTM steps before reaching target \"J'aime\". Each step shrinks the gradient. By the time it lands, the signal is faint.")
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(reversed ? tealAccent : amberAccent)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: reversed) { _, newVal in
            visited.insert(newVal)
            withAnimation(.easeInOut(duration: 0.5)) { pathAnim = 0 }
            withAnimation(.easeInOut(duration: 0.7).delay(0.1)) { pathAnim = 1 }
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= 2 {
            state.customCardComplete.insert(5)
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "Forward", subtitle: "BLEU 25.9", on: !reversed) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { reversed = false }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            modeButton(title: "Reversed", subtitle: "BLEU 30.6", on: reversed) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { reversed = true }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(s2sPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(s2sPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func modeButton(title: String, subtitle: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(on ? .white : s2sInk)
                Text(subtitle)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(on ? .white.opacity(0.85) : s2sInkSubtle)
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

    private var graphPanel: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let topY: CGFloat = 28
            let bottomY: CGFloat = h - 36

            // Source tokens, displayed in input order. Encoder feeds them in
            // the order shown (forward = left to right; reversed = right to
            // left). Visualise as positions; the chip text always reads left
            // to right so the user can compare.
            let sources = ["I", "love", "cats"]
            let targets = ["J'aime", "les", "chats"]

            let pad: CGFloat = 28
            let usable = w - pad * 2
            let n = sources.count

            // Forward: src[i] consumed at encoder step i; target[j] decoded
            // at encoder-step n + j. So src[0] → t[0] crosses n hops + 0.
            // Reversed: src[i] consumed at encoder step n - 1 - i; src[0] is
            // consumed at the last encoder step and sits adjacent to t[0].

            let srcXs: [CGFloat] = (0..<n).map { i in
                pad + usable * CGFloat(i) / CGFloat(n - 1)
            }
            let tgtXs: [CGFloat] = (0..<n).map { i in
                pad + usable * CGFloat(i) / CGFloat(n - 1)
            }

            // For the highlighted gradient path: connect src[0] ("I") and
            // tgt[0] ("J'aime"). Forward = long arc. Reversed = short.
            let srcIndex = 0
            let tgtIndex = 0
            let startPt = CGPoint(x: srcXs[srcIndex], y: topY + 18)
            let endPt   = CGPoint(x: tgtXs[tgtIndex], y: bottomY - 18)
            // Arc waypoint shows path length. Forward: bulge through every
            // intermediate timestep. Reversed: tight.
            let arcMidY: CGFloat = reversed ? (topY + bottomY) / 2 : (topY + bottomY) / 2
            let arcCtrlOffset: CGFloat = reversed ? 30 : 160

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(s2sPanelEdge, lineWidth: 1))

                // Section labels
                Text("SOURCE TOKENS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(s2sInkSubtle.opacity(0.7))
                    .position(x: 70, y: topY - 12)

                Text("TARGET TOKENS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(s2sInkSubtle.opacity(0.7))
                    .position(x: 70, y: bottomY + 18)

                // Gradient path arc
                Path { p in
                    p.move(to: startPt)
                    let mid = CGPoint(x: w / 2 + (reversed ? 0 : -arcCtrlOffset),
                                      y: arcMidY)
                    p.addQuadCurve(to: endPt, control: mid)
                }
                .trim(from: 0, to: max(0.05, min(1, pathAnim)))
                .stroke(
                    reversed ? tealAccent : amberAccent,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: reversed ? [] : [4, 3])
                )

                // Hop indicator label
                Text(reversed ? "1 hop" : "6 hops")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(reversed ? tealAccent : amberAccent))
                    .position(x: w / 2, y: arcMidY + (reversed ? 0 : 0))

                // Source chips
                ForEach(0..<n, id: \.self) { i in
                    sourceChip(text: sources[i], highlighted: i == srcIndex, position: i)
                        .position(x: srcXs[i], y: topY + 4)
                }

                // Order arrow under sources
                HStack(spacing: 4) {
                    if reversed {
                        Text("fed in:")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(amberAccent)
                        Image(systemName: "arrow.left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(amberAccent)
                    } else {
                        Text("fed in:")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(amberAccent)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(amberAccent)
                    }
                }
                .position(x: w - 56, y: topY + 4)

                // Target chips
                ForEach(0..<n, id: \.self) { i in
                    targetChip(text: targets[i], highlighted: i == tgtIndex)
                        .position(x: tgtXs[i], y: bottomY)
                }
            }
        }
        .frame(height: 220)
    }

    @ViewBuilder
    private func sourceChip(text: String, highlighted: Bool, position: Int) -> some View {
        Text(text)
            .font(.system(size: 11, weight: highlighted ? .semibold : .regular, design: .serif))
            .foregroundStyle(highlighted ? .white : s2sInk)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(highlighted ? (reversed ? tealAccent : amberAccent) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(highlighted ? Color.clear : s2sPanelEdge, lineWidth: 1)
                    )
            )
    }

    @ViewBuilder
    private func targetChip(text: String, highlighted: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: highlighted ? .semibold : .regular, design: .serif))
            .foregroundStyle(highlighted ? .white : s2sInk)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(highlighted ? tealAccent : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(highlighted ? Color.clear : s2sPanelEdge, lineWidth: 1)
                    )
            )
    }

    private var bleuTile: some View {
        HStack(spacing: 10) {
            statTile(label: "FORWARD",  bleu: 25.9, accent: amberAccent, on: !reversed)
            statTile(label: "REVERSED", bleu: 30.6, accent: tealAccent,  on: reversed)
            VStack(alignment: .leading, spacing: 4) {
                Text("DELTA")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(s2sInkSubtle.opacity(0.8))
                Text("+4.7")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(tealAccent)
                Text("BLEU")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(s2sInkSubtle.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(tealAccent.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(tealAccent.opacity(0.4), lineWidth: 0.8))
            )
        }
    }

    @ViewBuilder
    private func statTile(label: String, bleu: Double, accent: Color, on: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(on ? accent : s2sInkSubtle.opacity(0.8))
            Text(String(format: "%.1f", bleu))
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
            Text("BLEU")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(s2sInkSubtle.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(on ? s2sPanelBg : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(s2sPanelEdge, lineWidth: 1))
        )
    }
}

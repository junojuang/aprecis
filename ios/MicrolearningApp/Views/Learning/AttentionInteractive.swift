import SwiftUI

// MARK: - Attention bespoke interactives
//
// Hand-built interactive diagrams for the "Attention Is All You Need" lesson.
// Same editorial language as the perceptron set: every diagram is specific to
// the idea it teaches, drawn with SwiftUI shapes, no generic chart component
// and no web view. The lesson runs on the consistent picture of a sentence as
// a table of guests: each word asks a question, every other word answers.

// Two extra accents the attention set leans on, beyond the brand teal/amber.
private let attnBlue   = Color(hex: "2d7abf")   // Query
private let attnViolet = Color(hex: "7b4ba4")   // Value

// MARK: Attention web glyph (cover hero)
//
// A minimal living attention pattern for the editorial cover: a row of token
// nodes, one focus node reaching to every other with weighted arcs, a pulse
// breathing out of the focus. Light strokes, reads on the dark cover.

struct AttentionWebGlyph: View {
    @State private var pulse = false

    private let ink = Color(hex: "f4f1ea")
    // Attention weight from the focus node to each node (focus to itself = 1).
    private let weights: [CGFloat] = [0.34, 0.86, 1.0, 0.28, 0.58, 0.72]
    private let focus = 2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = weights.count
            let nodes: [CGPoint] = (0..<n).map { i in
                let t = CGFloat(i) / CGFloat(n - 1)
                return CGPoint(x: w * (0.12 + 0.76 * t),
                               y: h * (0.5 + 0.22 * sin(t * .pi * 2)))
            }
            let f = nodes[focus]

            ZStack {
                // weighted arcs from the focus token to every other token
                ForEach(0..<n, id: \.self) { i in
                    if i != focus {
                        Path { p in
                            let mid = CGPoint(x: (f.x + nodes[i].x) / 2,
                                              y: min(f.y, nodes[i].y) - 40)
                            p.move(to: f)
                            p.addQuadCurve(to: nodes[i], control: mid)
                        }
                        .stroke(tealMid.opacity(0.22 + 0.5 * weights[i]),
                                lineWidth: 1 + 2.6 * weights[i])
                    }
                }
                // breathing ring on the focus
                Circle()
                    .stroke(tealMid.opacity(0.6), lineWidth: 2)
                    .frame(width: pulse ? 96 : 34, height: pulse ? 96 : 34)
                    .opacity(pulse ? 0 : 0.8)
                    .position(f)
                // token nodes
                ForEach(0..<n, id: \.self) { i in
                    Circle()
                        .fill(i == focus ? tealAccent : ink.opacity(0.5))
                        .frame(width: i == focus ? 32 : 13,
                               height: i == focus ? 32 : 13)
                        .overlay(Circle().stroke(ink.opacity(0.85),
                                                 lineWidth: i == focus ? 2 : 0))
                        .position(nodes[i])
                }
                // travelling pulse along the strongest arc
                Circle()
                    .fill(amberAccent)
                    .frame(width: 8, height: 8)
                    .position(x: pulse ? nodes[1].x : f.x,
                              y: pulse ? nodes[1].y : f.y)
                    .opacity(pulse ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

// MARK: Attention arc art (big-idea illustration)
//
// One sentence laid out as word chips, with arcs bowing over it: the word
// "it" reaches back to "cat". Anchors the whole lesson's picture before any
// machinery appears.

struct AttentionArcArt: View {
    private let words = ["The", "cat", "sat", "as", "it", "dozed"]
    // (from, to, strong) — the live link is bold teal, supporting links faint.
    private let arcs: [(Int, Int, Bool)] = [(4, 1, true), (2, 1, false), (5, 1, false)]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let n = words.count
            let slot = w / CGFloat(n)
            let baseY = h * 0.82
            let cx: (Int) -> CGFloat = { slot * (CGFloat($0) + 0.5) }

            ZStack {
                ForEach(arcs.indices, id: \.self) { k in
                    let a = arcs[k]
                    Path { p in
                        let x0 = cx(a.0), x1 = cx(a.1)
                        let top = baseY - 22 - h * (a.2 ? 0.5 : 0.34)
                        p.move(to: CGPoint(x: x0, y: baseY - 20))
                        p.addQuadCurve(to: CGPoint(x: x1, y: baseY - 20),
                                       control: CGPoint(x: (x0 + x1) / 2, y: top))
                    }
                    .stroke(a.2 ? tealAccent : tealMid.opacity(0.45),
                            style: StrokeStyle(lineWidth: a.2 ? 2.6 : 1.4,
                                               lineCap: .round,
                                               dash: a.2 ? [] : [3, 3]))
                }
                ForEach(0..<n, id: \.self) { i in
                    let linked = arcs.contains(where: { $0.0 == i || $0.1 == i })
                    Text(words[i])
                        .scaledFont(size: 15,
                                      weight: linked ? .semibold : .regular,
                                      design: .serif)
                        .foregroundStyle(linked ? inkColor : inkColor.opacity(0.45))
                        .position(x: cx(i), y: baseY)
                }
            }
        }
    }
}

// MARK: Telephone chain art (the old way)
//
// Words in a line, a single memory token passed hand to hand and fading as it
// travels. The editorial picture of recurrence: information degrades down the
// chain, and nothing happens in parallel.

struct TelephoneChainArt: View {
    private let words = ["The", "cat", "sat", "as", "it", "dozed"]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let n = words.count
            let slot = w / CGFloat(n)
            let y = h * 0.52
            let cx: (Int) -> CGFloat = { slot * (CGFloat($0) + 0.5) }

            ZStack {
                // chain arrows between consecutive words
                ForEach(0..<(n - 1), id: \.self) { i in
                    Path { p in
                        p.move(to: CGPoint(x: cx(i) + 17, y: y))
                        p.addLine(to: CGPoint(x: cx(i + 1) - 17, y: y))
                    }
                    .stroke(mutedText.opacity(0.5), lineWidth: 1.3)
                }
                // the single memory token, fading as it is passed along
                ForEach(0..<n, id: \.self) { i in
                    Circle()
                        .fill(amberAccent.opacity(1.0 - 0.62 * Double(i) / Double(n - 1)))
                        .frame(width: 11, height: 11)
                        .position(x: cx(i), y: y - 27)
                }
                // word nodes
                ForEach(0..<n, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(borderColor, lineWidth: 1))
                        .frame(width: 30, height: 30)
                        .position(x: cx(i), y: y)
                    Text(words[i])
                        .scaledFont(size: 10, weight: .medium, design: .serif)
                        .foregroundStyle(inkColor.opacity(0.7))
                        .position(x: cx(i), y: y + 27)
                }
                Text("the memory blurs as it travels")
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(0.8)
                    .foregroundStyle(mutedText)
                    .position(x: w / 2, y: h * 0.06)
            }
        }
    }
}

// MARK: - SelfAttentionPlayground
//
// The reader taps any word in a short sentence; arcs fan out from it to every
// other word, thickness set by the attention weight, and the target chips
// tint by how hard the word looks there. The card unlocks once the reader has
// probed three different words and felt that attention is a per-word pattern.

struct SelfAttentionPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let tokens = ["The", "cat", "chased", "the", "ball"]
    // Row i = how much token i attends to each token. Rough, hand-tuned so the
    // verb reaches its subject and object, the adjective reaches its noun.
    private let W: [[Double]] = [
        [0.55, 0.22, 0.10, 0.07, 0.06],   // The
        [0.10, 0.46, 0.34, 0.05, 0.05],   // cat
        [0.05, 0.42, 0.20, 0.05, 0.28],   // chased
        [0.10, 0.08, 0.10, 0.42, 0.30],   // the
        [0.05, 0.10, 0.34, 0.16, 0.35],   // ball
    ]

    @State private var selected: Int? = nil
    @State private var tapped: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 14)

            Text("TAP A WORD")
                .scaledFont(size: 11, weight: .bold)
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Tap any word to see what it reads. The lines show where its attention goes; a thicker line means it looks harder there.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            arcPlot
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var arcPlot: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let n = tokens.count
            let slot = w / CGFloat(n)
            let baseY = h - 28
            let cx: (Int) -> CGFloat = { slot * (CGFloat($0) + 0.5) }

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))

                if let s = selected {
                    ForEach(0..<n, id: \.self) { j in
                        if j != s {
                            let weight = W[s][j]
                            Path { p in
                                let x0 = cx(s), x1 = cx(j)
                                let ctrlY = baseY - 44 - CGFloat(abs(j - s)) * 18
                                p.move(to: CGPoint(x: x0, y: baseY - 17))
                                p.addQuadCurve(to: CGPoint(x: x1, y: baseY - 17),
                                               control: CGPoint(x: (x0 + x1) / 2, y: ctrlY))
                            }
                            .stroke(tealAccent.opacity(0.25 + 0.6 * weight),
                                    style: StrokeStyle(lineWidth: 1 + 5 * weight,
                                                       lineCap: .round))
                        }
                    }
                }

                ForEach(0..<n, id: \.self) { i in
                    chip(i)
                        .position(x: cx(i), y: baseY)
                        .onTapGesture { select(i) }
                }
            }
        }
        .frame(height: 178)
    }

    private func chip(_ i: Int) -> some View {
        let isSel = selected == i
        let active = selected != nil
        let weight = selected.map { W[$0][i] } ?? 0
        return Text(tokens[i])
            .scaledFont(size: 13, weight: .semibold, design: .serif)
            .foregroundStyle(isSel ? .white : inkColor.opacity(0.85))
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSel ? tealAccent : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(tealAccent.opacity(active && !isSel ? weight * 0.9 : 0)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(borderColor, lineWidth: isSel ? 0 : 1))
            .motionAware(.snappy(duration: 0.3), value: selected)
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(selected == nil ? amberAccent : tealAccent)
                .frame(width: 9, height: 9)
            Text(captionText)
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var captionText: String {
        guard let s = selected else { return "Tap any word to see where it looks." }
        var best = (s == 0 ? 1 : 0)
        for j in tokens.indices where j != s {
            if W[s][j] > W[s][best] { best = j }
        }
        return "\u{201C}\(tokens[s])\u{201D} looks hardest at \u{201C}\(tokens[best])\u{201D}."
    }

    private func select(_ i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) { selected = i }
        tapped.insert(i)
        if tapped.count >= 3 { progress.markExplored(cardId) }
    }
}

// MARK: - QKVTriadArt (query/key/value illustration)
//
// One word chip on the left, three branches on the right: a Query, a Key and
// a Value, each its own colour and a one-word job. Shows that to attend, a
// word first splits itself into three smaller vectors.

struct QKVTriadArt: View {
    private struct Branch {
        let label: String
        let role: String
        let tint: Color
        let bars: [CGFloat]
    }
    private let branches: [Branch] = [
        Branch(label: "Q", role: "asks",   tint: attnBlue,   bars: [0.8, 0.3, 0.6, 0.4]),
        Branch(label: "K", role: "offers", tint: amberAccent, bars: [0.4, 0.85, 0.3, 0.7]),
        Branch(label: "V", role: "gives",  tint: attnViolet, bars: [0.6, 0.45, 0.9, 0.35]),
    ]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let word = CGPoint(x: w * 0.16, y: h * 0.5)
            let rowH = h / 3

            ZStack {
                // branch lines from the word to each projection
                ForEach(branches.indices, id: \.self) { i in
                    let endY = rowH * (CGFloat(i) + 0.5)
                    Path { p in
                        p.move(to: CGPoint(x: word.x + 26, y: word.y))
                        p.addCurve(to: CGPoint(x: w * 0.52, y: endY),
                                   control1: CGPoint(x: w * 0.36, y: word.y),
                                   control2: CGPoint(x: w * 0.36, y: endY))
                    }
                    .stroke(branches[i].tint.opacity(0.55), lineWidth: 1.6)
                }

                // the source word
                Text("cat")
                    .scaledFont(size: 15, weight: .semibold, design: .serif)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(inkColor))
                    .position(word)

                // the three projections
                ForEach(branches.indices, id: \.self) { i in
                    projection(branches[i])
                        .position(x: w * 0.74, y: rowH * (CGFloat(i) + 0.5))
                }
            }
        }
    }

    private func projection(_ b: Branch) -> some View {
        HStack(spacing: 9) {
            ZStack {
                Circle().fill(b.tint).frame(width: 26, height: 26)
                Text(b.label)
                    .scaledFont(size: 12, weight: .bold, design: .monospaced)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 2) {
                    ForEach(b.bars.indices, id: \.self) { k in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(b.tint.opacity(0.35 + 0.55 * Double(b.bars[k])))
                            .frame(width: 12, height: 4 + 12 * b.bars[k])
                    }
                }
                .frame(height: 18, alignment: .bottom)
                Text(b.role)
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(1.0)
                    .foregroundStyle(mutedText)
            }
        }
    }
}

// MARK: - AttentionMatchPlayground
//
// The reader drags a Query along a track of four Keys. Closeness to a Key
// becomes a match score; the scores are normalised into weights that always
// sum to one, and the output is the matching blend of the Keys' Values shown
// as a colour. The card unlocks the first time the winning Key changes hands,
// the moment the reader has felt attention shift.

struct AttentionMatchPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private struct Key {
        let label: String
        let pos: Double          // fixed position on the meaning track, 0...1
        let r, g, b: Double      // its Value, carried as a colour
        var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255) }
    }
    private let keys: [Key] = [
        Key(label: "K\u{2081}", pos: 0.12, r: 45,  g: 122, b: 191),
        Key(label: "K\u{2082}", pos: 0.40, r: 26,  g: 138, b: 138),
        Key(label: "K\u{2083}", pos: 0.66, r: 232, g: 160, b: 32),
        Key(label: "K\u{2084}", pos: 0.90, r: 123, g: 75,  b: 164),
    ]

    @State private var query: Double = 0.5
    @State private var lastTop: Int? = nil
    @State private var flipped = false

    // Match score: closeness of the Query to a Key, as a soft bell curve.
    private var scores: [Double] {
        keys.map { k in
            let d = (query - k.pos) * 3.4
            return exp(-d * d)
        }
    }
    // Normalised into weights that sum to one — the role softmax plays.
    private var weights: [Double] {
        let s = scores
        let sum = s.reduce(0, +)
        return sum > 0 ? s.map { $0 / sum } : s
    }
    private var topKey: Int {
        weights.indices.max(by: { weights[$0] < weights[$1] }) ?? 0
    }
    // The output: the Keys' Values blended by their weights.
    private var blended: Color {
        var r = 0.0, g = 0.0, b = 0.0
        for (k, wt) in zip(keys, weights) { r += k.r * wt; g += k.g * wt; b += k.b * wt }
        return Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("DRAG THE QUERY")
                .scaledFont(size: 11, weight: .bold)
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Drag Q along the line. The closer it lands to a Key, the louder that Key answers. The weights always add to 100%, and the output is their blend.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            queryTrack
            weightBars
            outputRow
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { lastTop = topKey }
    }

    private var queryTrack: some View {
        GeometryReader { g in
            let w = g.size.width
            ZStack {
                Capsule()
                    .fill(inkColor.opacity(0.08))
                    .frame(height: 6)
                ForEach(keys.indices, id: \.self) { i in
                    Circle()
                        .fill(keys[i].color)
                        .frame(width: 13, height: 13)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(x: CGFloat(keys[i].pos) * w, y: 27)
                }
                Rectangle()
                    .fill(inkColor.opacity(0.16))
                    .frame(width: 1, height: 40)
                    .position(x: CGFloat(query) * w, y: 27)
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(tealAccent, lineWidth: 2.5))
                    .overlay(Text("Q")
                        .scaledFont(size: 12, weight: .bold, design: .monospaced)
                        .foregroundStyle(tealAccent))
                    .shadow(color: inkColor.opacity(0.15), radius: 3, y: 1)
                    .position(x: CGFloat(query) * w, y: 27)
            }
            .frame(height: 54)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        query = min(max(0, Double(v.location.x / w)), 1)
                        checkFlip()
                    }
            )
        }
        .frame(height: 54)
    }

    private var weightBars: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(keys.indices, id: \.self) { i in
                VStack(spacing: 5) {
                    Text("\(Int(round(weights[i] * 100)))%")
                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                        .foregroundStyle(i == topKey ? keys[i].color : mutedText)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(keys[i].color.opacity(i == topKey ? 1 : 0.5))
                        .frame(height: max(4, CGFloat(weights[i]) * 96))
                    Text(keys[i].label)
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundStyle(mutedText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 132, alignment: .bottom)
        .motionAware(.snappy(duration: 0.25), value: query)
    }

    private var outputRow: some View {
        HStack(spacing: 12) {
            Text("BLENDED VALUE")
                .scaledFont(size: 10, weight: .bold)
                .tracking(1.6)
                .foregroundStyle(mutedText)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(inkColor.opacity(0.06))
                .frame(height: 30)
                .overlay(
                    HStack(spacing: 0) {
                        ForEach(keys.indices, id: \.self) { i in
                            Rectangle()
                                .fill(keys[i].color)
                                .frame(width: max(0, CGFloat(weights[i]) * 130))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                )
            Circle()
                .fill(blended)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(borderColor, lineWidth: 1))
        }
        .motionAware(.snappy(duration: 0.25), value: query)
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(flipped ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(flipped
                 ? "You moved the winner. That shift is attention at work."
                 : "\(keys[topKey].label) is winning. Drag Q until another Key takes over.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func checkFlip() {
        let t = topKey
        if let last = lastTop, last != t {
            if !flipped {
                flipped = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                progress.markExplored(cardId)
            }
        }
        lastTop = t
    }
}

// MARK: - MultiHeadStrip (multi-head illustration)
//
// Three small attention panels side by side, same five words in each, but the
// pattern of focus differs: one head tracks grammar, one tracks meaning, one
// tracks word order. Shows at a glance that heads specialise.

struct MultiHeadStrip: View {
    private struct Panel {
        let title: String
        let tint: Color
        let pattern: [CGFloat]   // attention over the five words
    }
    private static let words = ["The", "cat", "chased", "the", "ball"]
    private let panels: [Panel] = [
        Panel(title: "GRAMMAR",  tint: tealAccent,
              pattern: [0.06, 0.58, 0.18, 0.06, 0.12]),
        Panel(title: "MEANING",  tint: attnViolet,
              pattern: [0.05, 0.30, 0.10, 0.08, 0.47]),
        Panel(title: "ORDER",    tint: attnBlue,
              pattern: [0.10, 0.46, 0.30, 0.08, 0.06]),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            ForEach(panels.indices, id: \.self) { i in
                panelView(panels[i])
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func panelView(_ p: Panel) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(borderColor, lineWidth: 0.8))
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(p.pattern.indices, id: \.self) { k in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p.tint.opacity(0.35 + 0.6 * Double(p.pattern[k])))
                            .frame(width: 8, height: 8 + 44 * p.pattern[k])
                    }
                }
                .frame(height: 58, alignment: .bottom)
                .padding(.bottom, 8)
            }
            .frame(height: 74)
            Text(p.title)
                .scaledFont(size: 9, weight: .bold)
                .tracking(1.2)
                .foregroundStyle(p.tint)
        }
    }
}

// MARK: - AttentionHeadsPlayground
//
// The reader taps through four attention heads; each one redraws the same
// sentence with a different focus, and a one-line role explains what it has
// learned. The card unlocks once three heads have been inspected, so the
// reader has felt that the heads genuinely differ.

struct AttentionHeadsPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let tokens = ["The", "cat", "chased", "the", "ball"]
    private struct Head {
        let tag: String
        let role: String
        let tint: Color
        let pattern: [Double]
    }
    private let heads: [Head] = [
        Head(tag: "H1", role: "grammar: the verb back to its subject",
             tint: tealAccent,  pattern: [0.06, 0.58, 0.18, 0.06, 0.12]),
        Head(tag: "H2", role: "meaning: words about the same thing",
             tint: attnViolet,  pattern: [0.05, 0.30, 0.10, 0.08, 0.47]),
        Head(tag: "H3", role: "order: the word right before this one",
             tint: attnBlue,    pattern: [0.10, 0.46, 0.30, 0.08, 0.06]),
        Head(tag: "H4", role: "object: the verb to what was acted on",
             tint: amberAccent, pattern: [0.04, 0.08, 0.30, 0.12, 0.46]),
    ]

    @State private var selected = 0
    @State private var viewed: Set<Int> = [0]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("TAP THE HEADS")
                .scaledFont(size: 11, weight: .bold)
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Eight heads run at once; here are four. Each reads the same sentence but chases a different pattern. Tap through them and watch the focus jump.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            headPicker
            barPlot
            roleCaption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headPicker: some View {
        HStack(spacing: 8) {
            ForEach(heads.indices, id: \.self) { i in
                let isSel = selected == i
                Text(heads[i].tag)
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundStyle(isSel ? .white : heads[i].tint)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSel ? heads[i].tint : heads[i].tint.opacity(0.12)))
                    .onTapGesture { pick(i) }
            }
        }
    }

    private var barPlot: some View {
        let head = heads[selected]
        return ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(tokens.indices, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text("\(Int(round(head.pattern[i] * 100)))")
                            .scaledFont(size: 10, weight: .bold, design: .monospaced)
                            .foregroundStyle(mutedText)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(head.tint.opacity(0.4 + 0.6 * head.pattern[i]))
                            .frame(height: max(5, CGFloat(head.pattern[i]) * 104))
                        Text(tokens[i])
                            .scaledFont(size: 11, weight: .medium, design: .serif)
                            .foregroundStyle(inkColor.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
        .frame(height: 184)
        .motionAware(.snappy(duration: 0.3), value: selected)
    }

    private var roleCaption: some View {
        HStack(spacing: 8) {
            Circle().fill(heads[selected].tint).frame(width: 9, height: 9)
            Text("\(heads[selected].tag) reads \(heads[selected].role).")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pick(_ i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) { selected = i }
        viewed.insert(i)
        if viewed.count >= 3 { progress.markExplored(cardId) }
    }
}

// MARK: - PositionWavesArt (positional-encoding illustration)
//
// Four sine waves of doubling frequency, drawn in as the card appears. Each
// position reads one height off every wave; together those heights are a
// fingerprint no two slots share. The picture behind positional encoding.

private struct SineWave: Shape {
    var cycles: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 96
        for s in 0...steps {
            let t = Double(s) / Double(steps)
            let x = rect.minX + rect.width * CGFloat(t)
            let y = rect.midY - CGFloat(sin(t * cycles * 2 * .pi)) * rect.height * 0.42
            let pt = CGPoint(x: x, y: y)
            if s == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

struct PositionWavesArt: View {
    @State private var grow = false

    private let waves: [(cycles: Double, color: Color, width: CGFloat)] = [
        (1, tealAccent,  2.4),
        (2, amberAccent, 1.9),
        (3, attnViolet,  1.6),
        (5, attnBlue,    1.4),
    ]

    var body: some View {
        GeometryReader { g in
            let waveH = g.size.height * 0.72
            VStack(spacing: 10) {
                ZStack {
                    // a faint baseline
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 1)
                    ForEach(waves.indices, id: \.self) { i in
                        SineWave(cycles: waves[i].cycles)
                            .trim(from: 0, to: grow ? 1 : 0)
                            .stroke(waves[i].color.opacity(0.9),
                                    style: StrokeStyle(lineWidth: waves[i].width,
                                                       lineCap: .round))
                    }
                }
                .frame(height: waveH)

                HStack(spacing: 14) {
                    ForEach(waves.indices, id: \.self) { i in
                        HStack(spacing: 5) {
                            Capsule()
                                .fill(waves[i].color)
                                .frame(width: 14, height: 3)
                            Text("dim \(i)")
                                .scaledFont(size: 9, weight: .semibold,
                                              design: .monospaced)
                                .foregroundStyle(mutedText)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) { grow = true }
        }
    }
}

// MARK: - TransformerStackArt (architecture illustration)
//
// The whole machine in two towers: an encoder that reads and a decoder that
// writes, joined by a cross-attention bridge. Each block is named so the
// reader can match it to the parts the lesson already taught.

struct TransformerStackArt: View {
    private struct Block { let label: String; let tint: Color }

    private let encoder: [Block] = [
        Block(label: "Self-Attention", tint: tealAccent),
        Block(label: "Add & Norm",     tint: mutedText),
        Block(label: "Feed-Forward",   tint: attnViolet),
        Block(label: "Add & Norm",     tint: mutedText),
    ]
    private let decoder: [Block] = [
        Block(label: "Masked Self-Attn", tint: amberAccent),
        Block(label: "Cross-Attention",  tint: tealAccent),
        Block(label: "Feed-Forward",     tint: attnViolet),
        Block(label: "Linear + Softmax", tint: attnBlue),
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            tower("ENCODER", encoder, note: "reads · \u{00D7}6")
            bridge
            tower("DECODER", decoder, note: "writes · \u{00D7}6")
        }
        .frame(maxWidth: .infinity)
    }

    private func tower(_ title: String, _ blocks: [Block], note: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .scaledFont(size: 9, weight: .bold)
                .tracking(1.4)
                .foregroundStyle(mutedText)
            ForEach(blocks.indices, id: \.self) { i in
                Text(blocks[i].label)
                    .scaledFont(size: 9.5, weight: .semibold)
                    .foregroundStyle(blocks[i].tint == mutedText ? mutedText : inkColor)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(blocks[i].tint.opacity(0.55), lineWidth: 1.4)))
            }
            Text(note)
                .scaledFont(size: 8.5, weight: .bold, design: .monospaced)
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    private var bridge: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrow.left")
                .scaledFont(size: 11, weight: .black)
                .foregroundStyle(tealAccent)
            Text("cross")
                .scaledFont(size: 7, weight: .bold)
                .tracking(0.5)
                .foregroundStyle(tealAccent)
                .rotationEffect(.degrees(-90))
                .fixedSize()
                .frame(width: 14, height: 30)
        }
        .frame(width: 26)
    }
}

// MARK: - TransformerLineage (why-it-won timeline)
//
// A horizontal milestone strip: 2017 to today. Years above, dots threaded on
// a line, names below. The first dot is accented to mark this paper as the
// origin of the line that leads straight to every chatbot.

struct TransformerLineage: View {
    private struct Milestone {
        let year: String
        let label: String
        let accent: Bool
    }
    private let milestones: [Milestone] = [
        Milestone(year: "2017", label: "Transformer", accent: true),
        Milestone(year: "2018", label: "BERT · GPT",  accent: false),
        Milestone(year: "2020", label: "GPT-3",       accent: false),
        Milestone(year: "today", label: "Every chatbot", accent: false),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(milestones.indices, id: \.self) { i in
                    Text(milestones[i].year)
                        .scaledFont(size: 11, weight: .semibold, design: .serif)
                        .foregroundStyle(inkColor.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }
            ZStack {
                Rectangle()
                    .fill(inkColor.opacity(0.35))
                    .frame(height: 1)
                HStack(spacing: 0) {
                    ForEach(milestones.indices, id: \.self) { i in
                        Circle()
                            .fill(milestones[i].accent ? tealAccent : inkColor.opacity(0.75))
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(paperBg, lineWidth: 2.5))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 16)
            .padding(.vertical, 6)
            HStack(spacing: 0) {
                ForEach(milestones.indices, id: \.self) { i in
                    Text(milestones[i].label)
                        .scaledFont(size: 10, weight: .medium)
                        .foregroundStyle(mutedText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

import SwiftUI

// MARK: - Word2Vec bespoke interactives
//
// Hand-built interactive diagrams for "Efficient Estimation of Word
// Representations in Vector Space" (Mikolov et al., 2013). Same editorial
// language as the perceptron, attention and GPT-3 sets: every diagram is
// specific to the idea it teaches, drawn with SwiftUI shapes, no web view.
// The lesson runs on one picture: meaning turned into a map, where distance
// is similarity and a straight-line direction is a relationship.

private let w2vViolet = Color(hex: "7b4ba4")
private let w2vBlue   = Color(hex: "2d7abf")

// A point in the meaning map, in 0...1 coordinates (y up). An inset keeps the
// outermost word chips clear of the plot frame, so a wide label never spills
// past the edge.
private func mapPoint(_ x: Double, _ y: Double, _ s: CGFloat) -> CGPoint {
    let inset = 0.16
    let span = 1 - 2 * inset
    let fx = inset + span * x
    let fy = inset + span * (1 - y)
    return CGPoint(x: CGFloat(fx) * s, y: CGFloat(fy) * s)
}

// MARK: WordVectorGlyph (cover hero)
//
// A constellation of word-points with two parallel relationship arrows: the
// arrow from one word to another repeats elsewhere in the space. A pulse runs
// one arrow. Light strokes, reads on the dark cover.

struct WordVectorGlyph: View {
    @State private var pulse = false

    private let ink = Color(hex: "f4f1ea")
    // Two parallel arrows: a -> b and c -> d carry the same vector.
    private let a = (0.18, 0.36), b = (0.52, 0.70)
    private let c = (0.46, 0.22), d = (0.80, 0.56)
    private let scatter = [(0.30, 0.84), (0.70, 0.16), (0.88, 0.82)]

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let ox = (geo.size.width - s) / 2
            let pt: ((Double, Double)) -> CGPoint = { p in
                CGPoint(x: ox + CGFloat(p.0) * s, y: CGFloat(p.1) * s)
            }
            ZStack {
                arrow(from: pt(a), to: pt(b), tint: tealMid)
                arrow(from: pt(c), to: pt(d), tint: tealMid)
                ForEach(scatter.indices, id: \.self) { i in
                    Circle().fill(ink.opacity(0.4))
                        .frame(width: 9, height: 9)
                        .position(pt(scatter[i]))
                }
                ForEach(0..<4, id: \.self) { i in
                    let p = [a, b, c, d][i]
                    Circle()
                        .fill(i == 1 || i == 3 ? tealAccent : ink.opacity(0.65))
                        .frame(width: 15, height: 15)
                        .overlay(Circle().stroke(ink.opacity(0.85), lineWidth: 1.5))
                        .position(pt(p))
                }
                Circle()
                    .fill(amberAccent)
                    .frame(width: 9, height: 9)
                    .position(x: pulse ? pt(b).x : pt(a).x,
                              y: pulse ? pt(b).y : pt(a).y)
                    .opacity(pulse ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }

    private func arrow(from: CGPoint, to: CGPoint, tint: Color) -> some View {
        Path { p in p.move(to: from); p.addLine(to: to) }
            .stroke(tint.opacity(0.6), lineWidth: 2)
    }
}

// MARK: WordSpaceArt (big-idea illustration)
//
// A small meaning map: nine words in three clusters, coloured by cluster.
// The picture of the whole paper: every word gets a place, and alike words
// land together.

struct WordSpaceArt: View {
    private struct W { let text: String; let x: Double; let y: Double; let cluster: Int }
    private let words: [W] = [
        W(text: "king",   x: 0.74, y: 0.78, cluster: 0),
        W(text: "queen",  x: 0.86, y: 0.66, cluster: 0),
        W(text: "prince", x: 0.66, y: 0.62, cluster: 0),
        W(text: "cat",    x: 0.22, y: 0.30, cluster: 1),
        W(text: "dog",    x: 0.34, y: 0.40, cluster: 1),
        W(text: "horse",  x: 0.16, y: 0.46, cluster: 1),
        W(text: "tea",    x: 0.26, y: 0.82, cluster: 2),
        W(text: "coffee", x: 0.16, y: 0.70, cluster: 2),
        W(text: "water",  x: 0.36, y: 0.70, cluster: 2),
    ]
    private let tints = [tealAccent, w2vViolet, amberAccent]

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let ox = (g.size.width - s) / 2
            ZStack {
                ForEach(words.indices, id: \.self) { i in
                    let p = mapPoint(words[i].x, words[i].y, s)
                    HStack(spacing: 5) {
                        Circle().fill(tints[words[i].cluster])
                            .frame(width: 8, height: 8)
                        Text(words[i].text)
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .foregroundStyle(inkColor.opacity(0.82))
                    }
                    .position(x: ox + p.x, y: p.y)
                }
            }
        }
    }
}

// MARK: OneHotArt (the old way)
//
// Before word2vec: each word was a one-hot row, a single lit cell and nothing
// else. Every word the exact same distance from every other, no notion of
// similar.

struct OneHotArt: View {
    private let words = ["cat", "dog", "queen", "Tuesday"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(words.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    Text(words[i])
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.8))
                        .frame(width: 64, alignment: .leading)
                    HStack(spacing: 4) {
                        ForEach(words.indices, id: \.self) { j in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i == j ? tealAccent : inkColor.opacity(0.06))
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
            Text("every word equally far from every other")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(mutedText)
                .padding(.top, 2)
        }
    }
}

// MARK: ContextBlankArt (distributional-hypothesis illustration)
//
// One sentence with a blank, and three words that all fit it. Words that
// share contexts share meaning: the picture behind the whole training idea.

struct ContextBlankArt: View {
    private let fits = ["tea", "coffee", "water"]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 5) {
                Text("Pour the")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(inkColor)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(tealAccent, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    .frame(width: 44, height: 24)
                Text("into a cup")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(inkColor)
            }
            HStack(spacing: 10) {
                ForEach(fits.indices, id: \.self) { i in
                    Text(fits[i])
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(tealAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(tealLight)
                                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(tealAccent.opacity(0.3), lineWidth: 1)))
                }
            }
            Text("same blank, so word2vec places them close")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(mutedText)
        }
    }
}

// MARK: AnalogyParallelArt (relationships-are-directions illustration)
//
// Four words on a meaning plane, with two arrows that are exactly parallel:
// man to king is the same step as woman to queen. The paper's signature
// insight, drawn.

struct AnalogyParallelArt: View {
    private let man   = (0.26, 0.30)
    private let king  = (0.78, 0.30)
    private let woman = (0.26, 0.70)
    private let queen = (0.78, 0.70)

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let ox = (g.size.width - s) / 2
            let pt: ((Double, Double)) -> CGPoint = { p in
                CGPoint(x: ox + mapPoint(p.0, p.1, s).x, y: mapPoint(p.0, p.1, s).y)
            }
            ZStack {
                arrow(pt(man), pt(king))
                arrow(pt(woman), pt(queen))
                wordDot("man", pt(man), tint: inkColor.opacity(0.7))
                wordDot("king", pt(king), tint: tealAccent)
                wordDot("woman", pt(woman), tint: inkColor.opacity(0.7))
                wordDot("queen", pt(queen), tint: tealAccent)
                Text("+ royalty")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(amberAccent)
                    .position(x: ox + s * 0.52, y: s * 0.22)
            }
        }
    }

    private func arrow(_ from: CGPoint, _ to: CGPoint) -> some View {
        ZStack {
            Path { p in p.move(to: from); p.addLine(to: to) }
                .stroke(amberAccent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: to.x - 9, y: to.y - 5))
                p.addLine(to: to)
                p.addLine(to: CGPoint(x: to.x - 9, y: to.y + 5))
            }
            .stroke(amberAccent, style: StrokeStyle(lineWidth: 2.4,
                                                    lineCap: .round, lineJoin: .round))
        }
    }

    private func wordDot(_ text: String, _ at: CGPoint, tint: Color) -> some View {
        VStack(spacing: 3) {
            Circle().fill(tint).frame(width: 11, height: 11)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
        }
        .position(x: at.x, y: at.y + 6)
    }
}

// MARK: SkipGramWindowArt (how-it-learns illustration)
//
// A sentence with a context window over five words: the centre word, and the
// arrows out to the neighbours it is trained to predict.

struct SkipGramWindowArt: View {
    private let words = ["the", "quick", "brown", "fox", "jumps", "over", "lazy"]
    private let center = 3

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let n = words.count
            let slot = w / CGFloat(n)
            let y = h * 0.62
            let cx: (Int) -> CGFloat = { slot * (CGFloat($0) + 0.5) }

            ZStack {
                // the window box over centre +/- 2
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tealLight.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tealAccent.opacity(0.4), lineWidth: 1))
                    .frame(width: slot * 5, height: 38)
                    .position(x: cx(center), y: y)
                // arrows from centre to each neighbour in the window
                ForEach([1, 2, 4, 5], id: \.self) { j in
                    Path { p in
                        p.move(to: CGPoint(x: cx(center), y: y - 22))
                        p.addQuadCurve(to: CGPoint(x: cx(j), y: y - 22),
                                       control: CGPoint(x: (cx(center) + cx(j)) / 2,
                                                        y: y - 22 - h * 0.34))
                    }
                    .stroke(tealAccent.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }
                ForEach(0..<n, id: \.self) { i in
                    Text(words[i])
                        .font(.system(size: 12,
                                      weight: i == center ? .bold : .regular,
                                      design: .serif))
                        .foregroundStyle(i == center ? tealAccent : inkColor.opacity(0.7))
                        .position(x: cx(i), y: y)
                }
                Text("predict the neighbours from the centre word")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(mutedText)
                    .position(x: w / 2, y: h * 0.95)
            }
        }
    }
}

// MARK: Word2VecLineage (impact timeline)

struct Word2VecLineage: View {
    private struct Milestone { let year: String; let label: String; let accent: Bool }
    private let milestones: [Milestone] = [
        Milestone(year: "2013", label: "word2vec",    accent: true),
        Milestone(year: "2017", label: "Transformer", accent: false),
        Milestone(year: "2020", label: "GPT-3",       accent: false),
        Milestone(year: "today", label: "Every model", accent: false),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(milestones.indices, id: \.self) { i in
                    Text(milestones[i].year)
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }
            ZStack {
                Rectangle().fill(inkColor.opacity(0.35)).frame(height: 1)
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
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - WordMapPlayground
//
// The reader taps any word on a small meaning map; its three nearest
// neighbours light up and lines connect them. The clusters are obvious once
// touched: words used alike sit together. Unlocks after three words probed.

struct WordMapPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private struct W { let text: String; let x: Double; let y: Double; let cluster: Int }
    private let words: [W] = [
        W(text: "king",   x: 0.72, y: 0.80, cluster: 0),
        W(text: "queen",  x: 0.86, y: 0.70, cluster: 0),
        W(text: "prince", x: 0.78, y: 0.58, cluster: 0),
        W(text: "cat",    x: 0.20, y: 0.30, cluster: 1),
        W(text: "dog",    x: 0.34, y: 0.40, cluster: 1),
        W(text: "horse",  x: 0.18, y: 0.50, cluster: 1),
        W(text: "tea",    x: 0.24, y: 0.84, cluster: 2),
        W(text: "coffee", x: 0.14, y: 0.70, cluster: 2),
        W(text: "water",  x: 0.36, y: 0.72, cluster: 2),
    ]

    @State private var selected: Int? = nil
    @State private var tapped: Set<Int> = []

    private func dist(_ i: Int, _ j: Int) -> Double {
        let dx = words[i].x - words[j].x, dy = words[i].y - words[j].y
        return dx * dx + dy * dy
    }
    private func neighbors(of i: Int) -> [Int] {
        Array(words.indices.filter { $0 != i }
            .sorted { dist(i, $0) < dist(i, $1) }
            .prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 14)

            Text("TAP A WORD")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Every word sits at a point. Tap one to see its nearest neighbours, the words word2vec judged most alike.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            mapPlot
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mapPlot: some View {
        GeometryReader { g in
            // The ZStack below is framed to s and centred, so positions
            // inside it already run 0...s. No extra centring offset, or
            // every chip is pushed off the right edge of the white box.
            let s = min(g.size.width, g.size.height)
            let pt: (Int) -> CGPoint = { i in
                mapPoint(words[i].x, words[i].y, s)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))

                if let sel = selected {
                    ForEach(neighbors(of: sel), id: \.self) { j in
                        Path { p in p.move(to: pt(sel)); p.addLine(to: pt(j)) }
                            .stroke(tealAccent.opacity(0.6),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                }
                ForEach(words.indices, id: \.self) { i in
                    wordChip(i)
                        .position(pt(i))
                        .onTapGesture { select(i) }
                }
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 250)
    }

    private func wordChip(_ i: Int) -> some View {
        let isSel = selected == i
        let near = selected.map { neighbors(of: $0).contains(i) } ?? false
        let dim = selected != nil && !isSel && !near
        return Text(words[i].text)
            .font(.system(size: 12, weight: .semibold, design: .serif))
            .foregroundStyle(isSel ? .white : inkColor.opacity(dim ? 0.32 : 0.85))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSel ? tealAccent : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(near ? tealAccent : borderColor,
                                lineWidth: near ? 1.6 : 1)))
            .opacity(dim ? 0.7 : 1)
            .animation(.snappy(duration: 0.3), value: selected)
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(selected == nil ? amberAccent : tealAccent)
                .frame(width: 9, height: 9)
            Text(captionText)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var captionText: String {
        guard let sel = selected else { return "Tap a word to see what sits near it." }
        let near = neighbors(of: sel).map { words[$0].text }
        return "\u{201C}\(words[sel].text)\u{201D} sits nearest \(near[0]) and \(near[1])."
    }

    private func select(_ i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) { selected = i }
        tapped.insert(i)
        if tapped.count >= 3 { progress.markExplored(cardId) }
    }
}

// MARK: - AnalogyPlayground
//
// The analogy machine. The reader sets three words into A minus B plus C; the
// result vector is computed and the nearest real word is found. Two parallel
// arrows show why it works: B to A is the same step as C to the result.
// Unlocks once the reader has changed the inputs twice.

struct AnalogyPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private struct W { let text: String; let x: Double; let y: Double }
    // A clean gender (vertical) by royalty (horizontal) plane.
    private let words: [W] = [
        W(text: "king",     x: 0.80, y: 0.74),
        W(text: "queen",    x: 0.80, y: 0.34),
        W(text: "prince",   x: 0.60, y: 0.66),
        W(text: "princess", x: 0.60, y: 0.42),
        W(text: "man",      x: 0.24, y: 0.74),
        W(text: "woman",    x: 0.24, y: 0.34),
        W(text: "boy",      x: 0.12, y: 0.66),
        W(text: "girl",     x: 0.12, y: 0.42),
    ]

    @State private var aIdx = 0   // king
    @State private var bIdx = 4   // man
    @State private var cIdx = 5   // woman
    @State private var changes = 0

    private var result: (x: Double, y: Double) {
        (words[aIdx].x - words[bIdx].x + words[cIdx].x,
         words[aIdx].y - words[bIdx].y + words[cIdx].y)
    }
    private var nearestIdx: Int {
        var best = 0, bd = Double.infinity
        for i in words.indices {
            let dx = words[i].x - result.x, dy = words[i].y - result.y
            let d = dx * dx + dy * dy
            if d < bd { bd = d; best = i }
        }
        return best
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("THE ANALOGY MACHINE")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Tap any word in the sum to change it. Word2vec subtracts and adds the vectors, then reads off the closest word.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            equation
            analogyPlot
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var equation: some View {
        HStack(spacing: 6) {
            slot(aIdx) { aIdx = (aIdx + 1) % words.count; bumped() }
            op("\u{2212}")
            slot(bIdx) { bIdx = (bIdx + 1) % words.count; bumped() }
            op("+")
            slot(cIdx) { cIdx = (cIdx + 1) % words.count; bumped() }
            op("=")
            Text(words[nearestIdx].text)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(amberAccent))
        }
        .frame(maxWidth: .infinity)
    }

    private func slot(_ idx: Int, _ tap: @escaping () -> Void) -> some View {
        Text(words[idx].text)
            .font(.system(size: 13, weight: .semibold, design: .serif))
            .foregroundStyle(tealAccent)
            .padding(.horizontal, 9)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(tealAccent.opacity(0.12)))
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.snappy(duration: 0.25)) { tap() }
            }
    }

    private func op(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(mutedText)
    }

    private var analogyPlot: some View {
        GeometryReader { g in
            // The ZStack below is framed to s and centred, so positions
            // inside it already run 0...s. No extra centring offset, or
            // every label is pushed off the right edge of the white box.
            let s = min(g.size.width, g.size.height)
            let pt: ((Double, Double)) -> CGPoint = { p in
                mapPoint(p.0, p.1, s)
            }
            // The raw sum can fall off the map; clamp only what gets drawn.
            let shown = (min(max(result.x, 0), 1), min(max(result.y, 0), 1))
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))

                // arrow B -> A (the relationship) and C -> result (the same step)
                vector(pt((words[bIdx].x, words[bIdx].y)),
                       pt((words[aIdx].x, words[aIdx].y)), tint: tealAccent)
                vector(pt((words[cIdx].x, words[cIdx].y)),
                       pt(shown), tint: amberAccent)

                // the result marker, behind the labels so the word reads through
                Circle()
                    .stroke(amberAccent, lineWidth: 2.5)
                    .frame(width: 30, height: 30)
                    .position(pt(shown))

                ForEach(words.indices, id: \.self) { i in
                    let active = i == aIdx || i == bIdx || i == cIdx
                    Text(words[i].text)
                        .font(.system(size: 11,
                                      weight: active ? .bold : .regular,
                                      design: .serif))
                        .foregroundStyle(active ? inkColor : inkColor.opacity(0.4))
                        .position(pt((words[i].x, words[i].y)))
                }
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity)
            .animation(.snappy(duration: 0.3), value: aIdx + bIdx * 10 + cIdx * 100)
        }
        .frame(height: 230)
    }

    private func vector(_ from: CGPoint, _ to: CGPoint, tint: Color) -> some View {
        Path { p in p.move(to: from); p.addLine(to: to) }
            .stroke(tint, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle().fill(tealAccent).frame(width: 9, height: 9)
            Text("The teal arrow and the amber arrow are the same step. That is why the sum lands on \u{201C}\(words[nearestIdx].text)\u{201D}.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func bumped() {
        changes += 1
        if changes >= 2 {
            progress.markExplored(cardId)
        }
    }
}

// MARK: - SkipGramPlayground
//
// The reader taps any word to make it the centre; the context window snaps
// around it and the training pairs it produces are listed. Makes the skip-gram
// game concrete: one centre word, several "predict my neighbour" pairs.
// Unlocks after the window has been moved to three different words.

struct SkipGramPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let tokens = ["the", "quick", "brown", "fox", "jumps", "over", "lazy", "dogs"]
    @State private var center = 3
    @State private var visited: Set<Int> = [3]

    private var contextIdx: [Int] {
        [center - 2, center - 1, center + 1, center + 2].filter { tokens.indices.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("SLIDE THE WINDOW")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Tap any word to make it the centre. Word2vec\u{2019}s only job is to predict the words inside the window from that centre.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sentenceRow
            pairsPanel
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The eight words flow across two lines so each chip keeps its natural
    // width: no word is ever squeezed into a mid-word break.
    private var sentenceRow: some View {
        VStack(spacing: 6) {
            wordLine(0..<4)
            wordLine(4..<8)
        }
        .animation(.snappy(duration: 0.25), value: center)
    }

    private func wordLine(_ range: Range<Int>) -> some View {
        HStack(spacing: 6) {
            ForEach(range, id: \.self) { i in wordChip(i) }
        }
    }

    private func wordChip(_ i: Int) -> some View {
        let inWindow = contextIdx.contains(i)
        let isCenter = i == center
        return Text(tokens[i])
            .font(.system(size: 13,
                          weight: isCenter ? .bold : .medium,
                          design: .serif))
            .foregroundStyle(isCenter ? .white
                             : (inWindow ? tealAccent : inkColor.opacity(0.55)))
            .fixedSize()
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isCenter ? tealAccent
                          : (inWindow ? tealLight : Color.clear)))
            .onTapGesture { move(to: i) }
    }

    private var pairsPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TRAINING PAIRS FROM THIS CENTRE")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(mutedText)
            ForEach(contextIdx, id: \.self) { j in
                HStack(spacing: 7) {
                    Text(tokens[center])
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(tealAccent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(mutedText)
                    Text(tokens[j])
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(inkColor.opacity(0.75))
                    Spacer()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)))
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle().fill(tealAccent).frame(width: 9, height: 9)
            Text("Each pair nudges the centre\u{2019}s vector toward its neighbour\u{2019}s. Do this billions of times and meaning settles in.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func move(to i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.25)) { center = i }
        visited.insert(i)
        if visited.count >= 3 { progress.markExplored(cardId) }
    }
}

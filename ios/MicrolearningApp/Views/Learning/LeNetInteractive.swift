import SwiftUI

// MARK: - LeNet bespoke interactives
//
// Hand-built interactive diagrams for the LeNet lesson. Where the backprop
// paper was about a network learning, this paper is about how a network
// should *look at an image*. So every visual here is a pixel grid: a filter
// sliding across it, a digit wobbling under a pooling summary, and a grid
// the reader inks in by hand. Nothing generic, nothing shared with the
// other lessons.

// MARK: - Shared pixel grid
//
// One reusable NxN cell grid. `color` paints each cell, `onTap` makes it
// editable. Every LeNet interactive is built from this.

private struct LeNetPixelGrid: View {
    let rows: Int
    let cols: Int
    let color: (Int, Int) -> Color
    var stroke: Color = borderColor
    var onTap: ((Int, Int) -> Void)? = nil

    // A real VStack/HStack layout, not GeometryReader + .position. With
    // .position every cell expands to fill the parent and they stack, so
    // only the last-drawn cell is tappable. Flexible-framed cells each
    // keep their own hit area.
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<cols, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(color(r, c))
                            .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(stroke, lineWidth: 0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { onTap?(r, c) }
                    }
                }
            }
        }
    }
}

// MARK: - Digit bitmaps

private enum LeNetDigits {
    // 7x7 strokes used by the conv-slide and draw studios.
    static let seven: [[Int]] = [
        [1,1,1,1,1,1,0],
        [0,0,0,0,1,1,0],
        [0,0,0,1,1,0,0],
        [0,0,1,1,0,0,0],
        [0,0,1,1,0,0,0],
        [0,1,1,0,0,0,0],
        [0,1,1,0,0,0,0],
    ]
    static let one: [[Int]] = [
        [0,0,0,1,1,0,0],
        [0,0,1,1,1,0,0],
        [0,0,0,1,1,0,0],
        [0,0,0,1,1,0,0],
        [0,0,0,1,1,0,0],
        [0,0,0,1,1,0,0],
        [0,0,1,1,1,1,0],
    ]
    static let three: [[Int]] = [
        [0,1,1,1,1,0,0],
        [0,0,0,0,1,1,0],
        [0,0,1,1,1,0,0],
        [0,0,0,0,1,1,0],
        [0,0,0,0,1,1,0],
        [0,1,0,0,1,1,0],
        [0,1,1,1,1,0,0],
    ]
    // 5x5 core placed into an 8x8 frame for the pooling studio.
    static let threeCore: [[Int]] = [
        [1,1,1,1,0],
        [0,0,0,1,1],
        [0,1,1,1,0],
        [0,0,0,1,1],
        [1,1,1,1,0],
    ]
}

// MARK: - LeNetScanGlyph (cover hero)
//
// A digit on the dark cover with a teal filter square sweeping across it,
// feature dots lighting in its wake. The one motion the paper is about:
// a small detector, slid everywhere. Loops forever.

struct LeNetScanGlyph: View {
    @State private var phase: Double = 0   // 0..1, drives the sweep

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let n = 7
            let cell = side / CGFloat(n)
            let steps = (n - 2) * (n - 2)            // 25 filter positions
            let pos = min(steps - 1, Int(phase * Double(steps)))
            let fr = pos / (n - 2)
            let fc = pos % (n - 2)

            ZStack {
                // faint digit
                ForEach(0..<n, id: \.self) { r in
                    ForEach(0..<n, id: \.self) { c in
                        if LeNetDigits.seven[r][c] == 1 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ink.opacity(0.34))
                                .frame(width: cell - 3, height: cell - 3)
                                .position(x: cell * (CGFloat(c) + 0.5),
                                          y: cell * (CGFloat(r) + 0.5))
                        }
                    }
                }
                // feature dots already passed
                ForEach(0..<steps, id: \.self) { s in
                    if s < pos {
                        let dr = s / (n - 2), dc = s % (n - 2)
                        let lit = LeNetDigits.seven[dr + 1][dc + 1] == 1
                        Circle()
                            .fill((lit ? tealAccent : ink.opacity(0.12)))
                            .frame(width: lit ? 7 : 4, height: lit ? 7 : 4)
                            .position(x: cell * (CGFloat(dc) + 1.5),
                                      y: cell * (CGFloat(dr) + 1.5))
                    }
                }
                // sliding filter window
                RoundedRectangle(cornerRadius: 4)
                    .stroke(tealAccent, lineWidth: 2.5)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .fill(tealAccent.opacity(0.16)))
                    .frame(width: cell * 3, height: cell * 3)
                    .position(x: cell * (CGFloat(fc) + 1.5),
                              y: cell * (CGFloat(fr) + 1.5))
                    .shadow(color: tealAccent.opacity(0.6), radius: 8)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation(.linear(duration: 4.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - ShiftingSevenArt (illustrated hero)
//
// The same digit drawn three times at three offsets. The point of the
// opening card: a 7 is never the same pixels twice.

struct ShiftingSevenArt: View {
    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height * 1.6)
            let cell = side / 16
            ZStack {
                ForEach(0..<3, id: \.self) { k in
                    let dx = CGFloat([0, 4, 8][k])
                    let dy = CGFloat([5, 1, 6][k])
                    ForEach(0..<7, id: \.self) { r in
                        ForEach(0..<7, id: \.self) { c in
                            if LeNetDigits.seven[r][c] == 1 {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(k == 1 ? tealAccent.opacity(0.85)
                                                 : inkColor.opacity(0.22))
                                    .frame(width: cell - 2, height: cell - 2)
                                    .position(x: cell * (CGFloat(c) + 0.5) + dx * cell * 0.5,
                                              y: cell * (CGFloat(r) + 0.5) + dy * cell * 0.4)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - WeightShareArt (illustrated hero)
//
// One filter chip with arrows fanning out to many spots on a grid: the
// picture of weight sharing, one detector reused everywhere.

struct WeightShareArt: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let src = CGPoint(x: w * 0.16, y: h * 0.5)
            let targets = [
                CGPoint(x: w * 0.6,  y: h * 0.2),
                CGPoint(x: w * 0.8,  y: h * 0.42),
                CGPoint(x: w * 0.62, y: h * 0.66),
                CGPoint(x: w * 0.84, y: h * 0.86),
                CGPoint(x: w * 0.5,  y: h * 0.9),
            ]
            ZStack {
                ForEach(0..<targets.count, id: \.self) { i in
                    Path { p in
                        p.move(to: src)
                        p.addLine(to: targets[i])
                    }
                    .stroke(tealAccent.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                }
                ForEach(0..<targets.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(tealAccent, lineWidth: 1.6)
                        .background(RoundedRectangle(cornerRadius: 3)
                            .fill(tealAccent.opacity(0.12)))
                        .frame(width: 20, height: 20)
                        .position(targets[i])
                }
                RoundedRectangle(cornerRadius: 5)
                    .fill(amberAccent)
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white))
                    .position(src)
            }
        }
    }
}

// MARK: - ConvSlideStudio (interactive 1)
//
// One 3x3 filter, slid across a 7x7 digit. At every stop it answers one
// question: how much stroke is under me right now. The answers fill a
// feature map. The lesson the reader should feel: it is the SAME filter
// at every position, never a new one.

struct ConvSlideStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let n = 7
    private let fSize = 3
    private var maps: Int { n - fSize + 1 }       // 5
    private var steps: Int { maps * maps }        // 25

    @State private var pos = 0
    @State private var feature: [[Double]] = Array(repeating: Array(repeating: -1, count: 5),
                                                   count: 5)
    @State private var running = false
    @State private var hintBob = false

    private var done: Bool { pos >= steps }
    private var fr: Int { min(maps - 1, pos / maps) }
    private var fc: Int { min(maps - 1, pos % maps) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("SLIDE THE FILTER")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The window is a tiny 3x3 detector. Step it across the digit. At each stop it scores how much ink it covers, and that score drops into the feature map below. One detector, every position.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            imageWithFilter
            scrollHint
            arrowDown
            featureMap
            statusRow
            buttons
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imageWithFilter: some View {
        GeometryReader { g in
            let side = g.size.width
            let cell = side / CGFloat(n)
            ZStack(alignment: .topLeading) {
                LeNetPixelGrid(rows: n, cols: n, color: { r, c in
                    LeNetDigits.seven[r][c] == 1 ? inkColor.opacity(0.9)
                                                 : inkColor.opacity(0.05)
                })
                RoundedRectangle(cornerRadius: 4)
                    .stroke(done ? tealAccent : amberAccent, lineWidth: 2.5)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .fill((done ? tealAccent : amberAccent).opacity(0.14)))
                    .frame(width: cell * 3, height: cell * 3)
                    .offset(x: cell * CGFloat(fc), y: cell * CGFloat(fr))
                    .animation(.snappy(duration: 0.22), value: pos)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 230)
        .frame(maxWidth: .infinity)
    }

    private var arrowDown: some View {
        Image(systemName: "arrow.down")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(mutedText)
            .frame(maxWidth: .infinity)
    }

    /// Subtle nudge that the slide controls sit below the fold. Bobs gently,
    /// and disappears the moment the reader starts sliding.
    @ViewBuilder
    private var scrollHint: some View {
        if pos == 0 && !running {
            HStack(spacing: 5) {
                Text("Scroll for the controls")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(mutedText.opacity(0.55))
            .frame(maxWidth: .infinity)
            .offset(y: hintBob ? 2 : -2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    hintBob = true
                }
            }
        }
    }

    private var featureMap: some View {
        VStack(spacing: 6) {
            Text("FEATURE MAP")
                .font(.system(size: 10, weight: .bold)).tracking(1.6)
                .foregroundStyle(mutedText)
            LeNetPixelGrid(rows: maps, cols: maps, color: { r, c in
                let v = feature[r][c]
                return v < 0 ? inkColor.opacity(0.04)
                             : tealAccent.opacity(0.18 + 0.8 * v)
            })
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 165)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "One filter covered all 25 positions. That whole map came from a single 3x3 detector."
                 : "Position \(pos + 1) of \(steps)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button { step() } label: {
                Text("Slide one step")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(inkColor))
            }
            .buttonStyle(.plain)
            .disabled(done || running)

            Button { autoRun() } label: {
                Text(done ? "Done \u{2713}" : "Auto run")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(done ? tealAccent : tealAccent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(tealAccent.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .disabled(done || running)
        }
    }

    private func score(at r: Int, _ c: Int) -> Double {
        var sum = 0.0
        for i in 0..<fSize {
            for j in 0..<fSize {
                sum += Double(LeNetDigits.seven[r + i][c + j])
            }
        }
        return sum / Double(fSize * fSize)
    }

    private func step() {
        guard !done else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let r = pos / maps, c = pos % maps
        withAnimation(.snappy(duration: 0.25)) {
            feature[r][c] = score(at: r, c)
            pos += 1
        }
        if done {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func autoRun() {
        guard !running, !done else { return }
        running = true
        func tick() {
            guard pos < steps else { running = false; return }
            step()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { tick() }
        }
        tick()
    }
}

// MARK: - PoolShiftStudio (interactive 2)
//
// The same digit, nudged around an 8x8 frame. Below it, the 2x2 max-pooled
// summary. Nudge the digit and watch: the raw pixels move a lot, the pooled
// summary barely flinches. That stability is what pooling buys.

struct PoolShiftStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var dx = 1
    @State private var dy = 1
    @State private var nudges = 0

    private let frame = 8
    private let core = LeNetDigits.threeCore   // 5x5

    private func raw(_ r: Int, _ c: Int) -> Bool {
        let cr = r - dy, cc = c - dx
        guard cr >= 0, cr < 5, cc >= 0, cc < 5 else { return false }
        return core[cr][cc] == 1
    }

    /// 2x2 max-pool of the raw frame -> 4x4.
    private func pooled(_ r: Int, _ c: Int) -> Bool {
        for i in 0..<2 {
            for j in 0..<2 {
                if raw(r * 2 + i, c * 2 + j) { return true }
            }
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("NUDGE THE DIGIT")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Move the digit around its frame. The raw pixels shift a lot. The pooled summary underneath, each cell the busiest corner of a 2x2 block, hardly changes. Pooling teaches the network to stop caring about a small wobble.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 14) {
                gridBlock(title: "RAW 8x8", n: frame, cells: raw, max: 230)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(mutedText)
                gridBlock(title: "POOLED 4x4", n: 4, cells: pooled, max: 130)
            }
            .frame(maxWidth: .infinity)

            dpad
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gridBlock(title: String, n: Int,
                           cells: @escaping (Int, Int) -> Bool,
                           max: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold)).tracking(1.4)
                .foregroundStyle(mutedText)
            LeNetPixelGrid(rows: n, cols: n, color: { r, c in
                cells(r, c) ? (title.hasPrefix("POOLED") ? tealAccent : inkColor.opacity(0.9))
                            : inkColor.opacity(0.05)
            })
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: max)
        }
    }

    private var dpad: some View {
        HStack(spacing: 18) {
            arrowButton("arrow.left")  { shift(-1, 0) }
            VStack(spacing: 8) {
                arrowButton("arrow.up")   { shift(0, -1) }
                arrowButton("arrow.down") { shift(0,  1) }
            }
            arrowButton("arrow.right") { shift(1, 0) }
            Spacer()
            Button { dx = 1; dy = 1 } label: {
                Text("Reset")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(mutedText)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func arrowButton(_ icon: String, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 38)
                .background(RoundedRectangle(cornerRadius: 10).fill(inkColor))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(nudges >= 4 ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(nudges >= 4
                 ? "Notice how steady the pooled summary stayed. A shifted digit is still the same digit to the layer above."
                 : "Nudge it a few more times and watch the pooled grid.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func shift(_ ddx: Int, _ ddy: Int) {
        let nx = min(3, max(0, dx + ddx))
        let ny = min(3, max(0, dy + ddy))
        guard nx != dx || ny != dy else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.25)) { dx = nx; dy = ny }
        nudges += 1
        if nudges == 4 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - DigitVoteStudio (interactive 3)
//
// The payoff. The reader inks a 7x7 grid by tapping cells. Three feature
// templates (1, 3, 7) score the drawing by overlap, and a confidence bar
// names the winner. This is the whole network, compressed: detectors that
// vote, the kind of weights backprop would have tuned.

struct DigitVoteStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var ink: Set<Int> = []      // flattened r*7+c
    @State private var taps = 0

    private let templates: [(name: String, bits: [[Int]])] = [
        ("1", LeNetDigits.one),
        ("3", LeNetDigits.three),
        ("7", LeNetDigits.seven),
    ]

    private func isInk(_ r: Int, _ c: Int) -> Bool { ink.contains(r * 7 + c) }

    /// Overlap score against one template: shared ink minus stray ink.
    private func score(_ bits: [[Int]]) -> Double {
        guard !ink.isEmpty else { return 0 }
        var hit = 0, tmpl = 0, stray = 0
        for r in 0..<7 {
            for c in 0..<7 {
                let on = isInk(r, c)
                let t = bits[r][c] == 1
                if t { tmpl += 1 }
                if on && t { hit += 1 }
                if on && !t { stray += 1 }
            }
        }
        let cover = Double(hit) / Double(max(1, tmpl))
        let penalty = Double(stray) / Double(max(1, ink.count))
        return max(0, cover - 0.5 * penalty)
    }

    private var scores: [Double] { templates.map { score($0.bits) } }
    private var bestIdx: Int? {
        let s = scores
        guard let m = s.max(), m > 0.15 else { return nil }
        return s.firstIndex(of: m)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("DRAW A DIGIT")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Tap cells to ink a digit. Three detectors, each tuned to one shape, score what you drew. The bars are their votes. This is a whole convolutional net in miniature: detectors whose weights backprop would have learned.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            grid
            votes
            footerRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var grid: some View {
        LeNetPixelGrid(rows: 7, cols: 7,
                       color: { r, c in
                           isInk(r, c) ? inkColor.opacity(0.92) : inkColor.opacity(0.05)
                       },
                       stroke: borderColor,
                       onTap: { r, c in toggle(r, c) })
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 240)
        .frame(maxWidth: .infinity)
    }

    private var votes: some View {
        VStack(spacing: 10) {
            ForEach(0..<templates.count, id: \.self) { i in
                voteRow(i)
            }
        }
    }

    private func voteRow(_ i: Int) -> some View {
        let s = scores[i]
        let win = bestIdx == i
        return HStack(spacing: 10) {
            Text(templates[i].name)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(win ? tealAccent : inkColor.opacity(0.7))
                .frame(width: 20)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(inkColor.opacity(0.06))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(win ? tealAccent : inkColor.opacity(0.28))
                        .frame(width: max(4, g.size.width * CGFloat(min(1, s))))
                }
            }
            .frame(height: 18)
            .animation(.snappy(duration: 0.3), value: s)
            Text("\(Int(min(1, s) * 100))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(mutedText)
                .frame(width: 38, alignment: .trailing)
        }
    }

    private var footerRow: some View {
        HStack(spacing: 10) {
            Circle().fill(bestIdx != nil ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(verdict)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button { ink = []; } label: {
                Text("Clear")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(mutedText)
            }
            .buttonStyle(.plain)
        }
    }

    private var verdict: String {
        if let b = bestIdx {
            return "The detectors read it as a \(templates[b].name)."
        }
        return ink.isEmpty ? "Tap cells to start drawing."
                           : "Too ambiguous yet, keep inking the shape."
    }

    private func toggle(_ r: Int, _ c: Int) {
        let key = r * 7 + c
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if ink.contains(key) { ink.remove(key) } else { ink.insert(key) }
        taps += 1
        if taps == 6 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

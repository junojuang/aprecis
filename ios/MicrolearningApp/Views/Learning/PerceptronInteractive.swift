import SwiftUI

// MARK: - Perceptron bespoke interactives
//
// Hand-built interactive diagrams for the perceptron lesson. Each one is
// specific to the idea it teaches — no generic chart component.

// MARK: Neuron glyph (cover hero)
//
// A minimal living neuron for the editorial cover: three inputs feed a
// central node, a pulse travels out. Light strokes, reads on the dark cover.

struct NeuronGlyph: View {
    @State private var pulse = false

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let core = CGPoint(x: w * 0.62, y: h * 0.5)
            let inputs = [0.28, 0.5, 0.72].map { CGPoint(x: w * 0.14, y: h * $0) }

            ZStack {
                // dendrites
                ForEach(inputs.indices, id: \.self) { i in
                    Path { p in
                        p.move(to: inputs[i])
                        p.addLine(to: core)
                    }
                    .stroke(ink.opacity(0.32), lineWidth: 1.4)
                }
                // axon
                Path { p in
                    p.move(to: core)
                    p.addLine(to: CGPoint(x: w * 0.96, y: h * 0.5))
                }
                .stroke(tealMid.opacity(0.7), lineWidth: 2)

                // input nodes
                ForEach(inputs.indices, id: \.self) { i in
                    Circle()
                        .fill(ink.opacity(0.5))
                        .frame(width: 12, height: 12)
                        .position(inputs[i])
                }
                // travelling pulse along the axon
                Circle()
                    .fill(amberAccent)
                    .frame(width: 9, height: 9)
                    .position(x: w * (pulse ? 0.96 : 0.62), y: h * 0.5)
                    .opacity(pulse ? 0 : 1)

                // core
                Circle()
                    .fill(tealAccent)
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(ink.opacity(0.85), lineWidth: 2))
                    .position(core)
                Circle()
                    .stroke(tealMid.opacity(0.6), lineWidth: 2)
                    .frame(width: pulse ? 96 : 56, height: pulse ? 96 : 56)
                    .opacity(pulse ? 0 : 0.8)
                    .position(core)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

// MARK: Neuron playground
//
// The reader becomes the weights. A single guest is described by three fixed
// traits; the reader drags how much each trait should count. The weighted sum
// fills a bar against a threshold, and the neuron's verdict flips live. Once
// the reader makes the verdict flip, the card is marked explored.

private struct Trait {
    let name: String
    let strength: Double   // the guest's fixed input value, 0...1
}

struct PerceptronNeuronPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let traits = [
        Trait(name: "Dressed sharp",  strength: 0.85),
        Trait(name: "On tonight's list", strength: 0.30),
        Trait(name: "A regular here", strength: 0.65),
    ]
    private let threshold = 0.95          // sum must cross this to fire
    private let maxSum = 1.8              // 3 traits × weight 1 × strength ~ ceiling

    @State private var weights: [Double] = [0.5, 0.5, 0.5]
    @State private var lastFired: Bool? = nil
    @State private var flash = false

    private var contributions: [Double] {
        zip(weights, traits).map { $0 * $1.strength }
    }
    private var sum: Double { contributions.reduce(0, +) }
    private var fires: Bool { sum >= threshold }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 18)

            Text("YOU ARE THE NEURON")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("One guest at the door. Decide how much each thing should count, and watch the neuron make the call.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            verdict
            sumBar

            VStack(spacing: 14) {
                ForEach(traits.indices, id: \.self) { i in
                    weightRow(i)
                }
            }
            .padding(.top, 2)

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: fires) { _, nowFires in
            // The first time the verdict flips, the reader has seen the
            // mechanism — unlock Continue.
            if let last = lastFired, last != nowFires {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                flash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { flash = false }
            }
            lastFired = nowFires
        }
        .onAppear { lastFired = fires }
    }

    // MARK: verdict badge

    private var verdict: some View {
        HStack(spacing: 10) {
            Image(systemName: fires ? "checkmark.circle.fill" : "hand.raised.fill")
                .font(.system(size: 18, weight: .bold))
            VStack(alignment: .leading, spacing: 1) {
                Text(fires ? "WAVED IN" : "STOPPED AT THE DOOR")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(0.5)
                Text(fires ? "The signal crossed the line. The neuron fires."
                           : "Not enough signal. The neuron stays quiet.")
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .opacity(0.8)
            }
            Spacer()
        }
        .foregroundStyle(fires ? .white : inkColor.opacity(0.7))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(fires ? tealAccent : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(fires ? .clear : borderColor, lineWidth: 1)))
        .scaleEffect(flash ? 1.04 : 1.0)
        .animation(.snappy(duration: 0.3), value: fires)
        .animation(.snappy(duration: 0.25), value: flash)
    }

    // MARK: weighted-sum bar

    private var sumBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE WEIGHTED SUM")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(mutedText)
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(inkColor.opacity(0.06))
                    // stacked per-trait contributions
                    HStack(spacing: 0) {
                        ForEach(contributions.indices, id: \.self) { i in
                            Rectangle()
                                .fill(segmentColor(i))
                                .frame(width: max(0, w * contributions[i] / maxSum))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    // threshold marker
                    Rectangle()
                        .fill(amberAccent)
                        .frame(width: 2.5)
                        .offset(x: w * threshold / maxSum)
                    Text("fire ▸")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(amberAccent)
                        .offset(x: w * threshold / maxSum + 5, y: -16)
                }
            }
            .frame(height: 26)
            .animation(.snappy(duration: 0.25), value: sum)
        }
    }

    private func segmentColor(_ i: Int) -> Color {
        [tealAccent, tealMid, Color(hex: "5fc8c8")][i % 3]
    }

    // MARK: weight row

    private func weightRow(_ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                HStack(spacing: 7) {
                    Circle().fill(segmentColor(i)).frame(width: 8, height: 8)
                    Text(traits[i].name)
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor)
                }
                Spacer()
                Text("counts \(Int(weights[i] * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(mutedText)
            }
            WeightSlider(value: $weights[i], tint: segmentColor(i))
        }
    }
}

// MARK: - WeightSlider
//
// A compact custom slider — a thin track with a draggable knob. Bespoke so it
// matches the editorial look rather than the stock iOS control.

struct WeightSlider: View {
    @Binding var value: Double   // 0...1
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let knobX = CGFloat(value) * (w - 26)
            ZStack(alignment: .leading) {
                Capsule().fill(inkColor.opacity(0.08)).frame(height: 6)
                Capsule().fill(tint).frame(width: knobX + 13, height: 6)
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(tint, lineWidth: 2.5))
                    .shadow(color: inkColor.opacity(0.15), radius: 3, y: 1)
                    .offset(x: knobX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let x = min(max(0, g.location.x - 13), w - 26)
                        value = Double(x / (w - 26))
                    }
            )
        }
        .frame(height: 26)
    }
}

// MARK: - SignalFlowArt
//
// Editorial illustration for the "big idea" card: three signals flow into a
// summing gate, one decision flows out. A pulse runs the path so the picture
// reads as a process, not a static schematic.

struct SignalFlowArt: View {
    @State private var t = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let ins = [0.24, 0.5, 0.76].map { CGPoint(x: w * 0.14, y: h * $0) }
            let gate = CGPoint(x: w * 0.54, y: h * 0.5)
            let out  = CGPoint(x: w * 0.9,  y: h * 0.5)

            ZStack {
                ForEach(ins.indices, id: \.self) { i in
                    Path { p in p.move(to: ins[i]); p.addLine(to: gate) }
                        .stroke(inkColor.opacity(0.2), lineWidth: 1.5)
                }
                Path { p in p.move(to: gate); p.addLine(to: out) }
                    .stroke(tealAccent.opacity(0.55), lineWidth: 2.5)

                ForEach(ins.indices, id: \.self) { i in
                    Circle().fill(tealMid)
                        .frame(width: 15, height: 15)
                        .position(ins[i])
                        .scaleEffect(t ? 1 : 0.7)
                        .animation(.easeInOut(duration: 0.9).repeatForever()
                            .delay(Double(i) * 0.2), value: t)
                }
                // pulse along the axon
                Circle().fill(amberAccent).frame(width: 9, height: 9)
                    .position(x: t ? out.x : gate.x, y: h * 0.5)
                    .opacity(t ? 0 : 1)
                    .animation(.easeIn(duration: 1.0).repeatForever(autoreverses: false), value: t)

                RoundedRectangle(cornerRadius: 10)
                    .fill(inkColor)
                    .frame(width: 48, height: 48)
                    .position(gate)
                Text("Σ")
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .position(gate)

                Circle().fill(amberAccent)
                    .frame(width: 22, height: 22)
                    .overlay(Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black)).foregroundStyle(.white))
                    .position(out)

                Text("three signals")
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(mutedText)
                    .position(x: w * 0.14, y: h * 0.95)
                Text("one decision")
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(mutedText)
                    .position(x: w * 0.86, y: h * 0.95)
            }
        }
        .onAppear { t = true }
    }
}

// MARK: - LinearSeparationDiagram
//
// A static editorial diagram for the "picture it on paper" card. Shows a 2-D
// map with a labelled teal cluster (let in) above a single dashed line and a
// labelled rose cluster (turned away) below it. Anchors the chart vocabulary
// — dots = guests, axes = signals, line = the rule — before the reader meets
// the interactive plot on the next card.

struct LinearSeparationDiagram: View {
    private struct Dot { let x: Double; let y: Double; let teal: Bool }

    // Two visually obvious clusters, separable by one diagonal line.
    private let dots: [Dot] = [
        Dot(x: 0.62, y: 0.60, teal: true),
        Dot(x: 0.76, y: 0.72, teal: true),
        Dot(x: 0.86, y: 0.62, teal: true),
        Dot(x: 0.70, y: 0.86, teal: true),
        Dot(x: 0.20, y: 0.30, teal: false),
        Dot(x: 0.32, y: 0.20, teal: false),
        Dot(x: 0.16, y: 0.46, teal: false),
        Dot(x: 0.36, y: 0.50, teal: false),
    ]

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor.opacity(0.55), lineWidth: 1)
                    .frame(width: s, height: s)

                ZStack {
                    // The dashed bouncer rule, slicing the clusters cleanly.
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: s * 0.18))
                        p.addLine(to: CGPoint(x: s, y: s * 0.82))
                    }
                    .stroke(inkColor.opacity(0.8),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

                    ForEach(dots.indices, id: \.self) { i in
                        let d = dots[i]
                        Circle()
                            .fill(d.teal ? tealAccent : Color(hex: "c2557a"))
                            .frame(width: 12, height: 12)
                            .position(x: CGFloat(d.x) * s,
                                      y: (1 - CGFloat(d.y)) * s)
                    }

                    Text("let in")
                        .font(.system(size: 9, weight: .bold)).tracking(1.4)
                        .foregroundStyle(tealAccent)
                        .position(x: s * 0.80, y: s * 0.14)
                    Text("turned away")
                        .font(.system(size: 9, weight: .bold)).tracking(1.4)
                        .foregroundStyle(Color(hex: "c2557a"))
                        .position(x: s * 0.24, y: s * 0.88)

                    // Faint axis labels, hugging the inside of the frame.
                    Text("dressed sharp →")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(mutedText.opacity(0.85))
                        .position(x: s * 0.50, y: s - 8)
                    Text("on the list →")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(mutedText.opacity(0.85))
                        .rotationEffect(.degrees(-90))
                        .position(x: 10, y: s * 0.5)
                }
                .frame(width: s, height: s)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

// MARK: - XORImpossibilityDiagram
//
// A static editorial diagram for the "puzzle a line can't solve" card. Four
// dots in the XOR layout, one representative dashed line, and the two dots
// that line gets wrong are ringed in amber. Communicates the wall in one
// glance, before the reader meets the spin-the-line interactive next.

struct XORImpossibilityDiagram: View {
    private struct Dot { let x: Double; let y: Double; let teal: Bool }

    private let dots: [Dot] = [
        Dot(x: 0.26, y: 0.26, teal: true),
        Dot(x: 0.74, y: 0.74, teal: true),
        Dot(x: 0.74, y: 0.26, teal: false),
        Dot(x: 0.26, y: 0.74, teal: false),
    ]

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor.opacity(0.55), lineWidth: 1)
                    .frame(width: s, height: s)

                ZStack {
                    // A representative vertical line — any orientation gives
                    // the same wrong-count, two; vertical keeps the diagram
                    // legible.
                    Path { p in
                        p.move(to: CGPoint(x: s / 2, y: s * 0.08))
                        p.addLine(to: CGPoint(x: s / 2, y: s * 0.92))
                    }
                    .stroke(inkColor.opacity(0.8),
                            style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))

                    ForEach(dots.indices, id: \.self) { i in
                        let d = dots[i]
                        // With the vertical line at x=0.5 and the convention
                        // "left = let in", the teal at NE (x=0.74) and the
                        // rose at NW (x=0.26) are on the wrong side. Ring
                        // both in amber so the failure is unmissable.
                        let wrong = (d.teal && d.x > 0.5) ||
                                    (!d.teal && d.x < 0.5)
                        Circle()
                            .fill(d.teal ? tealAccent : Color(hex: "c2557a"))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(amberAccent,
                                            lineWidth: wrong ? 3 : 0)
                                    .frame(width: 28, height: 28))
                            .position(x: CGFloat(d.x) * s,
                                      y: (1 - CGFloat(d.y)) * s)
                    }

                    Text("2 always wrong")
                        .font(.system(size: 9, weight: .bold)).tracking(1.4)
                        .foregroundStyle(amberAccent)
                        .position(x: s / 2, y: s - 12)
                }
                .frame(width: s, height: s)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

// MARK: - PerceptronBoundaryLearner
//
// The learning rule, made tactile. Two classes of dots, linearly separable.
// A decision line starts wrong; each tap shows the perceptron one mistake and
// it nudges its weights — the line shifts, the wrong-count drops, and the
// reader watches a rule get found by trial and error. Card unlocks at zero.

struct PerceptronBoundaryLearner: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private struct Dot { let x: Double; let y: Double; let label: Double }

    private let dots: [Dot] = [
        Dot(x: 0.66, y: 0.72, label: 1),  Dot(x: 0.80, y: 0.60, label: 1),
        Dot(x: 0.72, y: 0.86, label: 1),  Dot(x: 0.86, y: 0.76, label: 1),
        Dot(x: 0.24, y: 0.34, label: -1), Dot(x: 0.36, y: 0.22, label: -1),
        Dot(x: 0.28, y: 0.50, label: -1), Dot(x: 0.18, y: 0.30, label: -1),
    ]
    private let eta = 0.5

    @State private var w1 = 1.0
    @State private var w2 = 1.0
    @State private var b  = -1.58
    @State private var taps = 0

    private func score(_ d: Dot) -> Double { w1 * d.x + w2 * d.y + b }
    private func isWrong(_ d: Dot) -> Bool { (score(d) >= 0 ? 1.0 : -1.0) != d.label }
    private var wrongCount: Int { dots.filter(isWrong).count }
    private var solved: Bool { wrongCount == 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("NOW YOU TRY")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Same map as the last card. Each tap shows the perceptron its worst mistake; watch the line tilt itself toward zero wrongs.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            plot
            statusRow
            stepButton
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plot: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
                // Dynamic content (boundary line, dots) is clipped to the plot
                // so the dashed line can't bleed past the rounded frame and
                // cut into the surrounding text when the weights are steep.
                ZStack {
                    boundaryLine(s)
                    ForEach(dots.indices, id: \.self) { i in dotView(dots[i], s: s) }
                }
                .frame(width: s, height: s)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 240)
    }

    private func pt(_ d: Dot, _ s: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(d.x) * s, y: (1 - CGFloat(d.y)) * s)
    }

    @ViewBuilder private func boundaryLine(_ s: CGFloat) -> some View {
        // w1·x + w2·y + b = 0  →  y = -(w1·x + b) / w2
        let yAt: (Double) -> Double = { x in -(w1 * x + b) / w2 }
        let p0 = CGPoint(x: 0, y: (1 - CGFloat(yAt(0))) * s)
        let p1 = CGPoint(x: s, y: (1 - CGFloat(yAt(1))) * s)
        Path { p in p.move(to: p0); p.addLine(to: p1) }
            .stroke(inkColor.opacity(0.8), style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
            .animation(.snappy(duration: 0.45), value: w1 + w2 + b)
    }

    private func dotView(_ d: Dot, s: CGFloat) -> some View {
        let color = d.label > 0 ? tealAccent : Color(hex: "c2557a")
        let wrong = isWrong(d)
        return Circle()
            .fill(color)
            .frame(width: 17, height: 17)
            .overlay(
                Circle().stroke(amberAccent, lineWidth: wrong ? 3 : 0)
                    .frame(width: 26, height: 26))
            .position(pt(d, s))
            .animation(.snappy(duration: 0.45), value: wrong)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(solved ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(solved ? "Zero mistakes. The perceptron found the rule."
                        : "\(wrongCount) on the wrong side (ringed in amber)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
        }
    }

    private var stepButton: some View {
        Button {
            guard let m = dots.first(where: isWrong) else { return }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.snappy(duration: 0.45)) {
                w1 += eta * m.label * m.x
                w2 += eta * m.label * m.y
                b  += eta * m.label
            }
            taps += 1
            if wrongCount == 0 || taps >= 6 { progress.markExplored(cardId) }
        } label: {
            Text(solved ? "It learned the rule ✓" : "Show it a mistake")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(solved ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(solved ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(solved)
    }
}

// MARK: - XORWall
//
// The honest limit. Four dots in an exclusive-or pattern. The reader drags to
// spin the decision line; the wrong-count never reaches zero, because a single
// straight line cannot carve XOR. Card unlocks once they have spun it enough
// to feel the wall.

struct XORWall: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private struct Dot { let x: Double; let y: Double; let cls: Int }
    private let dots = [
        Dot(x: 0.24, y: 0.24, cls: 0), Dot(x: 0.76, y: 0.76, cls: 0),
        Dot(x: 0.76, y: 0.24, cls: 1), Dot(x: 0.24, y: 0.76, cls: 1),
    ]

    @State private var angle: Double = .pi / 5
    @State private var swept: Double = 0
    /// Line angle when the current drag began; nil between drags.
    @State private var dragStartAngle: Double? = nil

    /// Normal of the line is (cos, sin); a dot's side is the sign of the
    /// projection. `wrong` takes the better of the two class→side mappings.
    private func side(_ d: Dot) -> Int {
        let v = cos(angle) * (d.x - 0.5) + sin(angle) * (d.y - 0.5)
        return v >= 0 ? 1 : 0
    }
    private var wrong: Int {
        let a = dots.filter { side($0) != $0.cls }.count
        return min(a, dots.count - a)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("TRY EVERY ANGLE")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(Color(hex: "c2557a"))
            Text("Drag the line to any angle you like. The wrong count never drops below two. The wall, in your hands.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            plot
            HStack(spacing: 8) {
                Circle().fill(Color(hex: "c2557a")).frame(width: 9, height: 9)
                Text("\(wrong) dot\(wrong == 1 ? "" : "s") still on the wrong side. It never hits zero.")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.8))
            }
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plot: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
                // Clip the spin line + dots + caption so the rotating dashed
                // line can't bleed past the plot's rounded frame and cut
                // into the surrounding body text.
                ZStack {
                    spinLine(s)
                    ForEach(dots.indices, id: \.self) { i in
                        Circle()
                            .fill(dots[i].cls == 0 ? tealAccent : Color(hex: "c2557a"))
                            .frame(width: 20, height: 20)
                            .position(x: CGFloat(dots[i].x) * s, y: (1 - CGFloat(dots[i].y)) * s)
                    }
                    Text("drag to spin")
                        .font(.system(size: 10, weight: .bold)).tracking(1)
                        .foregroundStyle(mutedText)
                        .position(x: s / 2, y: s - 16)
                }
                .frame(width: s, height: s)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(spinGesture())
        }
        .frame(height: 240)
    }

    private func spinLine(_ s: CGFloat) -> some View {
        // Line through the centre, perpendicular to the normal (cos, sin).
        let c = CGPoint(x: s / 2, y: s / 2)
        let dir = CGSize(width: -sin(angle), height: cos(angle))
        let len = s * 0.9
        let a = CGPoint(x: c.x + dir.width * len, y: c.y - dir.height * len)
        let bnd = CGPoint(x: c.x - dir.width * len, y: c.y + dir.height * len)
        return Path { p in p.move(to: a); p.addLine(to: bnd) }
            .stroke(inkColor.opacity(0.85), style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
    }

    // A simple left/right dial: dragging horizontally spins the line, so the
    // reader never has to orbit a finger around the centre. The line tracks
    // the drag directly — right spins it one way, left the other.
    private func spinGesture() -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                let start = dragStartAngle ?? angle
                if dragStartAngle == nil { dragStartAngle = start }
                // ~200pt of horizontal drag is a half-turn.
                let next = start + Double(v.translation.width) * (.pi / 200)
                swept += abs(next - angle)
                angle = next
                if swept > 1.6 { progress.markExplored(cardId) }
            }
            .onEnded { _ in dragStartAngle = nil }
    }
}

// MARK: - ThreeNightsStrip
//
// Editorial hero for the "How it learns" card. Three small plots side by
// side, showing the bouncer's rule tilting from a clumsy first guess
// toward the correct angle. Same dots in each panel; only the line moves.
// Misclassified dots wear an amber ring, so the reader sees the wrong-count
// shrink across the strip without anyone naming a number.

struct ThreeNightsStrip: View {
    private struct Dot { let x: Double; let y: Double; let teal: Bool }
    private struct Night {
        let label: String
        // Line endpoints in math coords: y at x=0, y at x=1.
        let yA: Double
        let yB: Double
        // Indices of dots this line gets wrong. Pre-computed against `dots`.
        let wrong: Set<Int>
    }

    // A small set with one stubborn rose dot at (0.20, 0.55) sitting near
    // the boundary. It is the dot that gets corrected last.
    private static let dots: [Dot] = [
        Dot(x: 0.55, y: 0.60, teal: true),
        Dot(x: 0.78, y: 0.58, teal: true),
        Dot(x: 0.68, y: 0.84, teal: true),
        Dot(x: 0.86, y: 0.74, teal: true),
        Dot(x: 0.32, y: 0.40, teal: false),
        Dot(x: 0.42, y: 0.22, teal: false),
        Dot(x: 0.20, y: 0.55, teal: false),
        Dot(x: 0.48, y: 0.45, teal: false),
    ]

    private let nights: [Night] = [
        // Night 1: line tilting the wrong way. Three dots on the wrong side.
        Night(label: "NIGHT 1", yA: 0.20, yB: 0.90, wrong: [1, 3, 6]),
        // Night 5: line has rotated; the boundary is close but one rose dot
        // still sits above.
        Night(label: "NIGHT 5", yA: 0.60, yB: 0.30, wrong: [6]),
        // Night N: settled. No rings.
        Night(label: "NIGHT N", yA: 0.80, yB: 0.15, wrong: []),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(nights.indices, id: \.self) { i in
                nightPanel(nights[i])
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // Fixed plot size keeps the strip predictable across screen widths.
    private static let plotSide: CGFloat = 80

    private func nightPanel(_ n: Night) -> some View {
        let s = Self.plotSide
        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(borderColor.opacity(0.55), lineWidth: 0.8))

                plotContents(n: n, s: s)
                    .frame(width: s, height: s)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(width: s, height: s)

            Text(n.label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(mutedText)
        }
    }

    @ViewBuilder
    private func plotContents(n: Night, s: CGFloat) -> some View {
        ZStack {
            // The dashed rule for this night.
            Path { p in
                p.move(to: CGPoint(x: 0, y: (1 - CGFloat(n.yA)) * s))
                p.addLine(to: CGPoint(x: s, y: (1 - CGFloat(n.yB)) * s))
            }
            .stroke(inkColor.opacity(0.85),
                    style: StrokeStyle(lineWidth: 1.3, dash: [3, 2]))

            ForEach(Self.dots.indices, id: \.self) { idx in
                let d = Self.dots[idx]
                ZStack {
                    if n.wrong.contains(idx) {
                        Circle()
                            .stroke(amberAccent, lineWidth: 1.5)
                            .frame(width: 11, height: 11)
                    }
                    Circle()
                        .fill(d.teal ? tealAccent : Color(hex: "c2557a"))
                        .frame(width: 5, height: 5)
                }
                .position(x: CGFloat(d.x) * s,
                          y: (1 - CGFloat(d.y)) * s)
            }
        }
    }
}

// MARK: - WallTypographicMoment
//
// Editorial hero for the "wall" card. Big serif words stacked vertically:
// ONE / STRAIGHT / LINE. — the last word in teal — with a literal heavy
// horizontal rule beneath. The composition embodies the lesson: the
// bouncer's tool, and its hard ceiling, in one editorial gesture.

struct WallTypographicMoment: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            wordLine("ONE", tint: inkColor.opacity(0.92))
            wordLine("STRAIGHT", tint: inkColor.opacity(0.92))
            wordLine("LINE.", tint: tealAccent)
                .padding(.bottom, 8)
            Rectangle()
                .fill(inkColor.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 2)
        }
    }

    private func wordLine(_ s: String, tint: Color) -> some View {
        Text(s)
            .font(.system(size: 48, weight: .bold, design: .serif))
            .tracking(-1.5)
            .foregroundStyle(tint)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - PerceptronTimeline
//
// Editorial hero for the "what came next" card. A horizontal milestone
// strip: 1958 → 1969 → 1986 → today. Years above, dots threaded on a
// continuous line, names below. The first dot is accented to mark this
// paper as the origin.

struct PerceptronTimeline: View {
    private struct Milestone {
        let year: String
        let label: String
        let accent: Bool
    }

    private let milestones: [Milestone] = [
        Milestone(year: "1958", label: "Perceptron", accent: true),
        Milestone(year: "1969", label: "XOR wall", accent: false),
        Milestone(year: "1986", label: "Backprop", accent: false),
        Milestone(year: "today", label: "Every neural net", accent: false),
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
                Rectangle()
                    .fill(inkColor.opacity(0.35))
                    .frame(height: 1)
                HStack(spacing: 0) {
                    ForEach(milestones.indices, id: \.self) { i in
                        Circle()
                            .fill(milestones[i].accent
                                  ? tealAccent
                                  : inkColor.opacity(0.75))
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
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

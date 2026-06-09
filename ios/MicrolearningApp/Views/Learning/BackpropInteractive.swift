import SwiftUI

// MARK: - Backprop bespoke interactives
//
// Hand-built interactive diagrams for the backpropagation lesson. Where the
// perceptron lesson taught one neuron, this paper is about a *network* of
// them — so every visual here is a small multi-layer net, and the signature
// motion is the error travelling backward through it. Nothing generic.

// MARK: - Shared: a teal..rose blend
//
// The lesson reads error as rose and correctness as teal. This blends the
// two for decision-region shading and blame strength.

private func blendTealRose(_ t: Double) -> Color {
    // t = 0 -> rose (wrong), t = 1 -> teal (right).
    let c = min(max(t, 0), 1)
    let rose = (r: 0.76, g: 0.33, b: 0.48)   // c2557a
    let teal = (r: 0.10, g: 0.54, b: 0.54)   // 1a8a8a
    return Color(.sRGB,
                 red:   rose.r + (teal.r - rose.r) * c,
                 green: rose.g + (teal.g - rose.g) * c,
                 blue:  rose.b + (teal.b - rose.b) * c,
                 opacity: 1)
}

// MARK: - BackpropNetworkGlyph (cover hero)
//
// A 2-3-1 network on the dark cover. A pulse runs forward (amber, left to
// right), the output flashes its mistake, then a pulse runs backward (rose,
// right to left) — the one motion this whole paper is about. Loops forever.

struct BackpropNetworkGlyph: View {
    @State private var phase: Double = 0   // 0..1 forward, 1..2 backward

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cols = [0.16, 0.5, 0.84].map { $0 * w }
            let inY  = [0.34, 0.66].map { $0 * h }
            let hidY = [0.22, 0.5, 0.78].map { $0 * h }
            let outY = 0.5 * h

            let inputs  = inY.map  { CGPoint(x: cols[0], y: $0) }
            let hiddens = hidY.map { CGPoint(x: cols[1], y: $0) }
            let output  = CGPoint(x: cols[2], y: outY)

            // Pulse x-position and colour, derived from phase.
            let goingBack = phase > 1
            let p = goingBack ? (2 - phase) : phase           // 1 -> 0 .. when back
            let pulseX = cols[0] + (cols[2] - cols[0]) * p
            let pulseColor = goingBack ? Color(hex: "d96b8a") : amberAccent

            ZStack {
                // edges: every input to every hidden, every hidden to output
                ForEach(0..<inputs.count, id: \.self) { i in
                    ForEach(0..<hiddens.count, id: \.self) { j in
                        line(inputs[i], hiddens[j]).stroke(ink.opacity(0.18), lineWidth: 1)
                    }
                }
                ForEach(0..<hiddens.count, id: \.self) { j in
                    line(hiddens[j], output).stroke(ink.opacity(0.22), lineWidth: 1.2)
                }

                // nodes
                ForEach(0..<inputs.count, id: \.self) { i in
                    Circle().fill(ink.opacity(0.5)).frame(width: 14, height: 14)
                        .position(inputs[i])
                }
                ForEach(0..<hiddens.count, id: \.self) { j in
                    Circle().fill(tealMid.opacity(0.85)).frame(width: 20, height: 20)
                        .overlay(Circle().stroke(ink.opacity(0.7), lineWidth: 1.5)
                            .frame(width: 20, height: 20))
                        .position(hiddens[j])
                }
                // output flashes rose at the moment the pulse turns around
                Circle()
                    .fill(phase > 0.92 && phase < 1.18 ? Color(hex: "d96b8a") : tealAccent)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(ink.opacity(0.85), lineWidth: 2)
                        .frame(width: 30, height: 30))
                    .position(output)

                // travelling pulse
                Circle()
                    .fill(pulseColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: pulseColor.opacity(0.7), radius: 6)
                    .position(x: pulseX, y: outY + (goingBack ? -0 : 0))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                phase = 2
            }
        }
    }

    private func line(_ a: CGPoint, _ b: CGPoint) -> Path {
        Path { p in p.move(to: a); p.addLine(to: b) }
    }
}

// MARK: - StackedCutsArt (illustrated hero)
//
// Editorial illustration for the "a line of cooks" card. A front row of small
// straight cuts feeds a single combining node, and the combined result is a
// closed curved region — the picture of why stacking neurons can carve a shape
// one line never could.

struct StackedCutsArt: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                // left: three little straight-line tiles
                ForEach(0..<3, id: \.self) { i in
                    let cy = h * (0.22 + 0.28 * Double(i))
                    lineTile()
                        .frame(width: w * 0.22, height: w * 0.22)
                        .position(x: w * 0.16, y: cy)
                    // connector to the combiner
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.27, y: cy))
                        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
                    }
                    .stroke(inkColor.opacity(0.22), lineWidth: 1.4)
                }
                // centre: the combiner node
                Circle()
                    .fill(tealAccent)
                    .frame(width: 34, height: 34)
                    .overlay(Image(systemName: "plus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white))
                    .position(x: w * 0.5, y: h * 0.5)
                // connector to the result
                Path { p in
                    p.move(to: CGPoint(x: w * 0.54, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))
                }
                .stroke(tealAccent.opacity(0.5), lineWidth: 2)
                // right: the carved region
                curveTile()
                    .frame(width: w * 0.26, height: w * 0.26)
                    .position(x: w * 0.85, y: h * 0.5)

                Text("straight cuts")
                    .font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText)
                    .position(x: w * 0.16, y: h * 0.96)
                Text("a real shape")
                    .font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText)
                    .position(x: w * 0.85, y: h * 0.96)
            }
        }
    }

    private func lineTile() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor.opacity(0.7), lineWidth: 0.8))
            GeometryReader { t in
                Path { p in
                    p.move(to: CGPoint(x: 0, y: t.size.height * 0.74))
                    p.addLine(to: CGPoint(x: t.size.width, y: t.size.height * 0.26))
                }
                .stroke(inkColor.opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.6, dash: [3, 2]))
            }
        }
    }

    private func curveTile() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor.opacity(0.7), lineWidth: 0.8))
            GeometryReader { t in
                let s = min(t.size.width, t.size.height)
                // a soft blob: the region a stack of cuts can enclose
                Path { p in
                    p.addEllipse(in: CGRect(x: s * 0.2, y: s * 0.24,
                                            width: s * 0.6, height: s * 0.52))
                }
                .fill(tealAccent.opacity(0.22))
                Path { p in
                    p.addEllipse(in: CGRect(x: s * 0.2, y: s * 0.24,
                                            width: s * 0.6, height: s * 0.52))
                }
                .stroke(tealAccent, style: StrokeStyle(lineWidth: 1.8))
            }
        }
    }
}

// MARK: - BackpropBlameFlow (interactive 1)
//
// The heart of the paper, made tactile. A real 2-2-1 network with honest
// arithmetic. Each tap runs one learning round: the signal flows forward to
// a guess, the gap to the target is measured, the error flows backward and
// every connection lights up with its exact share of the blame, then the
// weights nudge. The gap bar shrinks round by round. Unlocks once the
// network's guess has all but caught the target.

struct BackpropBlameFlow: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    // A fixed tiny problem. Identity activations keep every number on screen
    // an exact, checkable forward/backward computation.
    private let x: [Double] = [1.0, 0.7]      // two inputs, held constant
    private let target = 0.80
    private let lr = 0.42

    @State private var w: [[Double]] = [[0.10, 0.20], [0.15, 0.05]] // input i -> hidden j
    @State private var v: [Double]   = [0.30, 0.25]                 // hidden j -> output
    @State private var round = 0
    @State private var phase: Phase = .idle

    private enum Phase { case idle, forward, backward }

    // forward pass
    private var h: [Double] { (0..<2).map { j in x[0] * w[0][j] + x[1] * w[1][j] } }
    private var y: Double { h[0] * v[0] + h[1] * v[1] }
    private var error: Double { y - target }     // signed gap

    // backward pass — the chain rule, written out
    private var gradV: [Double] { (0..<2).map { j in error * h[j] } }
    private var gradH: [Double] { (0..<2).map { j in error * v[j] } }
    private var gradW: [[Double]] {
        (0..<2).map { i in (0..<2).map { j in gradH[j] * x[i] } }
    }
    private var maxBlame: Double {
        max(gradW.flatMap { $0 }.map(abs).max() ?? 0,
            gradV.map(abs).max() ?? 0, 0.0001)
    }

    private let startGap = 0.68
    private var solved: Bool { abs(error) < 0.05 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("WATCH THE BLAME TRAVEL")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("This little network guesses, then learns. Each round: the signal runs forward to a guess, the gap flows back, and every wire takes its share of the fix.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            netPlot
            gapBar
            statusRow
            runButton
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: network plot

    private var netPlot: some View {
        GeometryReader { g in
            let w0 = g.size.width, h0 = g.size.height
            let colX = [0.13, 0.52, 0.88].map { $0 * w0 }
            let inP  = [0.30, 0.70].map { CGPoint(x: colX[0], y: $0 * h0) }
            let hidP = [0.30, 0.70].map { CGPoint(x: colX[1], y: $0 * h0) }
            let outP = CGPoint(x: colX[2], y: 0.5 * h0)

            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))

                // input -> hidden edges
                ForEach(0..<2, id: \.self) { i in
                    ForEach(0..<2, id: \.self) { j in
                        edge(from: inP[i], to: hidP[j], blame: abs(gradW[i][j]))
                    }
                }
                // hidden -> output edges
                ForEach(0..<2, id: \.self) { j in
                    edge(from: hidP[j], to: outP, blame: abs(gradV[j]))
                }

                // nodes
                ForEach(0..<2, id: \.self) { i in node(inP[i], r: 13, fill: inkColor.opacity(0.5)) }
                ForEach(0..<2, id: \.self) { j in
                    node(hidP[j], r: 19, fill: tealMid,
                         ring: phase == .backward ? Color(hex: "d96b8a") : .clear)
                }
                node(outP, r: 25,
                     fill: solved ? tealAccent : Color(hex: "d96b8a"),
                     ring: phase == .forward ? amberAccent : .clear)

                // output value
                Text(String(format: "%.2f", y))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .position(outP)

                // labels
                Text("inputs").font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText).position(x: colX[0], y: h0 * 0.95)
                Text("hidden").font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText).position(x: colX[1], y: h0 * 0.95)
                Text("guess").font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText).position(x: colX[2], y: h0 * 0.95)
            }
        }
        .frame(height: 218)
    }

    private func edge(from a: CGPoint, to b: CGPoint, blame: Double) -> some View {
        let lit: Color
        let width: CGFloat
        switch phase {
        case .idle:
            lit = inkColor.opacity(0.16); width = 1.2
        case .forward:
            lit = tealAccent.opacity(0.8); width = 2.2
        case .backward:
            // thickness carries the blame share — the chain rule, visible
            lit = Color(hex: "d96b8a")
            width = 1.5 + 5.5 * CGFloat(blame / maxBlame)
        }
        return Path { p in p.move(to: a); p.addLine(to: b) }
            .stroke(lit, lineWidth: width)
            .animation(.easeInOut(duration: 0.4), value: phase)
    }

    private func node(_ c: CGPoint, r: CGFloat, fill: Color, ring: Color = .clear) -> some View {
        Circle()
            .fill(fill)
            .frame(width: r * 2, height: r * 2)
            .overlay(Circle().stroke(ring, lineWidth: 3).frame(width: r * 2 + 6, height: r * 2 + 6))
            .position(c)
            .animation(.easeInOut(duration: 0.3), value: phase)
    }

    // MARK: gap bar

    private var gapBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("GAP TO THE RIGHT ANSWER")
                .font(.system(size: 10, weight: .bold)).tracking(1.6)
                .foregroundStyle(mutedText)
            GeometryReader { geo in
                let frac = min(1, abs(error) / startGap)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(inkColor.opacity(0.06))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(solved ? tealAccent : Color(hex: "d96b8a"))
                        .frame(width: max(3, geo.size.width * frac))
                }
            }
            .frame(height: 22)
            .animation(.snappy(duration: 0.4), value: error)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(solved ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(solved
                 ? "The guess matches the answer. The network learned it."
                 : "Round \(round) · guess \(String(format: "%.2f", y)), wants \(String(format: "%.2f", target))")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
        }
    }

    // MARK: run button

    private var runButton: some View {
        Button { runRound() } label: {
            Text(solved ? "It learned the answer ✓" : "Run a learning round")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(solved ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(solved ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(solved || phase != .idle)
    }

    /// One round: forward highlight, backward highlight, then the nudge.
    /// Staged with short delays so the reader sees the two passes as two
    /// distinct events rather than one flash.
    private func runRound() {
        guard phase == .idle, !solved else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        withAnimation(.easeInOut(duration: 0.35)) { phase = .forward }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeInOut(duration: 0.35)) { phase = .backward }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            // gradient-descent step — the blame becomes a weight change
            withAnimation(.snappy(duration: 0.45)) {
                for i in 0..<2 { for j in 0..<2 { w[i][j] -= lr * gradW[i][j] } }
                for j in 0..<2 { v[j] -= lr * gradV[j] }
                phase = .idle
            }
            round += 1
            if solved || round >= 7 {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - GradientDescentValley (interactive 2)
//
// Gradient descent, made physical. The error is a valley; the network sits
// on one wall. Each step moves it downhill by an amount the reader controls
// with the step-size dial. Too small and it crawls; too large and it
// overshoots, bouncing wall to wall, even climbing out. Unlocks once the
// reader has steered it to rest at the bottom.

struct GradientDescentValley: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    // valley: f(p) = 0.5 * p^2 over p in [-1, 1]; slope f'(p) = p.
    // step: p -= lr * p. Converges for lr in (0,2), oscillates in (1,2).
    @State private var p: Double = -0.85
    @State private var trail: [Double] = []
    @State private var rate: Double = 0.18      // slider value 0...1
    @State private var steps = 0

    private var lr: Double { rate * 2.6 }       // mapped step size
    private var settled: Bool { abs(p) < 0.045 }
    private var diverged: Bool { abs(p) > 1.25 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("FIND THE BOTTOM")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The error is a valley. Each weight rolls downhill, one step at a time. Set how big a step to take, then push it along.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            valleyPlot
            rateRow
            statusRow
            buttonRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: valley plot

    private var valleyPlot: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))

                // the valley curve
                valleyPath(w: w, h: h)
                    .stroke(inkColor.opacity(0.7), lineWidth: 2.5)

                // bottom marker
                Circle().fill(tealAccent.opacity(0.25))
                    .frame(width: 16, height: 16)
                    .position(x: screenX(0, w), y: screenY(0, h))
                Text("the answer")
                    .font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(tealAccent)
                    .position(x: screenX(0, w), y: screenY(0, h) + 24)

                // trail of past positions
                ForEach(trail.indices, id: \.self) { i in
                    Circle().fill(amberAccent.opacity(0.28))
                        .frame(width: 7, height: 7)
                        .position(x: screenX(trail[i], w),
                                  y: screenY(curve(trail[i]), h))
                }

                // the rolling ball
                Circle()
                    .fill(settled ? tealAccent : amberAccent)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(.white, lineWidth: 2).frame(width: 22, height: 22))
                    .shadow(color: inkColor.opacity(0.18), radius: 3, y: 1)
                    .position(x: screenX(clampX(p), w),
                              y: screenY(curve(clampX(p)), h) - 12)
                    .animation(.snappy(duration: 0.4), value: p)
            }
        }
        .frame(height: 200)
    }

    private func curve(_ x: Double) -> Double { 0.5 * x * x }   // f(p)
    private func clampX(_ x: Double) -> Double { min(max(x, -1.15), 1.15) }

    private func screenX(_ x: Double, _ w: CGFloat) -> CGFloat {
        let pad: CGFloat = 26
        return pad + CGFloat((x + 1.2) / 2.4) * (w - 2 * pad)
    }
    private func screenY(_ f: Double, _ h: CGFloat) -> CGFloat {
        let topPad: CGFloat = 26, floor: CGFloat = h - 40
        // f ranges 0...~0.72; map to wall height
        return floor - CGFloat(f / 0.72) * (floor - topPad)
    }

    private func valleyPath(w: CGFloat, h: CGFloat) -> Path {
        Path { p in
            var first = true
            var x = -1.2
            while x <= 1.2001 {
                let pt = CGPoint(x: screenX(x, w), y: screenY(curve(x), h))
                if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
                x += 0.06
            }
        }
    }

    // MARK: step-size dial

    private var rateRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("STEP SIZE")
                    .font(.system(size: 10, weight: .bold)).tracking(1.6)
                    .foregroundStyle(mutedText)
                Spacer()
                Text(String(format: "%.2f", lr))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(rateTint)
            }
            WeightSlider(value: $rate, tint: rateTint)
        }
    }

    private var rateTint: Color {
        if lr > 2.0 { return Color(hex: "d96b8a") }   // diverges
        if lr < 0.25 { return amberAccent }            // crawls
        return tealAccent
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(statusColor).frame(width: 9, height: 9)
            Text(statusText)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusColor: Color {
        if settled { return tealAccent }
        if diverged { return Color(hex: "d96b8a") }
        return amberAccent
    }
    private var statusText: String {
        if settled { return "Rested at the bottom. The error is as low as it goes." }
        if diverged { return "It overshot and climbed out. The step was too big." }
        if lr < 0.25 { return "Barely moving. A tiny step takes forever to arrive." }
        return "Step \(steps) · still on the slope. Keep going, or retune the step."
    }

    // MARK: buttons

    private var buttonRow: some View {
        HStack(spacing: 10) {
            Button { reset() } label: {
                Text("Reset")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(inkColor.opacity(0.7))
                    .frame(maxWidth: 96, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { step() } label: {
                Text(settled ? "It found the bottom ✓" : "Take a step downhill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(settled ? tealAccent : .white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(settled ? tealAccent.opacity(0.12) : inkColor))
            }
            .buttonStyle(.plain)
            .disabled(settled)
        }
    }

    private func step() {
        guard !settled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        trail.append(p)
        if trail.count > 12 { trail.removeFirst() }
        withAnimation(.snappy(duration: 0.4)) {
            p -= lr * p                       // gradient-descent step
        }
        steps += 1
        if abs(p) < 0.045 || steps >= 9 {
            progress.markExplored(cardId)
            if abs(p) < 0.045 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func reset() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.35)) {
            p = -0.85; trail = []
        }
        steps = 0
    }
}

// MARK: - XORBreakthrough (interactive 3)
//
// The payoff, and a direct callback to the perceptron lesson's XOR wall. A
// real 2-3-1 network trains live on the four XOR points with honest
// backprop. Each tap runs a burst of learning; the decision regions bend
// from a useless straight split into the curved pattern XOR demands, and the
// loss bar drops. Unlocks once the wall is clearly broken.

struct XORBreakthrough: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    // The four XOR points: opposite corners share a class.
    private let data: [(x0: Double, x1: Double, t: Double)] = [
        (0, 0, 0), (0, 1, 1), (1, 0, 1), (1, 1, 0),
    ]
    private let lr = 0.5
    private let momentum = 0.7
    private let epochsPerTap = 400

    // Hand-picked asymmetric init — small, off-symmetry, reliably trainable.
    @State private var w1: [[Double]] = [[ 0.7, -0.6,  0.3],
                                         [-0.5,  0.8, -0.9]]   // input i -> hidden j
    @State private var b1: [Double] = [ 0.1, -0.3,  0.2]
    @State private var w2: [Double] = [ 0.9, -1.1,  0.6]       // hidden j -> output
    @State private var b2: Double = -0.2
    // momentum velocities
    @State private var vW1: [[Double]] = [[0,0,0],[0,0,0]]
    @State private var vB1: [Double] = [0,0,0]
    @State private var vW2: [Double] = [0,0,0]
    @State private var vB2: Double = 0

    @State private var epochs = 0
    @State private var taps = 0
    @State private var loss: Double = 1

    private var solved: Bool { loss < 0.04 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("BRING DOWN THE WALL")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The last lesson ended on a puzzle one neuron could never solve. This is the same four dots, given a hidden layer and trained by backprop. Push it, and watch the impossible split appear.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            regionPlot
            lossBar
            statusRow
            trainButton
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { loss = currentLoss() }
    }

    // MARK: decision-region plot

    private var regionPlot: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))

                Canvas { ctx, size in
                    let grid = 20
                    let cell = size.width / CGFloat(grid)
                    for gx in 0..<grid {
                        for gy in 0..<grid {
                            let inX = Double(gx) / Double(grid - 1)
                            // screen y is top-down; flip so input space reads
                            // bottom-left origin
                            let inY = 1 - Double(gy) / Double(grid - 1)
                            let o = forward(inX, inY).o
                            let rect = CGRect(x: CGFloat(gx) * cell,
                                              y: CGFloat(gy) * cell,
                                              width: cell + 0.6, height: cell + 0.6)
                            ctx.fill(Path(rect),
                                     with: .color(blendTealRose(o).opacity(0.55)))
                        }
                    }
                }
                .frame(width: s, height: s)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // the four XOR dots
                ForEach(0..<4, id: \.self) { i in
                    let d = data[i]
                    Circle()
                        .fill(d.t > 0.5 ? tealAccent : Color(hex: "c2557a"))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 2.5)
                            .frame(width: 20, height: 20))
                        .position(x: dotPos(d.x0, d.x1, s).x,
                                  y: dotPos(d.x0, d.x1, s).y)
                }
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 232)
    }

    private func dotPos(_ x0: Double, _ x1: Double, _ s: CGFloat) -> CGPoint {
        let pad: CGFloat = 30
        let span = s - 2 * pad
        return CGPoint(x: pad + CGFloat(x0) * span,
                       y: pad + CGFloat(1 - x1) * span)
    }

    // MARK: loss bar

    private var lossBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HOW WRONG THE NETWORK STILL IS")
                .font(.system(size: 10, weight: .bold)).tracking(1.6)
                .foregroundStyle(mutedText)
            GeometryReader { geo in
                let frac = min(1, loss / 0.5)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(inkColor.opacity(0.06))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(solved ? tealAccent : Color(hex: "d96b8a"))
                        .frame(width: max(3, geo.size.width * frac))
                }
            }
            .frame(height: 22)
            .animation(.snappy(duration: 0.4), value: loss)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(solved ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(solved
                 ? "Two curved regions. The wall a single line could not cross is gone."
                 : (taps == 0
                    ? "One flat guess for everything. No line, no curve, just wrong."
                    : "\(epochs) rounds of backprop · the regions are bending into shape"))
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var trainButton: some View {
        Button { train() } label: {
            Text(solved ? "The wall is down ✓" : "Train it on the four dots")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(solved ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(solved ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(solved)
    }

    // MARK: network maths

    private func sig(_ z: Double) -> Double { 1 / (1 + exp(-z)) }

    private func forward(_ in0: Double, _ in1: Double) -> (h: [Double], o: Double) {
        var h = [Double](repeating: 0, count: 3)
        for j in 0..<3 {
            let z = b1[j] + w1[0][j] * in0 + w1[1][j] * in1
            h[j] = sig(z)
        }
        var z2 = b2
        for j in 0..<3 { z2 += w2[j] * h[j] }
        return (h, sig(z2))
    }

    private func currentLoss() -> Double {
        var sum = 0.0
        for d in data {
            let o = forward(d.x0, d.x1).o
            sum += 0.5 * (o - d.t) * (o - d.t)
        }
        return sum / Double(data.count)
    }

    /// One burst of honest full-batch backprop with momentum.
    private func train() {
        guard !solved else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        for _ in 0..<epochsPerTap {
            var gW1 = [[Double]](repeating: [0,0,0], count: 2)
            var gB1 = [Double](repeating: 0, count: 3)
            var gW2 = [Double](repeating: 0, count: 3)
            var gB2 = 0.0

            for d in data {
                let (h, o) = forward(d.x0, d.x1)
                // output delta (MSE + sigmoid)
                let dO = (o - d.t) * o * (1 - o)
                for j in 0..<3 { gW2[j] += dO * h[j] }
                gB2 += dO
                // hidden deltas
                for j in 0..<3 {
                    let dH = dO * w2[j] * h[j] * (1 - h[j])
                    gW1[0][j] += dH * d.x0
                    gW1[1][j] += dH * d.x1
                    gB1[j]    += dH
                }
            }
            let n = Double(data.count)
            // momentum-smoothed gradient-descent update
            for j in 0..<3 {
                vW2[j] = momentum * vW2[j] - lr * gW2[j] / n
                w2[j] += vW2[j]
                for i in 0..<2 {
                    vW1[i][j] = momentum * vW1[i][j] - lr * gW1[i][j] / n
                    w1[i][j] += vW1[i][j]
                }
                vB1[j] = momentum * vB1[j] - lr * gB1[j] / n
                b1[j] += vB1[j]
            }
            vB2 = momentum * vB2 - lr * gB2 / n
            b2 += vB2
        }

        epochs += epochsPerTap
        taps += 1
        withAnimation(.easeInOut(duration: 0.5)) { loss = currentLoss() }

        if solved || taps >= 6 {
            progress.markExplored(cardId)
            if solved { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }
}

// MARK: - FeatureGridArt (illustrated hero)
//
// Editorial illustration for the "learning representations" card. Three small
// tiles, each a pattern a hidden unit might invent on its own — an edge, a
// corner, a centre blob. The point of the paper's title in one picture: the
// network writes its own vocabulary.

struct FeatureGridArt: View {
    private enum Kind { case edge, corner, blob }
    private let tiles: [(Kind, String)] = [
        (.edge, "an edge"), (.corner, "a corner"), (.blob, "a centre"),
    ]

    var body: some View {
        HStack(spacing: 14) {
            ForEach(tiles.indices, id: \.self) { i in
                VStack(spacing: 8) {
                    tile(tiles[i].0)
                        .frame(width: 64, height: 64)
                    Text(tiles[i].1)
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .foregroundStyle(mutedText)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func tile(_ k: Kind) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1))
            GeometryReader { g in
                let s = min(g.size.width, g.size.height)
                switch k {
                case .edge:
                    Path { p in
                        p.addRect(CGRect(x: 0, y: 0, width: s * 0.5, height: s))
                    }.fill(tealAccent.opacity(0.55))
                case .corner:
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: s))
                        p.addLine(to: CGPoint(x: 0, y: s * 0.45))
                        p.addLine(to: CGPoint(x: s * 0.55, y: s))
                        p.closeSubpath()
                    }.fill(tealAccent.opacity(0.55))
                case .blob:
                    Circle()
                        .fill(tealAccent.opacity(0.55))
                        .frame(width: s * 0.56, height: s * 0.56)
                        .position(x: s / 2, y: s / 2)
                }
            }
            .padding(7)
        }
    }
}

// MARK: - BackpropTimeline (prose hero)
//
// Editorial milestone strip for the "what came next" card. The 1969 wall,
// the 1986 fix, and the run of breakthroughs it unlocked. Backprop's date is
// accented as the hinge of the story.

struct BackpropTimeline: View {
    private struct Milestone { let year: String; let label: String; let accent: Bool }

    private let milestones: [Milestone] = [
        Milestone(year: "1969", label: "XOR wall", accent: false),
        Milestone(year: "1986", label: "Backprop", accent: true),
        Milestone(year: "2012", label: "AlexNet", accent: false),
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
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

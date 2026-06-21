import SwiftUI

// MARK: - Premium interactive cards for "The Perceptron: A Probabilistic
//                                       Model for Information Storage and
//                                       Organization in the Brain"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for
// Rosenblatt's perceptron paper. Design language mirrors the AlexNet / Word2Vec
// studios: cream prompt panels, teal accent, serif headlines, monospaced
// data, faint amber strips.
//
//   Card 04, PerceptronBoundaryView
//      "Watch a line learn." Tap STEP. The perceptron picks one
//      misclassified point and nudges its weight vector toward the right
//      answer. Five steps and the boundary lands in the gap.
//
//   Card 05, PerceptronXORView
//      "The wall it cannot cross." Toggle AND, OR, XOR. The first two
//      converge in a handful of epochs. XOR loops forever, no straight line
//      separates the four corners.
//
//   Card 06, PerceptronAnatomyView
//      "Five parts of a neuron." Tap each piece, inputs, weights, sum,
//      threshold, output, to read what it does. The whole thing is one
//      decision, repeated.

// MARK: - Local design tokens (mirrors AlexNet studio)

private let pcInk        = inkColor
private let pcInkSubtle  = inkColor.opacity(0.65)
private let pcPanelBg    = Color(hex: "f4ece0")
private let pcPanelEdge  = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Decision Boundary Learner
// =============================================================================

private struct PCPoint: Identifiable, Hashable {
    let id: Int
    let x: CGFloat   // -1...1 plot space
    let y: CGFloat
    let label: Int   // +1 / -1
}

// A linearly separable two-cluster dataset.
private let pcData: [PCPoint] = [
    PCPoint(id: 0, x: -0.65, y:  0.35, label: +1),
    PCPoint(id: 1, x: -0.40, y:  0.60, label: +1),
    PCPoint(id: 2, x: -0.20, y:  0.30, label: +1),
    PCPoint(id: 3, x: -0.55, y:  0.05, label: +1),
    PCPoint(id: 4, x:  0.50, y: -0.55, label: -1),
    PCPoint(id: 5, x:  0.30, y: -0.30, label: -1),
    PCPoint(id: 6, x:  0.65, y: -0.10, label: -1),
    PCPoint(id: 7, x:  0.20, y: -0.65, label: -1),
]

struct PerceptronBoundaryView: View {
    @ObservedObject var state: DailyLoopState
    @State private var w: SIMD2<Double> = SIMD2(0.40, -0.95)   // start tilted "wrong"
    @State private var b: Double = 0.05
    @State private var step: Int = 0
    @State private var lastTouched: Int? = nil
    @State private var converged: Bool = false

    private let lr: Double = 0.25
    private let maxSteps: Int = 6

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · A LINE THAT LEARNS")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Tap STEP. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(pcInk)
                + Text("Watch the line find the gap.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("The perceptron picks one misclassified point per step and nudges its weights: w ← w + η(y − ŷ)x. Six steps is enough on this dataset.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                plotPanel
                    .padding(.bottom, 12)

                DLActionHint(
                    text: "Tap STEP three times. Watch the line move.",
                    done: step >= 3
                )
                .padding(.bottom, 10)

                stepRow
                    .padding(.bottom, 14)

                weightsRow
                    .padding(.bottom, 14)

                Text(verdictLine)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(pcInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }

    // -- Logic --

    private func predict(_ p: PCPoint) -> Int {
        let z = w.x * Double(p.x) + w.y * Double(p.y) + b
        return z >= 0 ? +1 : -1
    }

    private var misclassified: [PCPoint] {
        pcData.filter { predict($0) != $0.label }
    }

    private func runOneStep() {
        guard step < maxSteps, let mis = misclassified.first else {
            converged = misclassified.isEmpty
            return
        }
        let target = Double(mis.label)
        let delta = lr * target
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            w.x += delta * Double(mis.x)
            w.y += delta * Double(mis.y)
            b   += delta
            step += 1
            lastTouched = mis.id
            converged = misclassified.isEmpty
            if step >= 3 { state.customCardComplete.insert(3) }
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func reset() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            w = SIMD2(0.40, -0.95)
            b = 0.05
            step = 0
            lastTouched = nil
            converged = false
        }
    }

    // -- View pieces --

    private var verdictLine: String {
        if step == 0 {
            return "Initial weights are random. Three points sit on the wrong side of the line. Tap STEP."
        }
        if converged {
            return "All eight points classified. The line found the margin in \(step) update\(step == 1 ? "" : "s")."
        }
        let bad = misclassified.count
        return "Step \(step). \(bad) point\(bad == 1 ? "" : "s") still on the wrong side."
    }

    private var plotPanel: some View {
        GeometryReader { geo in
            ZStack {
                // Plot must fit inside both the available width AND the fixed
                // 260pt panel height. The previous formula sized by width only
                // and let cy push past the frame on wider phones, so the points
                // and the boundary line spilled below the panel.
                let size = min(geo.size.width, geo.size.height - 24)
                let cx = geo.size.width / 2
                let cy = geo.size.height / 2

                // Card body
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(pcPanelEdge, lineWidth: 1))

                // Axes
                Path { p in
                    p.move(to: CGPoint(x: cx - size/2, y: cy)); p.addLine(to: CGPoint(x: cx + size/2, y: cy))
                    p.move(to: CGPoint(x: cx, y: cy - size/2)); p.addLine(to: CGPoint(x: cx, y: cy + size/2))
                }
                .stroke(pcPanelEdge, style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))

                // Decision boundary: w.x*x + w.y*y + b = 0
                boundaryPath(cx: cx, cy: cy, size: size)
                    .stroke(LinearGradient(colors: [tealAccent, tealAccent.opacity(0.4)], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))

                // Shaded half-planes (faint)
                halfPlanes(cx: cx, cy: cy, size: size)

                // Points
                ForEach(pcData) { p in
                    let predicted = predict(p)
                    let correct = predicted == p.label
                    let pos = CGPoint(x: cx + p.x * (size/2 - 18), y: cy - p.y * (size/2 - 18))
                    Circle()
                        .fill(p.label == 1 ? tealAccent : amberAccent)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(correct ? Color.white : Color(hex: "c0573c"),
                                            lineWidth: correct ? 1.6 : 2.2)
                        )
                        .scaleEffect(p.id == lastTouched ? 1.35 : 1.0)
                        .position(pos)
                        .motionAware(.spring(response: 0.4, dampingFraction: 0.7), value: lastTouched)
                }

                // Axis labels
                Text("x₁").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(pcInkSubtle.opacity(0.7))
                    .position(x: cx + size/2 - 8, y: cy + 12)
                Text("x₂").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(pcInkSubtle.opacity(0.7))
                    .position(x: cx + 12, y: cy - size/2 + 8)
            }
            // Clip any over-eager strokes (gradient boundary line, halfplane
            // grid) to the card so they can't peek above or beside it.
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(height: 260)
    }

    private func boundaryPath(cx: CGFloat, cy: CGFloat, size: CGFloat) -> Path {
        var p = Path()
        let half = size/2 - 18
        // Solve w.x*x + w.y*y + b = 0 → y = -(w.x*x + b)/w.y
        // Sample at the left and right edges of the plot, then walk the
        // segment in 0.02 steps and keep only the portion that lies inside
        // the [-1, +1]² plot square. This stops the boundary from exiting
        // the white card when the slope is steep, which previously read as
        // a graphical glitch.
        guard abs(w.y) > 1e-4 else { return p }
        let yAt: (Double) -> Double = { x in -(self.w.x * x + self.b) / self.w.y }

        let xMin = -1.0, xMax = 1.0
        let stride = 0.02
        var inside: [CGPoint] = []
        var x = xMin
        while x <= xMax + 1e-9 {
            let y = yAt(x)
            if y >= -1.0 && y <= 1.0 {
                inside.append(CGPoint(x: cx + CGFloat(x) * half, y: cy - CGFloat(y) * half))
            }
            x += stride
        }
        guard let first = inside.first, let last = inside.last else { return p }
        p.move(to: first)
        p.addLine(to: last)
        return p
    }

    @ViewBuilder
    private func halfPlanes(cx: CGFloat, cy: CGFloat, size: CGFloat) -> some View {
        let half = size/2 - 18
        // Sample a coarse grid; tint each cell by predicted side. Faint.
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                ForEach(0..<8, id: \.self) { j in
                    let xn = (Double(i) - 3.5) / 3.5
                    let yn = (Double(j) - 3.5) / 3.5
                    let z = w.x * xn + w.y * yn + b
                    Rectangle()
                        .fill(z >= 0 ? tealAccent.opacity(0.05) : amberAccent.opacity(0.05))
                        .frame(width: half * 2 / 8, height: half * 2 / 8)
                        .position(x: cx + CGFloat(xn) * half, y: cy - CGFloat(yn) * half)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var stepRow: some View {
        HStack(spacing: 10) {
            Button(action: runOneStep) {
                HStack(spacing: 6) {
                    Image(systemName: converged ? "checkmark" : "play.fill").font(scaledSystemFont(11, weight: .bold))
                    Text(converged ? "Converged" : "Step")
                        .font(scaledSystemFont(13, weight: .semibold, design: .serif))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(Capsule().fill(converged ? Color(hex: "4a9c4a") : tealAccent))
            }
            .buttonStyle(.plain)
            .disabled(converged)

            Button(action: reset) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise").font(scaledSystemFont(11, weight: .bold))
                    Text("Reset").font(scaledSystemFont(13, weight: .semibold, design: .serif))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundStyle(pcInk)
                .background(
                    Capsule().fill(Color.white)
                        .overlay(Capsule().stroke(pcPanelEdge, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("STEP \(step) / \(maxSteps)")
                .font(scaledSystemFont(9, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(pcInkSubtle.opacity(0.7))
        }
    }

    private var weightsRow: some View {
        HStack(spacing: 10) {
            weightChip("w₁", value: w.x, color: tealAccent)
            weightChip("w₂", value: w.y, color: amberAccent)
            weightChip("b",  value: b,   color: Color(hex: "7b4ba4"))
        }
    }

    private func weightChip(_ label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(scaledSystemFont(9, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(pcInkSubtle.opacity(0.7))
            Text(String(format: "%+.2f", value))
                .font(scaledSystemFont(16, weight: .semibold, design: .serif))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: value))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(pcPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Card 05, AND vs OR vs XOR
// =============================================================================

private enum PCBoolean: String, CaseIterable, Identifiable {
    case and, or, xor
    var id: String { rawValue }

    var name: String { rawValue.uppercased() }

    var truth: [(CGFloat, CGFloat, Int)] {
        switch self {
        case .and: return [(0,0,-1),(0,1,-1),(1,0,-1),(1,1,+1)]
        case .or:  return [(0,0,-1),(0,1,+1),(1,0,+1),(1,1,+1)]
        case .xor: return [(0,0,-1),(0,1,+1),(1,0,+1),(1,1,-1)]
        }
    }

    var separable: Bool { self != .xor }

    var verdict: String {
        switch self {
        case .and: return "AND. Linearly separable. Perceptron settles in 4 epochs. The line tilts to leave (1,1) alone on its side."
        case .or:  return "OR. Also separable. The boundary slides toward the origin so three of four corners pass."
        case .xor: return "XOR. No straight line separates the four corners. Minsky and Papert proved this in 1969 and the field went quiet for a decade."
        }
    }

    var convergeEpoch: Int? {
        switch self {
        case .and: return 4
        case .or:  return 3
        case .xor: return nil
        }
    }
}

struct PerceptronXORView: View {
    @ObservedObject var state: DailyLoopState
    @State private var problem: PCBoolean = .and
    @State private var visited: Set<PCBoolean> = [.and]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · THE WALL")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Two it can do. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(pcInk)
                + Text("One it cannot.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Toggle AND, OR, XOR. The first two finish in a handful of epochs. XOR oscillates forever, no straight line cuts off the diagonal pair.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                problemTabs
                    .padding(.bottom, 14)

                truthGrid
                    .padding(.bottom, 16)

                lossPanel
                    .padding(.bottom, 14)

                Text(problem.verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(pcInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
    }

    private func updateGate() {
        if visited.count >= PCBoolean.allCases.count {
            state.customCardComplete.insert(4)
        }
    }

    private var problemTabs: some View {
        HStack(spacing: 8) {
            ForEach(PCBoolean.allCases) { p in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        problem = p
                    }
                    visited.insert(p)
                    updateGate()
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Text(p.name)
                        .font(scaledSystemFont(12, weight: problem == p ? .semibold : .regular, design: .serif))
                        .foregroundStyle(problem == p ? .white : pcInkSubtle)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(problem == p ? (p.separable ? tealAccent : Color(hex: "c0573c")) : Color.white)
                                .overlay(Capsule().stroke(pcPanelEdge, lineWidth: problem == p ? 0 : 1))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var truthGrid: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, 240)
            let cx = geo.size.width / 2
            let cy = size / 2 + 8
            let half = size/2 - 24
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(pcPanelEdge, lineWidth: 1))

                // Axes labels at corners
                Group {
                    Text("0,0").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(pcInkSubtle.opacity(0.55))
                        .position(x: cx - half - 10, y: cy + half + 10)
                    Text("1,1").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(pcInkSubtle.opacity(0.55))
                        .position(x: cx + half + 10, y: cy - half - 10)
                }

                // Faint grid
                Path { p in
                    p.move(to: CGPoint(x: cx - half, y: cy - half))
                    p.addLine(to: CGPoint(x: cx + half, y: cy - half))
                    p.addLine(to: CGPoint(x: cx + half, y: cy + half))
                    p.addLine(to: CGPoint(x: cx - half, y: cy + half))
                    p.closeSubpath()
                }
                .stroke(pcPanelEdge, lineWidth: 0.8)

                // Decision line for separable cases
                if problem.separable {
                    decisionLine(cx: cx, cy: cy, half: half)
                        .stroke(LinearGradient(colors: [tealAccent, tealAccent.opacity(0.4)],
                                               startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round))
                } else {
                    // XOR: show two failed candidate lines crossed out
                    failedXORLines(cx: cx, cy: cy, half: half)
                }

                // Truth points
                ForEach(0..<problem.truth.count, id: \.self) { i in
                    let t = problem.truth[i]
                    let pos = CGPoint(x: cx - half + t.0 * 2 * half,
                                      y: cy + half - t.1 * 2 * half)
                    Circle()
                        .fill(t.2 == +1 ? tealAccent : amberAccent)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .position(pos)
                }
            }
        }
        .frame(height: 240)
    }

    private func decisionLine(cx: CGFloat, cy: CGFloat, half: CGFloat) -> Path {
        var p = Path()
        switch problem {
        case .and:
            // y = -x + 1.5, segment within unit square diagonal
            p.move(to: CGPoint(x: cx + half * 0.5, y: cy + half * 1.0))
            p.addLine(to: CGPoint(x: cx + half * 1.0, y: cy + half * 0.5))
        case .or:
            // y = -x + 0.5
            p.move(to: CGPoint(x: cx - half * 1.0, y: cy + half * 0.5))
            p.addLine(to: CGPoint(x: cx + half * 0.5, y: cy - half * 1.0))
        default: break
        }
        return p
    }

    private func failedXORLines(cx: CGFloat, cy: CGFloat, half: CGFloat) -> some View {
        ZStack {
            // Two crossed candidate lines, dashed, faded.
            Path { p in
                p.move(to: CGPoint(x: cx - half, y: cy - half * 0.2))
                p.addLine(to: CGPoint(x: cx + half, y: cy + half * 0.2))
            }
            .stroke(Color(hex: "c0573c").opacity(0.6),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 4]))
            Path { p in
                p.move(to: CGPoint(x: cx - half * 0.2, y: cy - half))
                p.addLine(to: CGPoint(x: cx + half * 0.2, y: cy + half))
            }
            .stroke(Color(hex: "c0573c").opacity(0.6),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 4]))
        }
    }

    private var lossPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LOSS PER EPOCH")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                if let e = problem.convergeEpoch {
                    Text("converged @ epoch \(e)")
                        .font(scaledSystemFont(9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "4a9c4a"))
                } else {
                    Text("does not converge")
                        .font(scaledSystemFont(9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "c0573c"))
                }
            }
            lossCurve
                .frame(height: 88)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(pcPanelEdge, lineWidth: 1))
        )
    }

    private var lossCurve: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let n = 24
            let pts: [Double] = (0..<n).map { i in
                let t = Double(i)
                switch problem {
                case .and: return max(0, 4 * exp(-t / 3.0) - 0.05) + 0.05 * sin(t)
                case .or:  return max(0, 4 * exp(-t / 2.5) - 0.05) + 0.05 * sin(t * 1.2)
                case .xor: return 1.6 + 0.7 * sin(t * 0.9) + 0.4 * sin(t * 1.7)
                }
            }
            let maxV = max(pts.max() ?? 1.0, 1.0)
            ZStack {
                Path { p in
                    for (i, v) in pts.enumerated() {
                        let x = CGFloat(i) / CGFloat(n - 1) * w
                        let y = h - CGFloat(v / maxV) * h * 0.9 - 4
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else      { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(problem.separable ? tealAccent : Color(hex: "c0573c"),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if let e = problem.convergeEpoch {
                    let x = CGFloat(e) / CGFloat(n - 1) * w
                    Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: h))
                    }
                    .stroke(Color(hex: "4a9c4a").opacity(0.35),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
        }
    }
}

// =============================================================================
// MARK: - Card 06, Anatomy of a Neuron
// =============================================================================

private enum PCPart: Int, CaseIterable, Identifiable {
    case input, weight, sum, threshold, output
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .input:     return "Inputs"
        case .weight:    return "Weights"
        case .sum:       return "Sum"
        case .threshold: return "Threshold"
        case .output:    return "Output"
        }
    }

    var symbol: String {
        switch self {
        case .input:     return "xᵢ"
        case .weight:    return "wᵢ"
        case .sum:       return "Σ"
        case .threshold: return "θ"
        case .output:    return "y"
        }
    }

    var role: String {
        switch self {
        case .input:
            return "Each xᵢ is one feature. Pixel intensity, sensor reading, a feature in a vector. The neuron sees the world through this list of numbers."
        case .weight:
            return "Each wᵢ is the importance assigned to xᵢ. Negative weights mean the feature argues against firing. Learning is just adjusting these weights."
        case .sum:
            return "Multiply pairwise, add them up: Σ wᵢxᵢ. One scalar that summarises everything the neuron has been told."
        case .threshold:
            return "If the sum crosses θ, fire. Otherwise, stay silent. The decision boundary is the hyperplane Σ wᵢxᵢ = θ."
        case .output:
            return "0 or 1. The neuron has voted. Stack thousands of these and you have a network. Rosenblatt built the first by hand on a 400-photocell grid."
        }
    }
}

struct PerceptronAnatomyView: View {
    @ObservedObject var state: DailyLoopState
    @State private var active: PCPart = .input
    @State private var visited: Set<PCPart> = [.input]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · ONE NEURON")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Five parts. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(pcInk)
                + Text("One vote.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap each piece. Inputs come in, get weighted, sum, cross a threshold. The neuron answers yes or no. Repeat that everywhere and you have a brain.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                neuronDiagram
                    .padding(.bottom, 18)

                Text(active.role)
                    .font(scaledSystemFont(13, design: .serif))
                    .foregroundStyle(pcInk)
                    .lineSpacing(4)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(pcPanelBg)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(pcPanelEdge, lineWidth: 1))
                    )
                    .padding(.bottom, 14)

                progressDots
                    .padding(.bottom, 14)

                Text(footerLine)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(pcInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
    }

    private func updateGate() {
        if visited.count >= PCPart.allCases.count {
            state.customCardComplete.insert(5)
        }
    }

    private var footerLine: String {
        if visited.count == PCPart.allCases.count {
            return "All five parts. Stack a few hundred neurons in layers and you have a deep network. Stack billions, and you have GPT."
        }
        return "Tap each piece. \(visited.count) of \(PCPart.allCases.count) explored."
    }

    private var neuronDiagram: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 220
            let cy = h / 2

            // Three input rows on the left
            let xLeft: CGFloat = 28
            let xWeight: CGFloat = w * 0.32
            let xSum: CGFloat = w * 0.55
            let xStep: CGFloat = w * 0.78
            let xOut: CGFloat = w - 28
            let inputYs: [CGFloat] = [cy - 60, cy, cy + 60]

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(pcPanelEdge, lineWidth: 1))

                // Edges
                ForEach(0..<3, id: \.self) { i in
                    Path { p in
                        p.move(to: CGPoint(x: xLeft + 18, y: inputYs[i]))
                        p.addLine(to: CGPoint(x: xWeight, y: inputYs[i]))
                    }
                    .stroke(active == .input || active == .weight ? tealAccent : pcPanelEdge,
                            lineWidth: 1.4)
                    Path { p in
                        p.move(to: CGPoint(x: xWeight + 22, y: inputYs[i]))
                        p.addLine(to: CGPoint(x: xSum - 18, y: cy))
                    }
                    .stroke(active == .weight || active == .sum ? tealAccent : pcPanelEdge,
                            lineWidth: 1.4)
                }
                Path { p in
                    p.move(to: CGPoint(x: xSum + 18, y: cy))
                    p.addLine(to: CGPoint(x: xStep - 18, y: cy))
                }
                .stroke(active == .sum || active == .threshold ? tealAccent : pcPanelEdge,
                        lineWidth: 1.6)
                Path { p in
                    p.move(to: CGPoint(x: xStep + 18, y: cy))
                    p.addLine(to: CGPoint(x: xOut - 14, y: cy))
                }
                .stroke(active == .threshold || active == .output ? tealAccent : pcPanelEdge,
                        lineWidth: 1.6)

                // Inputs
                ForEach(0..<3, id: \.self) { i in
                    partButton(label: "x\(["₁","₂","₃"][i])", part: .input)
                        .position(x: xLeft, y: inputYs[i])
                }
                // Weights
                ForEach(0..<3, id: \.self) { i in
                    partButton(label: "w\(["₁","₂","₃"][i])", part: .weight)
                        .position(x: xWeight, y: inputYs[i])
                }
                // Sum node
                partButton(label: "Σ", part: .sum, big: true)
                    .position(x: xSum, y: cy)
                // Threshold
                partButton(label: "≥θ", part: .threshold, big: true)
                    .position(x: xStep, y: cy)
                // Output
                partButton(label: "y", part: .output)
                    .position(x: xOut, y: cy)
            }
            .frame(height: h)
        }
        .frame(height: 220)
    }

    @ViewBuilder
    private func partButton(label: String, part: PCPart, big: Bool = false) -> some View {
        let isA = active == part
        let size: CGFloat = big ? 38 : 28
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                active = part
            }
            visited.insert(part)
            updateGate()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Text(label)
                .font(scaledSystemFont(big ? 14 : 11, weight: .bold, design: .serif))
                .foregroundStyle(isA ? .white : pcInk)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isA ? tealAccent : Color.white)
                        .overlay(Circle().stroke(isA ? tealAccent : pcPanelEdge, lineWidth: 1.4))
                )
        }
        .buttonStyle(.plain)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(PCPart.allCases) { p in
                let v = visited.contains(p)
                Circle()
                    .fill(v ? tealAccent : pcPanelEdge)
                    .frame(width: 6, height: 6)
            }
            Spacer()
            Text("\(visited.count) / \(PCPart.allCases.count)")
                .font(scaledSystemFont(9, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(pcInkSubtle.opacity(0.7))
        }
    }
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

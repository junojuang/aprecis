import SwiftUI

// MARK: - Premium interactive cards for "Generative Adversarial Nets"
//
// Three bespoke cards for the GAN paper. Each uses a distinct interaction
// mode so the deck never repeats itself.
//
//   Card 04, GANRoundView                — turn-based round simulator
//      "Forge. Detect. Repeat." Tap PLAY ROUND to advance the minimax game.
//      Two sample columns evolve, the fake's per-feature values converge
//      toward the real's. D's verdict pill flips from FAKE → REAL? → FOOLED.
//      G and D skill bars climb in arms-race fashion.
//
//   Card 05, GANConvergenceView          — training-curve scrubber
//      "D falls to ½. G has won." A 2D curve of D-accuracy over training
//      steps. Drag the cursor along the timeline; tap milestones (start,
//      near eq., Nash) to surface annotations. Live readouts in monospaced.
//
//   Card 06, GANModeCollapseView         — distribution scatter compare
//      "When G plays too safe." Toggle HEALTHY vs COLLAPSED. A 2D plot of
//      four real-data modes; G's samples scatter across all four (healthy)
//      or pile on one (collapsed). Per-mode coverage bars update. D's
//      verdict on both: PASSES, the punchline of the failure mode.

// MARK: - Local design tokens

private let ganInk        = inkColor
private let ganInkSubtle  = inkColor.opacity(0.65)
private let ganPanelBg    = Color(hex: "f4ece0")
private let ganPanelEdge  = Color(hex: "e2d8c6")
private let ganCorrect    = Color(hex: "1f7a4d")
private let ganWarn       = Color(hex: "b6502a")
private let ganViolet     = Color(hex: "6e4ea8")

// =============================================================================
// MARK: - Card 04, Round Simulator
// =============================================================================

private struct GANRound {
    let real: [Double]      // fixed across rounds
    let fakeAt: (Int) -> [Double]
    let dAccuracy: (Int) -> Double
    let totalRounds: Int = 8

    static let scenario: GANRound = {
        let real: [Double] = [0.42, 0.71, 0.18, 0.93, 0.55]
        // Fakes converge toward real with deterministic per-round noise.
        let randomStarts: [Double] = [0.91, 0.04, 0.66, 0.27, 0.84]
        return GANRound(
            real: real,
            fakeAt: { round in
                let t = max(0, min(1, Double(round) / 8.0))
                return zip(randomStarts, real).map { start, target in
                    start + (target - start) * t
                }
            },
            dAccuracy: { round in
                // Decays from 0.95 toward 0.50.
                let curve: [Double] = [0.95, 0.92, 0.86, 0.78, 0.70, 0.63, 0.57, 0.53, 0.50]
                return curve[max(0, min(curve.count - 1, round))]
            }
        )
    }()
}

struct GANRoundView: View {
    @ObservedObject var state: DailyLoopState
    @State private var round: Int = 0
    @State private var visited: Set<Int> = [0]
    @State private var autoPlaying: Bool = false
    private let scenario = GANRound.scenario

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · THE GAME")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Forge. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(ganInk)
                + Text("Detect. ").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)
                + Text("Repeat.").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(ganInk)

                Text("Tap PLAY to run a round. The forger paints, the detective inspects, both update. Watch fake features drift toward real and D's accuracy slide.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                roundHeader
                    .padding(.bottom, 14)

                samplePanel
                    .padding(.bottom, 14)

                skillsPanel
                    .padding(.bottom, 14)

                controls
                    .padding(.bottom, 14)

                Text(verdictForRound(round))
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(round >= 7 ? tealAccent : ganInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: round) { _, _ in
            visited.insert(round)
            updateGate()
        }
    }

    private func updateGate() {
        if round >= 5 || visited.contains(8) {
            state.customCardComplete.insert(3)
        }
    }

    private var roundHeader: some View {
        HStack {
            Text("ROUND")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(ganInkSubtle)
            Text("\(round) / \(scenario.totalRounds)")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(ganInk)
                .contentTransition(.numericText())
            Spacer()
            verdictPill
        }
    }

    private var verdictPill: some View {
        let acc = scenario.dAccuracy(round)
        let label: String
        let color: Color
        if acc > 0.85 {
            label = "FAKE"; color = ganWarn
        } else if acc > 0.60 {
            label = "REAL?"; color = amberAccent
        } else {
            label = "FOOLED"; color = ganCorrect
        }
        return HStack(spacing: 6) {
            Text("D =")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(ganInkSubtle)
            Text(String(format: "%.2f", acc))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(ganInk)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(color.opacity(0.10))
                .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.8))
        )
    }

    private var samplePanel: some View {
        let real = scenario.real
        let fake = scenario.fakeAt(round)
        return HStack(alignment: .top, spacing: 10) {
            sampleColumn(title: "REAL x", subtitle: "p_data", values: real, accent: tealAccent, refValues: real)
            sampleColumn(title: "FAKE G(z)", subtitle: "round \(round)", values: fake, accent: ganViolet, refValues: real)
        }
    }

    private func sampleColumn(title: String, subtitle: String, values: [Double], accent: Color, refValues: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(accent)
                Spacer()
                Text(subtitle)
                    .font(.system(size: 9, design: .serif))
                    .italic()
                    .foregroundStyle(ganInkSubtle)
            }
            VStack(spacing: 4) {
                ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                    let delta = abs(v - refValues[i])
                    HStack(spacing: 6) {
                        Text("f\(i)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ganInkSubtle.opacity(0.7))
                            .frame(width: 18, alignment: .leading)
                        Text(String(format: "%.2f", v))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ganInk)
                            .contentTransition(.numericText())
                        Spacer(minLength: 0)
                        // Match dot vs ref
                        Circle()
                            .fill(matchColor(delta))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ganPanelEdge, lineWidth: 1))
        )
    }

    private func matchColor(_ delta: Double) -> Color {
        if delta < 0.05 { return ganCorrect }
        if delta < 0.20 { return amberAccent }
        return ganWarn
    }

    private var skillsPanel: some View {
        let acc = scenario.dAccuracy(round)
        let gSkill = 1 - (acc - 0.5) / 0.5  // grows from ~0 to 1
        let dSkill = (acc - 0.5) / 0.5      // shrinks from 1 to 0 (advantage over chance)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ARMS RACE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
            }
            skillBar(label: "G · forger skill",
                     fraction: gSkill,
                     accent: ganViolet)
            skillBar(label: "D · edge over chance",
                     fraction: max(0.02, dSkill),
                     accent: amberAccent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ganPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ganPanelEdge, lineWidth: 1))
        )
    }

    private func skillBar(label: String, fraction: Double, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(ganInk)
                Spacer()
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.6), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: fraction)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button {
                step()
            } label: {
                Text(round >= scenario.totalRounds ? "AT NASH" : "PLAY ROUND")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(round >= scenario.totalRounds ? ganInkSubtle : tealAccent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(round >= scenario.totalRounds)

            Button {
                autoPlay()
            } label: {
                Text("AUTO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(ganInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ganPanelEdge, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                    round = 0
                }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                Text("RESET")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(ganInkSubtle)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ganPanelEdge, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func step() {
        guard round < scenario.totalRounds else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            round += 1
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func autoPlay() {
        guard !autoPlaying else { return }
        autoPlaying = true
        let stepsLeft = scenario.totalRounds - round
        guard stepsLeft > 0 else { autoPlaying = false; return }
        for i in 1...stepsLeft {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.32) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    round = min(scenario.totalRounds, round + 1)
                }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                if i == stepsLeft { autoPlaying = false }
            }
        }
    }

    private func verdictForRound(_ r: Int) -> String {
        switch r {
        case 0:    return "Round 0. G outputs noise. Every fake feature is far from real. D classifies perfectly."
        case 1...2: return "Early rounds. G picks up structure but features still drift. D wins easily."
        case 3...4: return "Half way. Fake features are getting close. D's confidence starts to crack."
        case 5...6: return "Late game. Most features are within margin. D is barely better than chance."
        case 7:    return "Near Nash. Fake features track real. D is at 53%, almost coin-flipping."
        default:   return "Nash equilibrium. p_G ≈ p_data. D = ½ everywhere. Stable, in theory; unstable in practice."
        }
    }
}

// =============================================================================
// MARK: - Card 05, Convergence Curve Scrubber
// =============================================================================

private struct GANCurvePoint: Identifiable {
    let id = UUID()
    let step: Double      // 0...160
    let accuracy: Double  // 0.5...1.0
    let label: String?    // optional milestone
    let annotation: String
}

private let convergenceCurve: [GANCurvePoint] = [
    GANCurvePoint(step: 0,   accuracy: 0.95, label: "start",
                  annotation: "Step 0. G outputs noise; D nails it. Accuracy ≈ 95%."),
    GANCurvePoint(step: 30,  accuracy: 0.85, label: nil,
                  annotation: "Step 30k. G has basic structure; D still wins but mistakes appear."),
    GANCurvePoint(step: 70,  accuracy: 0.70, label: nil,
                  annotation: "Step 70k. Fakes are crude but plausible. D is dropping fast."),
    GANCurvePoint(step: 120, accuracy: 0.55, label: "near eq.",
                  annotation: "Step 120k. Near equilibrium. D barely better than chance."),
    GANCurvePoint(step: 160, accuracy: 0.51, label: "Nash",
                  annotation: "Step 160k. Nash. p_G ≈ p_data. D ≈ ½ everywhere."),
]

struct GANConvergenceView: View {
    @ObservedObject var state: DailyLoopState
    @State private var step: Double = 0
    @State private var visited: Set<Int> = []
    @State private var auto: Bool = false

    private let totalSteps: Double = 160

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · CONVERGENCE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("D falls to ½. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(ganInk)
                + Text("G has won.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Drag the cursor across training. D-accuracy slides from near-perfect to chance. The slope is the only honest metric a GAN reports.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                curvePanel
                    .padding(.bottom, 14)

                readoutPanel
                    .padding(.bottom, 14)

                controls
                    .padding(.bottom, 14)

                Text(annotationFor(step: step))
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(currentAccuracy() < 0.55 ? tealAccent : ganInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: step) { _, _ in
            visited.insert(quartile(step))
            updateGate()
        }
    }

    private func quartile(_ s: Double) -> Int { min(3, max(0, Int(s / totalSteps * 4))) }

    private func updateGate() {
        if visited.count >= 3 || step >= totalSteps - 5 {
            state.customCardComplete.insert(4)
        }
    }

    private func currentAccuracy() -> Double {
        // Linear interpolate across milestone points.
        for i in 0..<(convergenceCurve.count - 1) {
            let a = convergenceCurve[i]
            let b = convergenceCurve[i + 1]
            if step >= a.step && step <= b.step {
                let t = (step - a.step) / max(1, b.step - a.step)
                return a.accuracy + (b.accuracy - a.accuracy) * t
            }
        }
        return convergenceCurve.last?.accuracy ?? 0.5
    }

    private func annotationFor(step: Double) -> String {
        let nearest = convergenceCurve.min(by: { abs($0.step - step) < abs($1.step - step) })
        return nearest?.annotation ?? ""
    }

    // MARK: Curve panel

    private var curvePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("D ACCURACY")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("STEP × 1k")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(ganInkSubtle)
            }

            ZStack {
                GeometryReader { geo in
                    let plotRect = CGRect(x: 30, y: 8, width: geo.size.width - 38, height: geo.size.height - 24)
                    yAxis(in: plotRect)
                    curvePath(in: plotRect)
                    milestoneDots(in: plotRect)
                    cursorLine(in: plotRect, totalWidth: geo.size.width)
                    xAxis(in: plotRect, totalWidth: geo.size.width)
                }
            }
            .frame(height: 170)

            scrubber
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ganPanelEdge, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func yAxis(in rect: CGRect) -> some View {
        let labels: [(Double, String)] = [(0.5, "0.5"), (0.75, "0.75"), (1.0, "1.0")]
        ForEach(labels, id: \.1) { val, txt in
            let y = rect.maxY - rect.height * CGFloat((val - 0.5) / 0.5)
            Path { p in
                p.move(to: CGPoint(x: rect.minX, y: y))
                p.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            .stroke(ganPanelEdge, style: StrokeStyle(lineWidth: 0.6, dash: [3, 4]))
            Text(txt)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(ganInkSubtle)
                .position(x: rect.minX - 14, y: y)
        }
    }

    @ViewBuilder
    private func xAxis(in rect: CGRect, totalWidth: CGFloat) -> some View {
        let stops: [(Double, String)] = [(0, "0"), (50, "50k"), (100, "100k"), (150, "150k")]
        ForEach(stops, id: \.1) { val, txt in
            let x = rect.minX + rect.width * CGFloat(val / totalSteps)
            Text(txt)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(ganInkSubtle)
                .position(x: x, y: rect.maxY + 12)
        }
    }

    @ViewBuilder
    private func curvePath(in rect: CGRect) -> some View {
        Path { p in
            let pts = convergenceCurve.map { pt -> CGPoint in
                let x = rect.minX + rect.width * CGFloat(pt.step / totalSteps)
                let y = rect.maxY - rect.height * CGFloat((pt.accuracy - 0.5) / 0.5)
                return CGPoint(x: x, y: y)
            }
            guard let first = pts.first else { return }
            p.move(to: first)
            for i in 1..<pts.count {
                let prev = pts[i - 1]
                let curr = pts[i]
                let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
                p.addQuadCurve(to: mid, control: prev)
                p.addQuadCurve(to: curr, control: CGPoint(x: (mid.x + curr.x) / 2, y: curr.y))
            }
        }
        .stroke(LinearGradient(colors: [tealAccent.opacity(0.5), tealAccent], startPoint: .topLeading, endPoint: .bottomTrailing),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

        // Half line marker (Nash floor)
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        .stroke(ganCorrect.opacity(0.5), style: StrokeStyle(lineWidth: 0.8, dash: [2, 3]))
    }

    @ViewBuilder
    private func milestoneDots(in rect: CGRect) -> some View {
        ForEach(convergenceCurve) { pt in
            if pt.label != nil {
                let x = rect.minX + rect.width * CGFloat(pt.step / totalSteps)
                let y = rect.maxY - rect.height * CGFloat((pt.accuracy - 0.5) / 0.5)
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                        step = pt.step
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                        Circle()
                            .stroke(tealAccent, lineWidth: 2)
                            .frame(width: 14, height: 14)
                    }
                }
                .buttonStyle(.plain)
                .position(x: x, y: y)

                if let label = pt.label {
                    Text(label.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(ganInkSubtle)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.white).overlay(Capsule().stroke(ganPanelEdge, lineWidth: 0.5)))
                        .position(x: x, y: y - 14)
                }
            }
        }
    }

    @ViewBuilder
    private func cursorLine(in rect: CGRect, totalWidth: CGFloat) -> some View {
        let cursorX = rect.minX + rect.width * CGFloat(step / totalSteps)
        let cursorY = rect.maxY - rect.height * CGFloat((currentAccuracy() - 0.5) / 0.5)
        Path { p in
            p.move(to: CGPoint(x: cursorX, y: rect.minY))
            p.addLine(to: CGPoint(x: cursorX, y: rect.maxY))
        }
        .stroke(ganInk.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        Circle()
            .fill(ganInk)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .frame(width: 12, height: 12)
            .position(x: cursorX, y: cursorY)
    }

    private var scrubber: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ganPanelBg)
                    .overlay(Capsule().stroke(ganPanelEdge, lineWidth: 0.8))
                    .frame(height: 5)
                Capsule()
                    .fill(LinearGradient(colors: [tealAccent.opacity(0.5), tealAccent], startPoint: .leading, endPoint: .trailing))
                    .frame(width: w * CGFloat(step / totalSteps), height: 5)
                Circle()
                    .fill(tealAccent)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .frame(width: 16, height: 16)
                    .offset(x: max(0, min(w - 16, w * CGFloat(step / totalSteps) - 8)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let f = max(0, min(1, v.location.x / w))
                                step = f * totalSteps
                            }
                    )
            }
        }
        .frame(height: 16)
    }

    private var readoutPanel: some View {
        HStack(spacing: 10) {
            chip(label: "STEP", value: "\(Int(step))k", accent: ganInk)
            chip(label: "D ACC",
                 value: String(format: "%.2f", currentAccuracy()),
                 accent: tealAccent)
            chip(label: "G WINS",
                 value: String(format: "%.0f%%", (1 - (currentAccuracy() - 0.5) / 0.5) * 100),
                 accent: ganViolet)
        }
    }

    private func chip(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(ganInkSubtle)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ganPanelEdge, lineWidth: 1))
        )
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button {
                playFromStart()
            } label: {
                Text("PLAY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent))
            }
            .buttonStyle(.plain)
            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { step = 0 }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                Text("RESET")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(ganInkSubtle)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ganPanelEdge, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func playFromStart() {
        guard !auto else { return }
        auto = true
        step = 0
        let frames = 60
        for i in 1...frames {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                withAnimation(.linear(duration: 0.04)) {
                    step = totalSteps * Double(i) / Double(frames)
                }
                if i == frames { auto = false; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
        }
    }
}

// =============================================================================
// MARK: - Card 06, Mode Collapse Compare
// =============================================================================

private struct GANMode: Identifiable {
    let id: Int
    let center: CGPoint   // unit square (0..1)
    let label: String
}

private let modes: [GANMode] = [
    GANMode(id: 0, center: CGPoint(x: 0.22, y: 0.30), label: "Mode 1"),
    GANMode(id: 1, center: CGPoint(x: 0.74, y: 0.28), label: "Mode 2"),
    GANMode(id: 2, center: CGPoint(x: 0.30, y: 0.78), label: "Mode 3"),
    GANMode(id: 3, center: CGPoint(x: 0.78, y: 0.74), label: "Mode 4"),
]

struct GANModeCollapseView: View {
    @ObservedObject var state: DailyLoopState
    @State private var collapsed: Bool = false
    @State private var visited: Set<Bool> = [false]
    @State private var seed: Int = 7

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · MODE COLLAPSE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("When G plays ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(ganInk)
                + Text("too safe.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("A healthy G covers every mode of the real distribution. A collapsed G locks onto one and stops exploring. D can't tell, both pass its check.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                modeToggle
                    .padding(.bottom, 14)

                scatterPanel
                    .padding(.bottom, 14)

                coverageBars
                    .padding(.bottom, 14)

                dPunchline
                    .padding(.bottom, 14)

                Text(verdict)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(collapsed ? ganWarn : tealAccent)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: collapsed) { _, _ in
            visited.insert(collapsed)
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= 2 {
            state.customCardComplete.insert(5)
        }
    }

    private var verdict: String {
        if collapsed {
            return "Collapsed. G has found one realistic output and stopped exploring. Three modes get zero coverage. The diversity loss is invisible to D."
        } else {
            return "Healthy. G's samples scatter across every cluster of the real distribution. Coverage is roughly proportional to mode mass."
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 8) {
            modeButton(title: "HEALTHY", isOn: !collapsed, accent: tealAccent) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { collapsed = false }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            modeButton(title: "COLLAPSED", isOn: collapsed, accent: ganWarn) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { collapsed = true }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            Button {
                seed = (seed * 1103515245 &+ 12345) & 0x7fffffff
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ganInkSubtle)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ganPanelEdge, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func modeButton(title: String, isOn: Bool, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isOn ? accent : Color.clear)
                    .overlay(Circle().stroke(isOn ? Color.clear : ganPanelEdge, lineWidth: 1))
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(isOn ? .white : ganInk.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn ? accent : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isOn ? Color.clear : ganPanelEdge, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Scatter

    private var scatterPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DISTRIBUTION SPACE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(ganInkSubtle.opacity(0.4)).frame(width: 6, height: 6)
                    Text("real")
                        .font(.system(size: 9, design: .serif))
                        .italic()
                        .foregroundStyle(ganInkSubtle)
                    Circle().fill(collapsed ? ganWarn : tealAccent).frame(width: 6, height: 6)
                    Text("G samples")
                        .font(.system(size: 9, design: .serif))
                        .italic()
                        .foregroundStyle(ganInkSubtle)
                }
            }

            GeometryReader { geo in
                let W = geo.size.width
                let H = geo.size.height
                ZStack {
                    // Real-mode clouds
                    ForEach(modes) { m in
                        Circle()
                            .fill(ganInkSubtle.opacity(0.10))
                            .frame(width: 64, height: 64)
                            .position(x: m.center.x * W, y: m.center.y * H)
                        Text(m.label)
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(ganInkSubtle)
                            .position(x: m.center.x * W, y: m.center.y * H + 28)
                    }
                    // G samples
                    ForEach(Array(samplePoints.enumerated()), id: \.offset) { _, pt in
                        Circle()
                            .fill(collapsed ? ganWarn.opacity(0.85) : tealAccent.opacity(0.85))
                            .frame(width: 5, height: 5)
                            .position(x: pt.x * W, y: pt.y * H)
                    }
                }
            }
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ganPanelBg.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ganPanelEdge, lineWidth: 0.8))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ganPanelEdge, lineWidth: 1))
        )
    }

    /// Deterministic sample positions seeded by `seed`.
    private var samplePoints: [CGPoint] {
        var rng = SeededRNG(seed: UInt64(seed))
        let total = 36
        if collapsed {
            let center = modes[0].center
            return (0..<total).map { _ in
                let r = rng.next01() * 0.07
                let theta = rng.next01() * .pi * 2
                let x = center.x + r * cos(theta)
                let y = center.y + r * sin(theta)
                return CGPoint(x: x, y: y)
            }
        } else {
            let weights: [Double] = [0.30, 0.28, 0.24, 0.18]
            var pts: [CGPoint] = []
            for (i, m) in modes.enumerated() {
                let count = max(1, Int(round(Double(total) * weights[i])))
                for _ in 0..<count {
                    let r = rng.next01() * 0.10
                    let theta = rng.next01() * .pi * 2
                    pts.append(CGPoint(x: m.center.x + r * cos(theta),
                                       y: m.center.y + r * sin(theta)))
                }
            }
            return pts
        }
    }

    // MARK: Coverage bars

    private var coverageBars: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MODE COVERAGE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text(collapsed ? "1 / 4 MODES" : "4 / 4 MODES")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(collapsed ? ganWarn : ganCorrect)
            }
            VStack(spacing: 6) {
                ForEach(Array(modes.enumerated()), id: \.offset) { i, m in
                    let cov = coverageFor(modeIndex: i)
                    HStack(spacing: 8) {
                        Text(m.label)
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(ganInkSubtle)
                            .frame(width: 56, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(ganPanelEdge.opacity(0.4))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: collapsed ? [ganWarn.opacity(0.55), ganWarn] : [tealAccent.opacity(0.55), tealAccent],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(cov))
                            }
                        }
                        .frame(height: 6)
                        Text(String(format: "%.0f%%", cov * 100))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(cov > 0.05 ? (collapsed ? ganWarn : tealAccent) : ganInkSubtle.opacity(0.6))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ganPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ganPanelEdge, lineWidth: 1))
        )
    }

    private func coverageFor(modeIndex: Int) -> Double {
        if collapsed {
            return modeIndex == 0 ? 0.95 : 0.02
        }
        let healthy: [Double] = [0.30, 0.28, 0.24, 0.18]
        return healthy[modeIndex]
    }

    // MARK: D punchline

    private var dPunchline: some View {
        HStack(spacing: 10) {
            Text("D'S VERDICT")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(ganInkSubtle)
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(ganCorrect).frame(width: 7, height: 7)
                Text("PASSES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(ganCorrect)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(ganCorrect.opacity(0.10))
                    .overlay(Capsule().stroke(ganCorrect.opacity(0.4), lineWidth: 0.8))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ganPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Tiny seeded RNG, deterministic across rerolls
// =============================================================================

private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdeadbeef : seed }
    mutating func next01() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let v = (state >> 33) & 0xffffff
        return Double(v) / Double(0xffffff)
    }
}

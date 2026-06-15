import SwiftUI

// MARK: - Premium interactive cards for "Deep Residual Learning for Image Recognition"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for the
// ResNet paper. Each uses a distinct interaction mode so the deck never
// repeats itself.
//
//   Card 04, ResNetFLearnView           — target picker + side-by-side
//      "Learn the change, not the whole." Pick a target H(x). The view shows
//      what F has to learn in a plain block (F = H) vs a residual block
//      (F = H − x). Difficulty bars surface why "answer mostly x" makes
//      residual trivial. A live x slider streams numeric outputs.
//
//   Card 05, ResNetTowerView             — grow-the-tower
//      "Plain breaks. ResNet bends." Tap GROW to add layers; two towers rise
//      in parallel. Above 20 layers the plain tower's error climbs and an X
//      mark eventually overlays it (DIVERGED). A JUMP TO 152 button finishes
//      the build.
//
//   Card 06, ResNetGradientStripeView    — horizontal fade rails + probe
//      "Signal survives the skip." Two long horizontal rails, Plain (amber)
//      fades from output to input; ResNet (teal) stays solid end to end.
//      Drag the probe to any depth, numeric readouts in monospaced log scale.

// MARK: - Local design tokens

private let rnInk        = inkColor
private let rnInkSubtle  = inkColor.opacity(0.65)
private let rnPanelBg    = Color(hex: "f4ece0")
private let rnPanelEdge  = Color(hex: "e2d8c6")
private let rnCorrect    = Color(hex: "1f7a4d")
private let rnWarn       = Color(hex: "b6502a")

// =============================================================================
// MARK: - Card 04, F-Learn Calculator
// =============================================================================

private enum FTarget: Int, CaseIterable, Identifiable {
    case identity, shift, flip
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .identity: return "IDENTITY"
        case .shift:    return "SHIFT"
        case .flip:     return "FLIP"
        }
    }
    var hExpression: String {
        switch self {
        case .identity: return "H(x) = x"
        case .shift:    return "H(x) = x + 0.3"
        case .flip:     return "H(x) = −x"
        }
    }
    /// What F has to learn in a plain block.
    var plainF: String {
        switch self {
        case .identity: return "F(x) = x"
        case .shift:    return "F(x) = x + 0.3"
        case .flip:     return "F(x) = −x"
        }
    }
    /// What F has to learn in a residual block (= H − x).
    var residualF: String {
        switch self {
        case .identity: return "F(x) = 0"
        case .shift:    return "F(x) = 0.3"
        case .flip:     return "F(x) = −2x"
        }
    }
    /// 0...1, hard = 1.
    var plainDifficulty: Double {
        switch self {
        case .identity: return 0.85
        case .shift:    return 0.85
        case .flip:     return 0.95
        }
    }
    var residualDifficulty: Double {
        switch self {
        case .identity: return 0.05
        case .shift:    return 0.20
        case .flip:     return 0.95
        }
    }
    var plainTag: String {
        switch self {
        case .identity: return "HARD"
        case .shift:    return "HARD"
        case .flip:     return "HARD"
        }
    }
    var residualTag: String {
        switch self {
        case .identity: return "TRIVIAL"
        case .shift:    return "EASY"
        case .flip:     return "HARD"
        }
    }
    var verdict: String {
        switch self {
        case .identity: return "Identity is what residual was built for. F just learns zero. The plain stack has to assemble identity out of nonlinearities, hard."
        case .shift:    return "A small offset. Residual F is a constant; plain F still has to track x and shift it. Residual wins comfortably."
        case .flip:     return "Both have to actively transform x. Residual gains nothing here, but loses nothing either. The skip never hurts."
        }
    }

    func plainFy(_ x: Double) -> Double {
        switch self {
        case .identity: return x
        case .shift:    return x + 0.3
        case .flip:     return -x
        }
    }
    func residualFy(_ x: Double) -> Double {
        switch self {
        case .identity: return 0
        case .shift:    return 0.3
        case .flip:     return -2 * x
        }
    }
    func hy(_ x: Double) -> Double {
        switch self {
        case .identity: return x
        case .shift:    return x + 0.3
        case .flip:     return -x
        }
    }
}

struct ResNetBlockView: View {
    @ObservedObject var state: DailyLoopState
    @State private var target: FTarget = .identity
    @State private var x: Double = 0.5
    @State private var visited: Set<Int> = [FTarget.identity.rawValue]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · WHAT F LEARNS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Learn the change. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(rnInk)
                + Text("Not the whole.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Pick a target output H(x). A plain block forces F to be H. A residual block lets F be H − x. When the answer is mostly x, F learns almost nothing.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                targetPicker
                    .padding(.bottom, 14)

                comparisonPanel
                    .padding(.bottom, 14)

                xSliderPanel
                    .padding(.bottom, 14)

                Text(target.verdict)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(rnInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: target) { _, _ in
            visited.insert(target.rawValue)
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= FTarget.allCases.count {
            state.customCardComplete.insert(3)
        }
    }

    private var targetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TARGET MAPPING")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text(target.hExpression)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInk)
                    .id(target)
                    .transition(.opacity)
            }

            HStack(spacing: 6) {
                ForEach(FTarget.allCases) { t in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            target = t
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Text(t.label)
                            .font(.system(size: 10, weight: target == t ? .bold : .semibold))
                            .tracking(1.0)
                            .foregroundStyle(target == t ? .white : rnInk.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(target == t ? tealAccent : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(target == t ? Color.clear : rnPanelEdge, lineWidth: 1)
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
                .fill(rnPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(rnPanelEdge, lineWidth: 1))
        )
    }

    private var comparisonPanel: some View {
        HStack(alignment: .top, spacing: 10) {
            blockColumn(
                title: "PLAIN BLOCK",
                subtitle: "no skip",
                fExpr: target.plainF,
                hExpr: "H(x) = F(x)",
                difficulty: target.plainDifficulty,
                tag: target.plainTag,
                tagColor: rnWarn,
                accent: amberAccent
            )
            blockColumn(
                title: "RESIDUAL",
                subtitle: "with skip",
                fExpr: target.residualF,
                hExpr: "H(x) = F(x) + x",
                difficulty: target.residualDifficulty,
                tag: target.residualTag,
                tagColor: target == .flip ? rnWarn : rnCorrect,
                accent: tealAccent
            )
        }
    }

    private func blockColumn(title: String, subtitle: String, fExpr: String, hExpr: String,
                             difficulty: Double, tag: String, tagColor: Color, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(accent)
                Text(subtitle)
                    .font(.system(size: 9, design: .serif))
                    .italic()
                    .foregroundStyle(rnInkSubtle)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("F MUST LEARN")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(rnInkSubtle)
                Text(fExpr)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInk)
                    .id(fExpr)
                    .transition(.opacity)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("OUTPUT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(rnInkSubtle)
                Text(hExpr)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(rnInkSubtle)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("DIFFICULTY")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(rnInkSubtle)
                    Spacer()
                    Text(tag)
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(tagColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(tagColor.opacity(0.10))
                                .overlay(Capsule().stroke(tagColor.opacity(0.4), lineWidth: 0.6))
                        )
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accent.opacity(0.10))
                        Capsule()
                            .fill(LinearGradient(colors: [accent.opacity(0.6), accent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(4, geo.size.width * difficulty))
                    }
                }
                .frame(height: 6)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: difficulty)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(rnPanelEdge, lineWidth: 1))
        )
    }

    private var xSliderPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LIVE INPUT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("x = \(xString(x))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInk)
            }

            // Slider for x ∈ [-1, 1]
            xSlider

            // Numeric outputs
            HStack(spacing: 8) {
                outputChip(label: "PLAIN F",
                           value: target.plainFy(x),
                           accent: amberAccent)
                outputChip(label: "RESID F",
                           value: target.residualFy(x),
                           accent: tealAccent)
                outputChip(label: "H(x)",
                           value: target.hy(x),
                           accent: rnInk)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(rnPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(rnPanelEdge, lineWidth: 1))
        )
    }

    private var xSlider: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let frac = (x + 1) / 2  // 0...1
            ZStack(alignment: .leading) {
                Capsule().fill(rnPanelEdge.opacity(0.6)).frame(height: 4)
                // Center tick
                Rectangle()
                    .fill(rnInkSubtle.opacity(0.5))
                    .frame(width: 1, height: 10)
                    .offset(x: width / 2 - 0.5, y: -3)
                Circle()
                    .fill(tealAccent)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .frame(width: 18, height: 18)
                    .offset(x: max(0, min(width - 18, width * frac - 9)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let f = max(0, min(1, v.location.x / width))
                                x = f * 2 - 1
                            }
                    )
            }
        }
        .frame(height: 18)
    }

    private func outputChip(label: String, value: Double, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(rnInkSubtle)
            Text(xString(value))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(rnPanelEdge, lineWidth: 1))
        )
    }

    private func xString(_ v: Double) -> String {
        let s = String(format: "%+.2f", v)
        // Replace ASCII minus with proper minus for display
        return s.replacingOccurrences(of: "-", with: "−")
    }
}

// =============================================================================
// MARK: - Card 05, Tower Builder
// =============================================================================

struct ResNetDepthView: View {
    @ObservedObject var state: DailyLoopState
    @State private var depth: Int = 0
    @State private var visitedMilestone: Set<Int> = []

    private let maxDepth: Int = 152

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · BUILD THE TOWERS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Plain breaks. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(rnInk)
                + Text("ResNet bends.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap GROW to add layers. Two networks build in parallel. Past 20 layers the plain tower's error climbs; past 100 it diverges entirely.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                towers
                    .padding(.bottom, 16)

                controlPanel
                    .padding(.bottom, 14)

                Text(verdictForDepth(depth))
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(plainDiverged ? rnWarn : rnInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: depth) { _, _ in
            recordMilestones()
            updateGate()
        }
    }

    private var plainDiverged: Bool { depth > 100 }

    private func resnetError(at d: Int) -> Double {
        // Anchor points: 0→untrained (10.5), 18→8.6, 34→7.0, 50→5.3, 101→4.1, 152→3.6
        guard d > 0 else { return 10.5 }
        let pts: [(Int, Double)] = [(0, 10.5), (18, 8.6), (34, 7.0), (50, 5.3), (101, 4.1), (152, 3.6)]
        return interpolate(pts, at: d)
    }

    private func plainError(at d: Int) -> Double {
        // 0→10.5, 18→9.2, 34→9.6, 50→11.0, 80→11.8 (still trainable, getting worse), 100→12.0 (cliff)
        guard d > 0 else { return 10.5 }
        let pts: [(Int, Double)] = [(0, 10.5), (18, 9.2), (34, 9.6), (50, 11.0), (80, 11.8), (100, 12.0)]
        return interpolate(pts, at: min(d, 100))
    }

    private func interpolate(_ pts: [(Int, Double)], at d: Int) -> Double {
        guard let first = pts.first else { return 0 }
        if d <= first.0 { return first.1 }
        for i in 0..<(pts.count - 1) {
            let (x0, y0) = pts[i]
            let (x1, y1) = pts[i + 1]
            if d >= x0 && d <= x1 {
                let t = Double(d - x0) / Double(max(1, x1 - x0))
                return y0 + (y1 - y0) * t
            }
        }
        return pts.last?.1 ?? 0
    }

    private func recordMilestones() {
        for m in [0, 20, 50, 100, 152] where depth >= m {
            visitedMilestone.insert(m)
        }
    }

    private func updateGate() {
        if depth >= 100 {
            state.customCardComplete.insert(4)
        }
    }

    private func verdictForDepth(_ d: Int) -> String {
        switch d {
        case 0: return "Both networks are at depth 0. Untrained, errors are tied at 10.5%. Tap GROW to start adding layers."
        case 1...20: return "Shallow regime. Both networks improve as depth grows, the skip costs nothing here."
        case 21...50: return "The U turn. Plain net's error has started climbing, depth degradation in action. ResNet keeps falling."
        case 51...100: return "Deep. ResNet drops past 5%. Plain net is approaching its cliff; gradient signal is dying."
        case 101...152: return "Plain has DIVERGED. ResNet, still building. At 152 layers it wins ImageNet 2015."
        default: return ""
        }
    }

    // MARK: Towers

    private var towers: some View {
        let containerHeight: CGFloat = 220
        let pxPerLayer: CGFloat = containerHeight / CGFloat(maxDepth)
        return HStack(alignment: .bottom, spacing: 14) {
            towerColumn(title: "PLAIN",
                        depth: depth,
                        error: plainError(at: depth),
                        diverged: plainDiverged,
                        accent: amberAccent,
                        pxPerLayer: pxPerLayer,
                        containerHeight: containerHeight)
            towerColumn(title: "RESNET",
                        depth: depth,
                        error: resnetError(at: depth),
                        diverged: false,
                        accent: tealAccent,
                        pxPerLayer: pxPerLayer,
                        containerHeight: containerHeight)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(rnPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(rnPanelEdge, lineWidth: 1))
        )
    }

    private func towerColumn(title: String,
                             depth: Int,
                             error: Double,
                             diverged: Bool,
                             accent: Color,
                             pxPerLayer: CGFloat,
                             containerHeight: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Top readout
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(accent)
                if diverged {
                    Text("DIVERGED")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(rnWarn)
                } else {
                    Text(String(format: "%.1f%%", error))
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(rnInk)
                        .contentTransition(.numericText())
                }
            }

            // Tower
            ZStack(alignment: .bottom) {
                // Empty plinth outline
                RoundedRectangle(cornerRadius: 4)
                    .stroke(rnPanelEdge.opacity(0.6), style: StrokeStyle(lineWidth: 0.6, dash: [2, 3]))
                    .frame(width: 44, height: containerHeight)

                // Stack of layers
                VStack(spacing: 0.5) {
                    ForEach(0..<depth, id: \.self) { i in
                        Rectangle()
                            .fill(layerColor(i: i, accent: accent, diverged: diverged))
                            .frame(width: 38, height: max(0.8, pxPerLayer - 0.5))
                    }
                }
                .frame(width: 44, alignment: .bottom)

                // Diverged X overlay
                if diverged {
                    ZStack {
                        Rectangle()
                            .fill(rnWarn.opacity(0.10))
                            .frame(width: 44, height: containerHeight)
                        Path { p in
                            p.move(to: CGPoint(x: 4, y: 4))
                            p.addLine(to: CGPoint(x: 40, y: containerHeight - 4))
                            p.move(to: CGPoint(x: 40, y: 4))
                            p.addLine(to: CGPoint(x: 4, y: containerHeight - 4))
                        }
                        .stroke(rnWarn.opacity(0.7), lineWidth: 1.5)
                        .frame(width: 44, height: containerHeight)
                    }
                }
            }
            .frame(width: 44, height: containerHeight)
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: depth)

            // Depth label
            Text("L=\(depth)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(rnInkSubtle)
        }
        .frame(maxWidth: .infinity)
    }

    /// Color shifts: plain blocks turn rust as depth crosses degradation point.
    private func layerColor(i: Int, accent: Color, diverged: Bool) -> Color {
        if accent == amberAccent && i >= 20 {
            // Plain net layers past 20 turn warm/rust as a degradation cue.
            return rnWarn.opacity(0.7)
        }
        return accent.opacity(0.85)
    }

    // MARK: Controls

    private var controlPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                controlButton(title: "+5", action: { grow(by: 5) }, fill: tealAccent, isPrimary: true)
                controlButton(title: "+20", action: { grow(by: 20) }, fill: tealAccent.opacity(0.8), isPrimary: true)
                controlButton(title: "BUILD TO 152",
                              action: { animateTo(152) },
                              fill: rnInk,
                              isPrimary: true)
            }
            HStack(spacing: 8) {
                controlButton(title: "RESET", action: { animateTo(0) }, fill: Color.white, isPrimary: false)
                Text("DEPTH")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(rnInkSubtle)
                Text("\(depth) / \(maxDepth)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInk)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func grow(by n: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            depth = min(maxDepth, depth + n)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func animateTo(_ target: Int) {
        let clamped = min(max(0, target), maxDepth)
        if clamped == depth {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            return
        }
        let steps = 30
        let delta = clamped - depth
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.025) {
                withAnimation(.linear(duration: 0.025)) {
                    depth = depth + delta / steps
                    if i == steps { depth = clamped }
                }
                if i == steps { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
        }
    }

    private func controlButton(title: String, action: @escaping () -> Void, fill: Color, isPrimary: Bool) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(isPrimary ? .white : rnInk)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isPrimary ? Color.clear : rnPanelEdge, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// =============================================================================
// MARK: - Card 06, Gradient Stripe + Probe
// =============================================================================

struct ResNetGradientView: View {
    @ObservedObject var state: DailyLoopState
    @State private var probeFraction: Double = 0.5  // 0 = input, 1 = output
    @State private var visitedRegions: Set<Int> = [1]  // quartiles 0..3

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · GRADIENT HIGHWAY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Signal survives. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(rnInk)
                + Text("The skip.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Two rails, gradient strength along each layer. Plain (amber) fades from output to input. ResNet (teal) holds. Drag the probe to read either off.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                stripePanel
                    .padding(.bottom, 14)

                readoutPanel
                    .padding(.bottom, 14)

                Text(verdict)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(plainHealthy ? rnInkSubtle : rnWarn)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
        .onChange(of: probeFraction) { _, _ in
            visitedRegions.insert(quartile(probeFraction))
            updateGate()
        }
    }

    private func quartile(_ f: Double) -> Int { min(3, max(0, Int(f * 4))) }

    private func updateGate() {
        if visitedRegions.count >= 3 {
            state.customCardComplete.insert(5)
        }
    }

    /// log10 magnitude. f = 0 means input (left), f = 1 means output (right).
    private func plainLog(_ f: Double) -> Double {
        // Roughly: at output (f=1) log = 0; at input (f=0) log = -6
        return -6.0 * (1.0 - f)
    }
    private func resnetLog(_ f: Double) -> Double {
        // Slight decay across depth: output 0, input ~ -0.15
        return -0.15 * (1.0 - f)
    }

    private var plainHealthy: Bool { plainLog(probeFraction) > -1.0 }

    private var verdict: String {
        let pf = probeFraction
        if pf > 0.85 {
            return "Near the output. Both gradients are healthy here, this is the easy end."
        } else if pf > 0.5 {
            return "Mid-network. Plain has lost an order of magnitude already; ResNet has barely decayed."
        } else if pf > 0.15 {
            return "Past mid-depth. Plain's gradient is shrinking exponentially. ResNet stays close to full strength."
        } else {
            return "At the input. Plain gradient is essentially noise; ResNet's still ~80% of the output. Trainable, that is the whole win."
        }
    }

    // MARK: Stripe panel

    private var stripePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("INPUT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(rnInkSubtle)
                Spacer()
                Text("BACKPROP DIRECTION ←")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("OUTPUT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(rnInkSubtle)
            }
            .padding(.horizontal, 4)

            stripeRow(label: "ResNet",
                      gradient: LinearGradient(
                        colors: [tealAccent.opacity(0.55), tealAccent],
                        startPoint: .leading, endPoint: .trailing),
                      accent: tealAccent,
                      log10: resnetLog(probeFraction),
                      healthy: true)

            stripeRow(label: "Plain",
                      gradient: LinearGradient(
                        colors: [amberAccent.opacity(0.02), amberAccent.opacity(0.18),
                                 amberAccent.opacity(0.55), amberAccent],
                        startPoint: .leading, endPoint: .trailing),
                      accent: amberAccent,
                      log10: plainLog(probeFraction),
                      healthy: plainHealthy)

            // Probe rail
            probeRail
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(rnPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(rnPanelEdge, lineWidth: 1))
        )
    }

    private func stripeRow(label: String,
                           gradient: LinearGradient,
                           accent: Color,
                           log10: Double,
                           healthy: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(rnInk)
                Circle()
                    .fill(healthy ? rnCorrect : rnWarn)
                    .frame(width: 6, height: 6)
                Text(healthy ? "alive" : "vanished")
                    .font(.system(size: 9, design: .serif))
                    .italic()
                    .foregroundStyle(healthy ? rnCorrect : rnWarn)
                Spacer()
                Text(magnitudeString(log10))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(healthy ? accent : rnWarn)
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rnPanelEdge.opacity(0.3))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(gradient)
                    // Probe marker on the stripe
                    Rectangle()
                        .fill(rnInk.opacity(0.85))
                        .frame(width: 1.5, height: 18)
                        .offset(x: geo.size.width * probeFraction - 0.75, y: -1)
                }
            }
            .frame(height: 16)
        }
    }

    private var probeRail: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white)
                        .overlay(Capsule().stroke(rnPanelEdge, lineWidth: 1))
                        .frame(height: 6)
                    Circle()
                        .fill(rnInk)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .frame(width: 18, height: 18)
                        .offset(x: max(0, min(w - 18, w * probeFraction - 9)))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { v in
                                    let f = max(0, min(1, v.location.x / w))
                                    probeFraction = f
                                }
                        )
                    // Tap-to-jump tick stops
                    HStack(spacing: 0) {
                        ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { stop in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                        probeFraction = stop
                                    }
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                }
                        }
                    }
                    .frame(height: 18)
                    .allowsHitTesting(probeFraction.isFinite)
                }
                .frame(height: 18)
            }
            .frame(height: 18)

            HStack {
                Text("L=1")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInkSubtle)
                Spacer()
                Text("L=50")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInkSubtle)
                Spacer()
                Text("L=100")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInkSubtle)
                Spacer()
                Text("L=152")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rnInkSubtle)
            }
        }
    }

    // MARK: Readout panel

    private var readoutPanel: some View {
        HStack(spacing: 10) {
            readoutChip(label: "PROBE AT",
                        value: layerLabelForFraction(probeFraction),
                        accent: rnInk)
            readoutChip(label: "PLAIN ‖∇‖",
                        value: magnitudeString(plainLog(probeFraction)),
                        accent: plainHealthy ? amberAccent : rnWarn)
            readoutChip(label: "RESNET ‖∇‖",
                        value: magnitudeString(resnetLog(probeFraction)),
                        accent: tealAccent)
        }
    }

    private func layerLabelForFraction(_ f: Double) -> String {
        let layer = Int(round(f * 152))
        return "L=\(max(1, layer))"
    }

    private func magnitudeString(_ log10: Double) -> String {
        let v = pow(10.0, log10)
        if v >= 0.1 { return String(format: "%.2f", v) }
        if v >= 0.001 { return String(format: "%.3f", v) }
        let s = String(format: "%.0e", v)
        return s.replacingOccurrences(of: "e-0", with: "e-")
    }

    private func readoutChip(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(rnInkSubtle)
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
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(rnPanelEdge, lineWidth: 1))
        )
    }
}

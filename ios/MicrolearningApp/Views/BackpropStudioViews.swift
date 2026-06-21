import SwiftUI

// MARK: - Premium interactive cards for "Learning Representations by
//                                       Back Propagating Errors"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for
// Rumelhart, Hinton, Williams (1986). Design language mirrors the AlexNet /
// Word2Vec studios.
//
//   Card 04, BackpropFlowView
//      "Forward, then backward." Tap RUN. Activations flow left to right,
//      then gradients flow right to left, lighting each layer in turn.
//      Tap any node to inspect the local derivative.
//
//   Card 05, BackpropChainRuleView
//      "Just the chain rule, repeated." Drag the input slider. Watch every
//      intermediate value, the loss, and each partial derivative recompute
//      live: ∂L/∂w₁ = ∂L/∂y · ∂y/∂h · ∂h/∂w₁.
//
//   Card 06, BackpropCreditView
//      "Hidden layers finally learn." Slide the epoch dial from 0 to 200.
//      Without backprop, hidden units stay random. With it, they organise
//      into edge, curve, and corner detectors.

private let bpInk        = inkColor
private let bpInkSubtle  = inkColor.opacity(0.65)
private let bpPanelBg    = Color(hex: "f4ece0")
private let bpPanelEdge  = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Forward / Backward Flow
// =============================================================================

private enum BPNode: String, CaseIterable, Identifiable {
    case x, h1, h2, y, loss
    var id: String { rawValue }

    var label: String {
        switch self {
        case .x:    return "x"
        case .h1:   return "h₁"
        case .h2:   return "h₂"
        case .y:    return "ŷ"
        case .loss: return "L"
        }
    }

    var color: Color {
        switch self {
        case .x:    return tealAccent
        case .h1:   return amberAccent
        case .h2:   return amberAccent
        case .y:    return Color(hex: "7b4ba4")
        case .loss: return Color(hex: "c0573c")
        }
    }

    var forwardEqn: String {
        switch self {
        case .x:    return "Input feature, treated as a constant during this pass."
        case .h1:   return "h₁ = σ(W₁x + b₁). The first hidden representation."
        case .h2:   return "h₂ = σ(W₂h₁ + b₂). A composition of the first."
        case .y:    return "ŷ = W₃h₂ + b₃. Final prediction, no nonlinearity at the head."
        case .loss: return "L = ½(ŷ − y)². Mean-squared error between prediction and truth."
        }
    }

    var backwardEqn: String {
        switch self {
        case .x:    return "Inputs are fixed, no gradient needed here. The chain stops at the first weight matrix."
        case .h1:   return "∂L/∂h₁ = ∂L/∂h₂ · σ'(z₂) · W₂. Receive gradient from above, propagate down."
        case .h2:   return "∂L/∂h₂ = ∂L/∂ŷ · W₃. The error from the head is shaped by the layer above."
        case .y:    return "∂L/∂ŷ = ŷ − y. Closed form for MSE. The prediction gap, signed."
        case .loss: return "Start of the backward pass. Gradient at the top is 1 by definition."
        }
    }
}

struct BackpropFlowView: View {
    @ObservedObject var state: DailyLoopState
    @State private var phase: Int = 0   // 0 idle, 1 forward, 2 backward, 3 done
    @State private var visited: Set<BPNode> = []
    @State private var active: BPNode = .x
    @State private var fwdProgress: Double = 0
    @State private var bwdProgress: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · FORWARD, THEN BACKWARD")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Run a pass. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(bpInk)
                + Text("Watch the gradient walk back.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Activations propagate left to right. Loss is computed. Gradients propagate back, multiplied by each layer's local derivative. Tap any node to read its equation.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                runRow
                    .padding(.bottom, 14)

                graphPanel
                    .padding(.bottom, 18)

                detailPanel
                    .padding(.bottom, 14)

                Text(verdictLine)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(bpInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }

    private var verdictLine: String {
        if phase == 0 { return "Idle. Tap RUN to send a pass forward and a gradient back." }
        if phase == 1 { return "Forward pass. Each layer transforms its input and hands the result forward." }
        if phase == 2 { return "Backward pass. Gradient flows right to left, each layer applies the chain rule once." }
        return "One full pass done. The weights now know how to update. Visited \(visited.count) of \(BPNode.allCases.count) nodes."
    }

    private func runPass() {
        if phase != 0 { reset(); return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.linear(duration: 0.9)) {
            phase = 1
            fwdProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.linear(duration: 0.9)) {
                phase = 2
                bwdProgress = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            phase = 3
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = 0
            fwdProgress = 0
            bwdProgress = 0
        }
    }

    private func tap(_ n: BPNode) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            active = n
        }
        visited.insert(n)
        if visited.count >= BPNode.allCases.count {
            state.customCardComplete.insert(3)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private var runRow: some View {
        HStack(spacing: 10) {
            Button(action: runPass) {
                HStack(spacing: 6) {
                    Image(systemName: phase == 0 ? "play.fill" : "arrow.counterclockwise")
                        .font(scaledSystemFont(11, weight: .bold))
                    Text(phase == 0 ? "Run pass" : "Reset")
                        .font(scaledSystemFont(13, weight: .semibold, design: .serif))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(Capsule().fill(tealAccent))
            }
            .buttonStyle(.plain)
            Spacer()
            Text(phaseLabel)
                .font(scaledSystemFont(9, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(phaseColor.opacity(0.10))
                    .overlay(Capsule().stroke(phaseColor.opacity(0.35), lineWidth: 0.8)))
        }
    }

    private var phaseLabel: String {
        switch phase {
        case 1: return "FORWARD"
        case 2: return "BACKWARD"
        case 3: return "DONE"
        default: return "IDLE"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case 1: return tealAccent
        case 2: return amberAccent
        case 3: return Color(hex: "4a9c4a")
        default: return bpInkSubtle
        }
    }

    private var graphPanel: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let cy: CGFloat = 90
            let nodes = BPNode.allCases
            let xs: [CGFloat] = nodes.indices.map { i in
                28 + CGFloat(i) * (w - 56) / CGFloat(nodes.count - 1)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(bpPanelEdge, lineWidth: 1))

                // Forward arrows (top)
                ForEach(0..<nodes.count - 1, id: \.self) { i in
                    let from = CGPoint(x: xs[i] + 18, y: cy)
                    let to   = CGPoint(x: xs[i + 1] - 18, y: cy)
                    arrow(from: from, to: to,
                          color: tealAccent,
                          active: phase == 1 && Double(i + 1) <= fwdProgress * Double(nodes.count - 1) + 0.5,
                          label: "fwd")
                }

                // Backward arrows (bottom curve)
                ForEach(0..<nodes.count - 1, id: \.self) { i in
                    let revIdx = nodes.count - 2 - i
                    let from = CGPoint(x: xs[revIdx + 1] - 18, y: cy + 36)
                    let to   = CGPoint(x: xs[revIdx] + 18, y: cy + 36)
                    arrow(from: from, to: to,
                          color: amberAccent,
                          active: phase >= 2 && Double(i + 1) <= bwdProgress * Double(nodes.count - 1) + 0.5,
                          label: "grad")
                }

                // Nodes
                ForEach(nodes.indices, id: \.self) { i in
                    nodeView(nodes[i]).position(x: xs[i], y: cy + 18)
                }

                // Captions
                Text("FORWARD").font(scaledSystemFont(8, weight: .bold)).tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                    .position(x: 50, y: cy - 16)
                Text("BACKWARD").font(scaledSystemFont(8, weight: .bold)).tracking(1.4)
                    .foregroundStyle(amberAccent)
                    .position(x: 60, y: cy + 56)
            }
        }
        .frame(height: 168)
    }

    private func arrow(from: CGPoint, to: CGPoint, color: Color, active: Bool, label: String) -> some View {
        ZStack {
            Path { p in
                p.move(to: from); p.addLine(to: to)
            }
            .stroke(active ? color : bpPanelEdge,
                    style: StrokeStyle(lineWidth: active ? 2 : 1.2, lineCap: .round))

            // Arrowhead at to
            let dx = to.x - from.x
            let len = max(abs(dx), 1)
            let dir: CGFloat = dx >= 0 ? 1 : -1
            let head = CGPoint(x: to.x, y: to.y)
            Path { p in
                p.move(to: head)
                p.addLine(to: CGPoint(x: head.x - 6 * dir * (len/len), y: head.y - 4))
                p.move(to: head)
                p.addLine(to: CGPoint(x: head.x - 6 * dir * (len/len), y: head.y + 4))
            }
            .stroke(active ? color : bpPanelEdge,
                    style: StrokeStyle(lineWidth: active ? 2 : 1.2, lineCap: .round))
        }
    }

    @ViewBuilder
    private func nodeView(_ n: BPNode) -> some View {
        let isA = active == n
        Button {
            tap(n)
        } label: {
            Text(n.label)
                .font(scaledSystemFont(13, weight: .bold, design: .serif))
                .foregroundStyle(isA ? .white : bpInk)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(isA ? n.color : Color.white)
                        .overlay(Circle().stroke(n.color, lineWidth: 1.6))
                )
        }
        .buttonStyle(.plain)
    }

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(active.color).frame(width: 8, height: 8)
                Text("NODE \(active.label.uppercased())")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(active.color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "FORWARD", body: active.forwardEqn, color: tealAccent)
                detailRow(title: "BACKWARD", body: active.backwardEqn, color: amberAccent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bpPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(bpPanelEdge, lineWidth: 1))
        )
    }

    private func detailRow(title: String, body: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(scaledSystemFont(8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(color)
            Text(body)
                .font(scaledSystemFont(12, design: .serif))
                .foregroundStyle(bpInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// =============================================================================
// MARK: - Card 05, Chain Rule Slider
// =============================================================================

struct BackpropChainRuleView: View {
    @ObservedObject var state: DailyLoopState
    @State private var x: Double = 1.0
    @State private var stops: Set<Int> = []   // sample indices the user dragged through

    // Tiny network: h = σ(w₁ x + b₁), ŷ = w₂ h + b₂, L = ½(ŷ − t)²
    private let w1: Double = 0.7
    private let b1: Double = 0.2
    private let w2: Double = 1.5
    private let b2: Double = -0.3
    private let target: Double = 1.2

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · ONE RULE, COMPOSED")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Just the chain rule. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(bpInk)
                + Text("Repeated.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Drag the input slider. Every intermediate value and partial derivative updates live. ∂L/∂w₁ is the product of the local derivatives along the path.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                slider
                    .padding(.bottom, 14)

                forwardPanel
                    .padding(.bottom, 14)

                backwardPanel
                    .padding(.bottom, 14)

                Text(verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(bpInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }

    // -- Math --
    private func sigmoid(_ z: Double) -> Double { 1.0 / (1.0 + exp(-z)) }

    private var z1: Double { w1 * x + b1 }
    private var h: Double { sigmoid(z1) }
    private var yhat: Double { w2 * h + b2 }
    private var loss: Double { 0.5 * (yhat - target) * (yhat - target) }

    private var dL_dy: Double { yhat - target }
    private var dy_dh: Double { w2 }
    private var dh_dz: Double { h * (1 - h) }
    private var dz_dw: Double { x }
    private var dL_dw: Double { dL_dy * dy_dh * dh_dz * dz_dw }

    private var verdict: String {
        if loss < 0.05 {
            return "Loss \(String(format: "%.3f", loss)). The prediction is on top of the target. ∂L/∂w₁ approaches zero, no more updates needed."
        }
        if dL_dw > 0 {
            return "Gradient is positive. SGD pushes w₁ down by η · \(String(format: "%.3f", dL_dw)) on the next step."
        }
        return "Gradient is negative. SGD nudges w₁ up by η · \(String(format: "%.3f", -dL_dw)) on the next step."
    }

    private var slider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INPUT x")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text(String(format: "%+.2f", x))
                    .font(scaledSystemFont(13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(bpInk)
                    .contentTransition(.numericText(value: x))
            }
            Slider(value: Binding(get: { x }, set: {
                x = $0
                let stop = Int((x + 2) * 4)   // 16 stops over -2...2
                stops.insert(stop)
                if stops.count >= 6 { state.customCardComplete.insert(4) }
            }), in: -2.0...2.0)
            .accentColor(tealAccent)
            .padding(.horizontal, 4)
            HStack {
                Text("−2").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(bpInkSubtle.opacity(0.7))
                Spacer()
                Text("0").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(bpInkSubtle.opacity(0.7))
                Spacer()
                Text("+2").font(scaledSystemFont(9, design: .monospaced)).foregroundStyle(bpInkSubtle.opacity(0.7))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(bpPanelEdge, lineWidth: 1))
        )
    }

    private var forwardPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORWARD")
                .font(scaledSystemFont(9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(tealAccent.opacity(0.85))
            valueRow("z₁ = w₁·x + b₁", value: z1, color: tealAccent)
            valueRow("h = σ(z₁)",       value: h,  color: amberAccent)
            valueRow("ŷ = w₂·h + b₂",   value: yhat, color: Color(hex: "7b4ba4"))
            valueRow("L = ½(ŷ − t)²",   value: loss, color: Color(hex: "c0573c"), highlight: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bpPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(bpPanelEdge, lineWidth: 1))
        )
    }

    private var backwardPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BACKWARD · CHAIN")
                .font(scaledSystemFont(9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(amberAccent)
            VStack(alignment: .leading, spacing: 6) {
                Text("∂L/∂w₁  =  ∂L/∂ŷ  ·  ∂ŷ/∂h  ·  ∂h/∂z  ·  ∂z/∂w")
                    .font(scaledSystemFont(11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(bpInk)
                HStack(spacing: 8) {
                    factor("ŷ−t",   value: dL_dy, color: Color(hex: "c0573c"))
                    Text("·").foregroundStyle(bpInkSubtle).font(scaledSystemFont(12, weight: .bold))
                    factor("w₂",    value: dy_dh, color: Color(hex: "7b4ba4"))
                    Text("·").foregroundStyle(bpInkSubtle).font(scaledSystemFont(12, weight: .bold))
                    factor("h(1−h)",value: dh_dz, color: amberAccent)
                    Text("·").foregroundStyle(bpInkSubtle).font(scaledSystemFont(12, weight: .bold))
                    factor("x",     value: dz_dw, color: tealAccent)
                }
            }
            valueRow("∂L/∂w₁", value: dL_dw, color: tealAccent, highlight: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(bpPanelEdge, lineWidth: 1))
        )
    }

    private func valueRow(_ label: String, value: Double, color: Color, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(scaledSystemFont(11, design: .monospaced))
                .foregroundStyle(bpInk)
            Spacer()
            Text(String(format: "%+.3f", value))
                .font(scaledSystemFont(highlight ? 14 : 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: value))
        }
    }

    private func factor(_ name: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(scaledSystemFont(8, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(String(format: "%+.2f", value))
                .font(scaledSystemFont(11, weight: .semibold, design: .monospaced))
                .foregroundStyle(bpInk)
                .contentTransition(.numericText(value: value))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 0.8))
        )
    }
}

// =============================================================================
// MARK: - Card 06, Credit Assignment Through Time
// =============================================================================

struct BackpropCreditView: View {
    @ObservedObject var state: DailyLoopState
    @State private var epoch: Double = 0
    @State private var withBackprop: Bool = true
    @State private var stops: Set<Int> = []

    // 8 hidden units in a 4×2 grid; each animates from random to a learned
    // detector pattern as epoch advances. Patterns are 5×5 binary masks.
    private static let learned: [[Int]] = [
        // horizontal edge
        [0,0,0,0,0, 0,0,0,0,0, 1,1,1,1,1, 0,0,0,0,0, 0,0,0,0,0],
        // vertical edge
        [0,0,1,0,0, 0,0,1,0,0, 0,0,1,0,0, 0,0,1,0,0, 0,0,1,0,0],
        // diagonal /
        [0,0,0,0,1, 0,0,0,1,0, 0,0,1,0,0, 0,1,0,0,0, 1,0,0,0,0],
        // diagonal \
        [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0, 0,0,0,0,1],
        // top corner
        [1,1,1,0,0, 1,0,0,0,0, 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0],
        // arc
        [0,1,1,1,0, 1,0,0,0,1, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0],
        // T
        [1,1,1,1,1, 0,0,1,0,0, 0,0,1,0,0, 0,0,1,0,0, 0,0,0,0,0],
        // L
        [1,0,0,0,0, 1,0,0,0,0, 1,0,0,0,0, 1,0,0,0,0, 1,1,1,1,0],
    ]

    private static let labels: [String] = [
        "h-edge", "v-edge", "diag /", "diag \\", "corner", "arc", "junction", "L-shape"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · CREDIT ASSIGNMENT")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Hidden units, ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(bpInk)
                + Text("organising themselves.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Slide the epoch dial. With backprop, eight hidden units crystallise into edge, corner, and stroke detectors. Without it, the same units stay random forever.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                modeToggle
                    .padding(.bottom, 14)

                epochSlider
                    .padding(.bottom, 16)

                hiddenGrid
                    .padding(.bottom, 16)

                Text(verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(bpInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }

    private var verdict: String {
        let e = Int(epoch)
        if !withBackprop {
            return "No gradient signal at epoch \(e). Hidden units are stuck on the initialisation. The output layer cannot tell them what to learn."
        }
        if e < 30 { return "Epoch \(e). Faint structure emerging. The error signal has only made it through a few times." }
        if e < 100 { return "Epoch \(e). Edges and corners visible. The hidden layer has discovered features no one designed." }
        return "Epoch \(e). Detectors crisp. This is what Hinton meant by learning representations."
    }

    private var modeToggle: some View {
        HStack(spacing: 8) {
            modeChip(label: "With backprop",   on: withBackprop)
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { withBackprop = true }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            modeChip(label: "No backprop", on: !withBackprop)
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { withBackprop = false }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            Spacer()
        }
    }

    private func modeChip(label: String, on: Bool) -> some View {
        Text(label)
            .font(scaledSystemFont(11, weight: on ? .semibold : .regular, design: .serif))
            .foregroundStyle(on ? .white : bpInkSubtle)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(on ? tealAccent : Color.white)
                    .overlay(Capsule().stroke(bpPanelEdge, lineWidth: on ? 0 : 1))
            )
    }

    private var epochSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("EPOCH")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text(String(format: "%d / 200", Int(epoch)))
                    .font(scaledSystemFont(13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(bpInk)
            }
            Slider(value: Binding(get: { epoch }, set: {
                epoch = $0
                let stop = Int(epoch / 25)
                stops.insert(stop)
                if stops.count >= 5 || epoch > 150 { state.customCardComplete.insert(5) }
            }), in: 0...200)
            .accentColor(tealAccent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(bpPanelEdge, lineWidth: 1))
        )
    }

    private var hiddenGrid: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { col in
                        let idx = row * 4 + col
                        unitTile(idx)
                    }
                }
            }
        }
    }

    private func unitTile(_ idx: Int) -> some View {
        let cells: Int = 5
        let progress: Double = withBackprop ? min(epoch / 150, 1.0) : 0.0
        return VStack(spacing: 4) {
            // 5x5 grid
            VStack(spacing: 1) {
                ForEach(0..<cells, id: \.self) { r in
                    HStack(spacing: 1) {
                        ForEach(0..<cells, id: \.self) { c in
                            let learnedOn = Self.learned[idx][r * cells + c] == 1
                            // Random target seeded from idx,r,c so it stays stable
                            let seed = abs((idx * 127) ^ (r * 31) ^ (c * 7))
                            let randomVal = Double((seed * 9301 + 49297) % 233280) / 233280.0
                            let targetVal = learnedOn ? 0.92 : 0.06
                            let v = randomVal * (1 - progress) + targetVal * progress
                            Rectangle()
                                .fill(tealAccent.opacity(v))
                                .frame(width: 9, height: 9)
                        }
                    }
                }
            }
            Text(progress > 0.4 ? Self.labels[idx] : "—")
                .font(scaledSystemFont(8, weight: .bold, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(progress > 0.4 ? tealAccent : bpInkSubtle.opacity(0.6))
                .frame(height: 9)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(bpPanelEdge, lineWidth: 1))
        )
    }
}

import SwiftUI

// MARK: - Premium interactive cards for "ImageNet Classification with Deep
//                                       Convolutional Neural Networks"
//
// Three bespoke cards that replace the generic flow + bar-chart slots for
// the AlexNet paper. Design language mirrors the Word2Vec / Attention
// studios: cream prompt panels, teal accent, serif headlines, monospaced
// data, faint amber strips.
//
//   Card 04, AlexNetAblationView
//      "Five tricks compound." Toggle ReLU, Dropout, Augmentation, Dual
//      GPU, LRN. The top-5 error tile collapses from a 26% baseline to
//      16.4% as each trick comes online. Each row shows its delta.
//
//   Card 05, AlexNetReluRaceView
//      "ReLU trains six times faster." Tap any activation. Hardcoded
//      training curves race down the panel. ReLU hits 25% error at epoch
//      6; tanh needs 36; sigmoid never quite gets there.
//
//   Card 06, AlexNetCliffView
//      "Twenty twelve, the cliff." ImageNet top-5 error 2010 to 2012
//      with the runner-up baseline. Tap a year. The 10-point drop is the
//      first phase transition in computer vision.

// MARK: - Local design tokens (mirrors Word2Vec studio)

private let axInk        = inkColor
private let axInkSubtle  = inkColor.opacity(0.65)
private let axPanelBg    = Color(hex: "f4ece0")
private let axPanelEdge  = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Ablation Toggle Stack
// =============================================================================

private enum AlexTrick: Int, CaseIterable, Identifiable {
    case relu, dropout, aug, gpu, lrn
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .relu:    return "ReLU"
        case .dropout: return "Dropout"
        case .aug:     return "Augmentation"
        case .gpu:     return "Dual GPU"
        case .lrn:     return "Local Resp Norm"
        }
    }

    var subtitle: String {
        switch self {
        case .relu:    return "max(0, x). 6× faster training, no vanishing gradient."
        case .dropout: return "Zero 50% of FC neurons each pass. Forces redundant features."
        case .aug:     return "Random 224 crops, flips, PCA colour jitter. ~2,048× more data."
        case .gpu:     return "Split across 2× GTX 580. Enables 60M parameters."
        case .lrn:     return "Local Response Norm. Lateral inhibition between channels."
        }
    }

    // Approximate top-5 error delta when this trick comes on. Tuned so all
    // five flipped lands within rounding of AlexNet's reported 16.4%.
    var deltaPct: Double {
        switch self {
        case .relu:    return 2.5
        case .dropout: return 3.0
        case .aug:     return 2.5
        case .gpu:     return 1.0
        case .lrn:     return 0.6
        }
    }
}

private let alexBaselinePct: Double = 25.6   // baseline with all tricks off
private let alexTargetPct: Double   = 16.0   // sum of all deltas removed

struct AlexNetAblationView: View {
    @ObservedObject var state: DailyLoopState
    @State private var on: Set<AlexTrick> = Set(AlexTrick.allCases)
    @State private var visited: Set<AlexTrick> = []
    @State private var animatedError: Double = alexTargetPct

    private var currentError: Double {
        let removed = AlexTrick.allCases
            .filter { !on.contains($0) }
            .map { $0.deltaPct }
            .reduce(0, +)
        return alexTargetPct + removed
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · FIVE TRICKS COMPOUND")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Flip each on. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(axInk)
                + Text("Watch error collapse.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Each row is one of AlexNet's five practical ideas. Toggle any combination. The top-5 error tile recomputes the contribution of what's on.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                errorTile
                    .padding(.bottom, 16)

                togglesPanel
                    .padding(.bottom, 14)

                Text(verdictLine)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(axInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            animatedError = currentError
            updateGate()
        }
        .onChange(of: on) { _, _ in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                animatedError = currentError
            }
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= AlexTrick.allCases.count {
            state.customCardComplete.insert(3)
        }
    }

    private var verdictLine: String {
        if on.isEmpty {
            return "Baseline. No tricks. The 2011 ImageNet winner sat near here using hand-crafted features."
        }
        if on == Set(AlexTrick.allCases) {
            return "Full AlexNet. 16.4% top-5. Runner-up that year: 26.2%, still hand-crafted features."
        }
        if on.count == 1, let only = on.first {
            return "\(only.name) alone removes \(String(format: "%.1f", only.deltaPct)) points. The tricks compound; together they multiply."
        }
        let saved = AlexTrick.allCases.filter { on.contains($0) }.map { $0.deltaPct }.reduce(0, +)
        return "\(on.count) tricks on. \(String(format: "%.1f", saved)) points removed. Each addition compounds with the others."
    }

    private var errorTile: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("IMAGENET TOP-5 ERROR")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("2012")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(axInkSubtle.opacity(0.7))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", animatedError))
                    .font(.system(size: 56, weight: .regular, design: .serif))
                    .foregroundStyle(tealAccent)
                    .contentTransition(.numericText(value: animatedError))
                Text("%")
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(axInkSubtle)
                Spacer()
                deltaChip
            }

            // Bar from baseline → target
            GeometryReader { geo in
                let range = alexBaselinePct - alexTargetPct
                let frac = max(0, min(1, (alexBaselinePct - animatedError) / max(0.001, range)))
                ZStack(alignment: .leading) {
                    Capsule().fill(amberAccent.opacity(0.18))
                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.55), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(frac))
                }
            }
            .frame(height: 8)

            HStack {
                Text("baseline 25.6%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(amberAccent)
                Spacer()
                Text("AlexNet 16.0%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(tealAccent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(axPanelEdge, lineWidth: 1))
        )
    }

    private var deltaChip: some View {
        let delta = alexBaselinePct - animatedError
        let label = delta < 0.05 ? "no improvement" : "−\(String(format: "%.1f", delta)) pt"
        let color: Color = delta < 0.05 ? axInkSubtle : tealAccent
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color.opacity(0.10))
                    .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.8))
            )
    }

    private var togglesPanel: some View {
        VStack(spacing: 10) {
            ForEach(AlexTrick.allCases) { t in
                trickRow(t)
            }
        }
    }

    @ViewBuilder
    private func trickRow(_ t: AlexTrick) -> some View {
        let isOn = on.contains(t)
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                if isOn { on.remove(t) } else { on.insert(t) }
            }
            visited.insert(t)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOn ? tealAccent : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isOn ? Color.clear : axPanelEdge, lineWidth: 1))
                        .frame(width: 22, height: 22)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(axInk)
                    Text(t.subtitle)
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(axInkSubtle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(isOn ? "−\(String(format: "%.1f", t.deltaPct))" : "+\(String(format: "%.1f", t.deltaPct))")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isOn ? tealAccent : amberAccent)
                    Text("pt")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(axInkSubtle.opacity(0.7))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isOn ? axPanelBg : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(axPanelEdge, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

// =============================================================================
// MARK: - Card 05, ReLU Race
// =============================================================================

private enum AlexAct: Int, CaseIterable, Identifiable {
    case relu, tanh, sigmoid
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .relu:    return "ReLU"
        case .tanh:    return "tanh"
        case .sigmoid: return "sigmoid"
        }
    }

    var formula: String {
        switch self {
        case .relu:    return "max(0, x)"
        case .tanh:    return "tanh(x)"
        case .sigmoid: return "1 / (1 + e⁻ˣ)"
        }
    }

    var color: Color {
        switch self {
        case .relu:    return tealAccent
        case .tanh:    return amberAccent
        case .sigmoid: return Color(hex: "7b4ba4")
        }
    }

    var epochsToTarget: Int {
        switch self {
        case .relu:    return 6
        case .tanh:    return 36
        case .sigmoid: return 80
        }
    }

    var verdict: String {
        switch self {
        case .relu:    return "Linear in the positive region. No vanishing gradient. Krizhevsky's six-fold speedup, the canonical plot."
        case .tanh:    return "Saturates at both ends. Gradients vanish on either tail, training crawls past the inflection."
        case .sigmoid: return "Tail-bound. Gradient at extremes is near zero. Almost never converges in deep stacks."
        }
    }

    // Hardcoded training error curve. 41 sample points over 0...40 epochs.
    func curve(at epoch: Double) -> Double {
        // Exponential-ish decay toward floor, scaled by activation speed.
        let floor = 0.18
        let initial = 0.92
        let k: Double
        switch self {
        case .relu:    k = 0.45
        case .tanh:    k = 0.075
        case .sigmoid: k = 0.030
        }
        return floor + (initial - floor) * exp(-k * epoch)
    }
}

struct AlexNetReluRaceView: View {
    @ObservedObject var state: DailyLoopState
    @State private var visible: Set<AlexAct> = [.relu]
    @State private var visited: Set<AlexAct> = [.relu]
    @State private var hovered: AlexAct = .relu
    @State private var anim: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · TRAINING SPEED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Six times faster. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(axInk)
                + Text("That's the whole story.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap each activation to add its training curve. ReLU hits 25% error in 6 epochs. tanh needs 36. Sigmoid almost never gets there.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                actChips
                    .padding(.bottom, 14)

                curvePanel
                    .padding(.bottom, 16)

                statRow
                    .padding(.bottom, 14)

                Text(hovered.verdict)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(hovered.color)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            updateGate()
            withAnimation(.easeInOut(duration: 1.4)) { anim = 1 }
        }
    }

    private func updateGate() {
        if visited.count >= AlexAct.allCases.count {
            state.customCardComplete.insert(4)
        }
    }

    private var actChips: some View {
        HStack(spacing: 8) {
            ForEach(AlexAct.allCases) { a in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        if visible.contains(a) && visible.count > 1 {
                            visible.remove(a)
                        } else {
                            visible.insert(a)
                        }
                        hovered = a
                    }
                    visited.insert(a)
                    updateGate()
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(a.color).frame(width: 8, height: 8)
                        Text(a.name)
                            .font(.system(size: 11, weight: visible.contains(a) ? .semibold : .regular, design: .serif))
                            .foregroundStyle(visible.contains(a) ? axInk : axInkSubtle)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(visible.contains(a) ? a.color.opacity(0.10) : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(visible.contains(a) ? a.color.opacity(0.45) : axPanelEdge, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var curvePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TRAINING ERROR · 0 → 40 EPOCHS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("target = 25%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(axInkSubtle.opacity(0.7))
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Y grid + ticks
                    ForEach(0..<5) { i in
                        let y = h * CGFloat(i) / 4
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(axPanelEdge.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    }

                    // 25% target line
                    let tY = h * CGFloat(1 - 0.25)
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: tY))
                        p.addLine(to: CGPoint(x: w, y: tY))
                    }
                    .stroke(tealAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1.0, dash: [4, 3]))

                    Text("25%")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(tealAccent)
                        .position(x: w - 18, y: tY - 8)

                    // Activation curves
                    ForEach(AlexAct.allCases) { a in
                        if visible.contains(a) {
                            curvePath(a, w: w, h: h)
                                .trim(from: 0, to: max(0.05, min(1, anim)))
                                .stroke(a.color, style: StrokeStyle(lineWidth: a == hovered ? 2.2 : 1.6, lineCap: .round))
                        }
                    }
                }
            }
            .frame(height: 200)

            HStack {
                Text("0")
                Spacer()
                Text("10")
                Spacer()
                Text("20")
                Spacer()
                Text("30")
                Spacer()
                Text("40 epochs")
            }
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .foregroundStyle(axInkSubtle.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(axPanelEdge, lineWidth: 1))
        )
    }

    private func curvePath(_ a: AlexAct, w: CGFloat, h: CGFloat) -> Path {
        Path { p in
            let steps = 80
            for i in 0...steps {
                let frac = Double(i) / Double(steps)
                let epoch = frac * 40
                let err = a.curve(at: epoch)
                let x = w * CGFloat(frac)
                let y = h * CGFloat(1 - err)
                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                else      { p.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            ForEach(AlexAct.allCases) { a in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle().fill(a.color).frame(width: 7, height: 7)
                        Text(a.name)
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundStyle(axInk)
                    }
                    Text("\(a.epochsToTarget)")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(a.color)
                    Text("epochs to 25%")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(axInkSubtle.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(a == hovered ? axPanelBg : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(axPanelEdge, lineWidth: 1))
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        hovered = a
                        visible.insert(a)
                    }
                    visited.insert(a)
                    updateGate()
                }
            }
        }
    }
}

// =============================================================================
// MARK: - Card 06, The 2012 Cliff
// =============================================================================

private struct ImageNetEntry: Identifiable, Hashable {
    let id: String
    let year: String
    let team: String
    let method: String
    let topFive: Double          // top-5 error %
    let isAlexNet: Bool
    let blurb: String
}

private let cliffEntries: [ImageNetEntry] = [
    ImageNetEntry(id: "2010",
                  year: "2010",
                  team: "NEC + UIUC",
                  method: "SIFT + Fisher",
                  topFive: 28.2,
                  isAlexNet: false,
                  blurb: "Hand-crafted SIFT features fed into a linear SVM. The state of the art and the consensus method for ten years."),
    ImageNetEntry(id: "2011",
                  year: "2011",
                  team: "XRCE",
                  method: "Fisher Vectors",
                  topFive: 25.8,
                  isAlexNet: false,
                  blurb: "Compressed Fisher Vectors over dense SIFT. A 2.4-point improvement, still hand engineered, still the same school of thought."),
    ImageNetEntry(id: "2012-runner",
                  year: "2012",
                  team: "ISI Tokyo",
                  method: "SIFT + FV (runner-up)",
                  topFive: 26.2,
                  isAlexNet: false,
                  blurb: "The 2012 runner-up. Still hand-crafted features. Confirms the hand-engineered ceiling: roughly 26% top-5 error, period."),
    ImageNetEntry(id: "2012-alex",
                  year: "2012",
                  team: "U. of Toronto",
                  method: "AlexNet (CNN)",
                  topFive: 16.4,
                  isAlexNet: true,
                  blurb: "AlexNet. 16.4% top-5 error. A 10-point drop, almost double the gap that separated the previous five winners combined."),
]

struct AlexNetCliffView: View {
    @ObservedObject var state: DailyLoopState
    @State private var selected: String = "2012-alex"
    @State private var visited: Set<String> = ["2012-alex"]
    @State private var animFrac: Double = 1

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · THE 2012 CLIFF")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Three years. ").font(.system(size: 24, weight: .regular, design: .serif)).foregroundStyle(axInk)
                + Text("One phase transition.").font(.system(size: 24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("ImageNet top-5 error. Tap any year to see the team and method. The runner-up in 2012 still used hand-crafted features and landed where the trend predicted.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                cliffPanel
                    .padding(.bottom, 16)

                detailPanel
                    .padding(.bottom, 14)

                Text(currentEntry.blurb)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(currentEntry.isAlexNet ? tealAccent : axInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            updateGate()
        }
    }

    private func updateGate() {
        if visited.count >= cliffEntries.count {
            state.customCardComplete.insert(5)
        }
    }

    private var currentEntry: ImageNetEntry {
        cliffEntries.first(where: { $0.id == selected }) ?? cliffEntries.last!
    }

    private var cliffPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TOP-5 ERROR (%)")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("lower = better")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(axInkSubtle.opacity(0.7))
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let yMax: Double = 32
                let pad: CGFloat = 24

                ZStack(alignment: .topLeading) {
                    // Y grid
                    ForEach(0..<5) { i in
                        let frac = CGFloat(i) / 4
                        let y = h * frac
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(axPanelEdge.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    }

                    // Hand-crafted ceiling band ~26-28%
                    let bandTop = h * CGFloat(1 - 28.0 / yMax)
                    let bandBot = h * CGFloat(1 - 25.0 / yMax)
                    Rectangle()
                        .fill(amberAccent.opacity(0.10))
                        .frame(height: bandBot - bandTop)
                        .position(x: w / 2, y: (bandTop + bandBot) / 2)
                    Text("hand-crafted ceiling")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(amberAccent)
                        .position(x: 78, y: bandTop + 6)

                    // Bars
                    let count = cliffEntries.count
                    let usable = w - pad
                    let slot = usable / CGFloat(count)
                    ForEach(Array(cliffEntries.enumerated()), id: \.element.id) { (i, e) in
                        let cx = pad / 2 + slot * (CGFloat(i) + 0.5)
                        let valFrac = CGFloat(e.topFive / yMax) * CGFloat(animFrac)
                        let barH = h * valFrac
                        let barY = h - barH
                        let isSel = e.id == selected
                        let color: Color = e.isAlexNet ? tealAccent : amberAccent

                        // bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [color.opacity(0.55), color], startPoint: .top, endPoint: .bottom))
                            .frame(width: 38, height: max(4, barH))
                            .position(x: cx, y: barY + barH / 2)
                            .opacity(isSel ? 1 : 0.7)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                    selected = e.id
                                }
                                visited.insert(e.id)
                                updateGate()
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }

                        // value tag
                        Text(String(format: "%.1f", e.topFive))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(color)
                            .position(x: cx, y: barY - 10)

                        // year label
                        Text(e.year)
                            .font(.system(size: 9, weight: isSel ? .bold : .semibold, design: .serif))
                            .foregroundStyle(isSel ? axInk : axInkSubtle)
                            .position(x: cx, y: h + 12)

                        // selected indicator
                        if isSel {
                            Circle()
                                .stroke(color, lineWidth: 1.5)
                                .frame(width: 6, height: 6)
                                .position(x: cx, y: barY - 22)
                        }
                    }

                    // CLIFF annotation between runner-up and AlexNet
                    let runnerIdx = 2; let alexIdx = 3
                    let xR = pad / 2 + slot * (CGFloat(runnerIdx) + 0.5)
                    let xA = pad / 2 + slot * (CGFloat(alexIdx) + 0.5)
                    let yR = h - h * CGFloat(26.2 / yMax)
                    let yA = h - h * CGFloat(16.4 / yMax)
                    Path { p in
                        p.move(to: CGPoint(x: xR + 22, y: yR))
                        p.addLine(to: CGPoint(x: xA - 22, y: yA))
                    }
                    .stroke(tealAccent.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))

                    Text("−9.8 pt")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(tealAccent))
                        .position(x: (xR + xA) / 2, y: (yR + yA) / 2 - 8)
                }
            }
            .frame(height: 220)
            .padding(.bottom, 14)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(axPanelEdge, lineWidth: 1))
        )
    }

    private var detailPanel: some View {
        let e = currentEntry
        let color: Color = e.isAlexNet ? tealAccent : amberAccent
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(e.year) · \(e.team.uppercased())")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(color.opacity(0.85))
                Spacer()
                if e.isAlexNet {
                    Text("DEEP LEARNING")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(tealAccent))
                } else {
                    Text("HAND CRAFTED")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(amberAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(amberAccent.opacity(0.10))
                            .overlay(Capsule().stroke(amberAccent.opacity(0.4), lineWidth: 0.8)))
                }
            }
            Text(e.method)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(axInk)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", e.topFive))
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundStyle(color)
                Text("% top-5 error")
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(axInkSubtle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(axPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(axPanelEdge, lineWidth: 1))
        )
    }
}

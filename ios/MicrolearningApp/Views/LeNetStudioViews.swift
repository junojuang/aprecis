import SwiftUI

// MARK: - Premium interactive cards for "Gradient-Based Learning Applied to
//                                       Document Recognition" (LeNet-5)
//
// Three bespoke cards that replace the generic flow + bar-chart slots for
// LeCun et al. (1998). Design language mirrors the AlexNet / Word2Vec studios.
//
//   Card 04, LeNetFilterView
//      "One filter, slid everywhere." Pick a filter (edge, curve, corner).
//      Drag a window across the digit. The activation map lights up where
//      the filter fires. Translation invariance, made visible.
//
//   Card 05, LeNetReceptiveView
//      "The patch grows with depth." Tap a layer. The diagram zooms to show
//      what one unit at that layer can see in the original 32×32 input.
//      Conv1: 5px. Pool1: 6px. Conv2: 14px. FC: the whole digit.
//
//   Card 06, LeNetParamView
//      "Same accuracy, fraction of weights." Toggle Conv vs FC for the same
//      receptive field. The parameter bar swells 5,000×; accuracy holds. The
//      whole argument for spatial structure in one chart.

private let lnInk        = inkColor
private let lnInkSubtle  = inkColor.opacity(0.65)
private let lnPanelBg    = Color(hex: "f4ece0")
private let lnPanelEdge  = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Sliding Filter
// =============================================================================

private enum LNFilter: Int, CaseIterable, Identifiable {
    case hEdge, vEdge, diag, corner
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .hEdge:  return "h-edge"
        case .vEdge:  return "v-edge"
        case .diag:   return "diagonal"
        case .corner: return "corner"
        }
    }

    /// 5×5 kernel as 25 doubles, −1...+1.
    var kernel: [Double] {
        switch self {
        case .hEdge:  return [
             1, 1, 1, 1, 1,
             1, 1, 1, 1, 1,
             0, 0, 0, 0, 0,
            -1,-1,-1,-1,-1,
            -1,-1,-1,-1,-1,
        ]
        case .vEdge:  return [
             1, 1, 0,-1,-1,
             1, 1, 0,-1,-1,
             1, 1, 0,-1,-1,
             1, 1, 0,-1,-1,
             1, 1, 0,-1,-1,
        ]
        case .diag:   return [
             1, 1, 0,-1,-1,
             1, 1, 1,-1,-1,
             0, 1, 1, 1, 0,
            -1,-1, 1, 1, 1,
            -1,-1, 0, 1, 1,
        ]
        case .corner: return [
             1, 1, 1, 0, 0,
             1, 1, 1, 0, 0,
             1, 1, 0, 0, 0,
             0, 0, 0, 0, 0,
             0, 0, 0, 0, 0,
        ]
        }
    }

    var verdict: String {
        switch self {
        case .hEdge:  return "Horizontal edge filter. Fires along the top of the 5 and the crossbar of the 4. Same filter, different positions, no extra weights."
        case .vEdge:  return "Vertical edge filter. Lights up the strokes of the 1 and the right side of the 9. Translation invariance is just sliding the same template."
        case .diag:   return "Diagonal filter. Picks up the slants in the 7 and the curves of the 3. Conv2 will combine these into corners."
        case .corner: return "Corner filter. Highlights where strokes meet, the elbow of an L, the join of a T. Higher layers stack these into whole digits."
        }
    }
}

// 16×16 stylised digit (a 7) for the canvas. 1 = ink, 0 = paper.
private let lnDigit: [[Int]] = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0],
    [0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
]

struct LeNetFilterView: View {
    @ObservedObject var state: DailyLoopState
    @State private var filter: LNFilter = .hEdge
    @State private var visited: Set<LNFilter> = [.hEdge]
    @State private var winRow: Int = 5
    @State private var winCol: Int = 5
    @State private var dragSeen: Set<Int> = []

    private let gridSize = 16
    private let kernSize = 5

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 04 · ONE FILTER, EVERYWHERE")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Pick a filter. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(lnInk)
                + Text("Slide it across the digit.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("The same 5×5 kernel slides over every position. Activations highlight where the pattern fires. Translation invariance for free.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                filterChips
                    .padding(.bottom, 14)

                canvasPanel
                    .padding(.bottom, 16)

                kernelInspector
                    .padding(.bottom, 14)

                Text(filter.verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(lnInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
    }

    private func updateGate() {
        if visited.count >= LNFilter.allCases.count && dragSeen.count >= 4 {
            state.customCardComplete.insert(3)
        }
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(LNFilter.allCases) { f in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        filter = f
                    }
                    visited.insert(f)
                    updateGate()
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Text(f.name)
                        .font(scaledSystemFont(11, weight: filter == f ? .semibold : .regular, design: .serif))
                        .foregroundStyle(filter == f ? .white : lnInkSubtle)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(filter == f ? tealAccent : Color.white)
                                .overlay(Capsule().stroke(lnPanelEdge, lineWidth: filter == f ? 0 : 1))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var canvasPanel: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Pick the largest cell that fits in BOTH dimensions. Sizing by
            // width alone overflowed the fixed 280pt frame on wider phones
            // because cell·gridSize + topOffset exceeded the available height.
            let cellFromW = floor((w - 32) / CGFloat(gridSize))
            let cellFromH = floor((h - 32) / CGFloat(gridSize))
            let cell: CGFloat = max(1, min(cellFromW, cellFromH))
            let totalW = cell * CGFloat(gridSize)
            let totalH = cell * CGFloat(gridSize)
            let xOff = (w - totalW) / 2
            let yOff = max(8, (h - totalH) / 2)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(lnPanelEdge, lineWidth: 1))

                // Activation heatmap (responds to filter sweep)
                ForEach(0..<gridSize, id: \.self) { r in
                    ForEach(0..<gridSize, id: \.self) { c in
                        let act = activation(at: r, c: c)
                        Rectangle()
                            .fill(tealAccent.opacity(act))
                            .frame(width: cell, height: cell)
                            .position(x: xOff + CGFloat(c) * cell + cell/2,
                                      y: yOff + CGFloat(r) * cell + cell/2)
                    }
                }

                // Digit overlay
                ForEach(0..<gridSize, id: \.self) { r in
                    ForEach(0..<gridSize, id: \.self) { c in
                        if lnDigit[r][c] == 1 {
                            Rectangle()
                                .fill(lnInk.opacity(0.85))
                                .frame(width: cell - 0.5, height: cell - 0.5)
                                .position(x: xOff + CGFloat(c) * cell + cell/2,
                                          y: yOff + CGFloat(r) * cell + cell/2)
                        }
                    }
                }

                // Window outline
                let wx = xOff + CGFloat(winCol) * cell
                let wy: CGFloat = yOff + CGFloat(winRow) * cell
                RoundedRectangle(cornerRadius: 3)
                    .stroke(amberAccent, lineWidth: 2)
                    .frame(width: cell * CGFloat(kernSize), height: cell * CGFloat(kernSize))
                    .position(x: wx + cell * CGFloat(kernSize) / 2,
                              y: wy + cell * CGFloat(kernSize) / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let col = Int(((v.location.x - xOff) / cell) - CGFloat(kernSize) / 2)
                        let row = Int(((v.location.y - yOff) / cell) - CGFloat(kernSize) / 2)
                        let newCol = max(0, min(gridSize - kernSize, col))
                        let newRow = max(0, min(gridSize - kernSize, row))
                        if newCol != winCol || newRow != winRow {
                            winCol = newCol
                            winRow = newRow
                            dragSeen.insert(newRow * gridSize + newCol)
                            if dragSeen.count % 6 == 0 {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                            updateGate()
                        }
                    }
            )
        }
        .frame(height: 280)
    }

    private func activation(at r: Int, c: Int) -> Double {
        // Convolve filter centred at (r,c). Skip near edges.
        guard r >= kernSize/2 && r < gridSize - kernSize/2,
              c >= kernSize/2 && c < gridSize - kernSize/2 else { return 0 }
        let k = filter.kernel
        var sum: Double = 0
        for kr in 0..<kernSize {
            for kc in 0..<kernSize {
                let ir = r - kernSize/2 + kr
                let ic = c - kernSize/2 + kc
                sum += k[kr * kernSize + kc] * Double(lnDigit[ir][ic])
            }
        }
        // Normalise to 0...1 with a soft floor; ReLU clips negatives.
        return max(0, min(1, sum / 6.0))
    }

    private var kernelInspector: some View {
        HStack(spacing: 14) {
            // Tiny kernel visualisation
            VStack(spacing: 2) {
                ForEach(0..<kernSize, id: \.self) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<kernSize, id: \.self) { c in
                            let v = filter.kernel[r * kernSize + c]
                            Rectangle()
                                .fill(v > 0 ? tealAccent.opacity(min(1, v))
                                            : amberAccent.opacity(min(1, -v)))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("KERNEL · 5×5 · 25 WEIGHTS")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Text("Same 25 weights at every position. A dense layer of comparable receptive field would need ~780,000 weights to do the same job.")
                    .font(scaledSystemFont(11, design: .serif))
                    .foregroundStyle(lnInk)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(lnPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(lnPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Card 05, Receptive Field Pyramid
// =============================================================================

private enum LNLayer: Int, CaseIterable, Identifiable {
    case conv1, pool1, conv2, fc
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .conv1: return "Conv1"
        case .pool1: return "Pool1"
        case .conv2: return "Conv2"
        case .fc:    return "FC"
        }
    }

    var subtitle: String {
        switch self {
        case .conv1: return "edges"
        case .pool1: return "halve"
        case .conv2: return "junctions"
        case .fc:    return "the digit"
        }
    }

    /// Receptive field size in original-image pixels.
    var rf: Int {
        switch self {
        case .conv1: return 5
        case .pool1: return 6
        case .conv2: return 14
        case .fc:    return 32
        }
    }

    var verdict: String {
        switch self {
        case .conv1: return "Conv1: 5×5 receptive field. Each unit sees a 5-pixel patch. Filters learn edges, curves, gradients."
        case .pool1: return "After 2× downsampling, each new unit covers 6 pixels of the original input. Cheap effective field doubling."
        case .conv2: return "Conv2: 14×14 effective field. Filters now combine edges into corners and junctions across a quarter of the image."
        case .fc:    return "Final layer sees the whole 32×32. Each unit responds to a holistic shape, a 7, an 8, a loop."
        }
    }
}

struct LeNetReceptiveView: View {
    @ObservedObject var state: DailyLoopState
    @State private var active: LNLayer = .conv1
    @State private var visited: Set<LNLayer> = [.conv1]

    private let canvasSize: Int = 32

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · DEPTH GROWS THE PATCH")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Each layer ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(lnInk)
                + Text("sees a wider patch.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap any layer. The amber square shows what one unit at that layer can see in the original input. Five pixels at the bottom, the entire image at the top.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                stackChips
                    .padding(.bottom, 14)

                inputCanvas
                    .padding(.bottom, 16)

                statRow
                    .padding(.bottom, 14)

                Text(active.verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(lnInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
    }

    private func updateGate() {
        if visited.count >= LNLayer.allCases.count {
            state.customCardComplete.insert(4)
        }
    }

    private var stackChips: some View {
        VStack(spacing: 6) {
            ForEach(LNLayer.allCases.reversed()) { l in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        active = l
                    }
                    visited.insert(l)
                    updateGate()
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    HStack(spacing: 12) {
                        Text(l.name)
                            .font(scaledSystemFont(12, weight: active == l ? .semibold : .regular, design: .serif))
                            .foregroundStyle(active == l ? .white : lnInk)
                            .frame(width: 60, alignment: .leading)
                        Text(l.subtitle)
                            .font(scaledSystemFont(10, design: .serif))
                            .foregroundStyle(active == l ? .white.opacity(0.8) : lnInkSubtle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(l.rf)px")
                            .font(scaledSystemFont(11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(active == l ? .white : tealAccent)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(active == l ? tealAccent : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(lnPanelEdge, lineWidth: active == l ? 0 : 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var inputCanvas: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let canvasW = min(w - 24, 240)
            let cell = canvasW / CGFloat(canvasSize)
            let xOff = (w - canvasW) / 2
            let yOff: CGFloat = 12
            // Centre the receptive-field overlay
            let rf = active.rf
            let centre = canvasSize / 2
            let half = rf / 2
            let startCol = max(0, centre - half)
            let startRow = max(0, centre - half)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(lnPanelEdge, lineWidth: 1))

                // Faint pixel grid
                ForEach(0..<canvasSize, id: \.self) { r in
                    ForEach(0..<canvasSize, id: \.self) { c in
                        Rectangle()
                            .stroke(lnPanelEdge.opacity(0.35), lineWidth: 0.4)
                            .frame(width: cell, height: cell)
                            .position(x: xOff + CGFloat(c) * cell + cell/2,
                                      y: yOff + CGFloat(r) * cell + cell/2)
                    }
                }

                // Stylised digit (re-use lnDigit, scaled to 32×32 by rough mapping)
                ForEach(0..<canvasSize, id: \.self) { r in
                    ForEach(0..<canvasSize, id: \.self) { c in
                        let dr = min(15, r * 16 / canvasSize)
                        let dc = min(15, c * 16 / canvasSize)
                        if lnDigit[dr][dc] == 1 {
                            Rectangle()
                                .fill(lnInk.opacity(0.85))
                                .frame(width: cell, height: cell)
                                .position(x: xOff + CGFloat(c) * cell + cell/2,
                                          y: yOff + CGFloat(r) * cell + cell/2)
                        }
                    }
                }

                // Receptive-field overlay
                Rectangle()
                    .fill(amberAccent.opacity(0.18))
                    .overlay(Rectangle().stroke(amberAccent, lineWidth: 2))
                    .frame(width: cell * CGFloat(rf), height: cell * CGFloat(rf))
                    .position(x: xOff + CGFloat(startCol) * cell + cell * CGFloat(rf)/2,
                              y: yOff + CGFloat(startRow) * cell + cell * CGFloat(rf)/2)
                    .motionAware(.spring(response: 0.45, dampingFraction: 0.8), value: active)
            }
        }
        .frame(height: 270)
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            statTile(label: "RF",   value: "\(active.rf)px",                       color: amberAccent)
            statTile(label: "PCT",  value: String(format: "%.0f%%", Double(active.rf * active.rf) / Double(canvasSize * canvasSize) * 100),
                     color: tealAccent)
            statTile(label: "STAGE", value: active.name, color: Color(hex: "7b4ba4"))
        }
    }

    private func statTile(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(scaledSystemFont(9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(lnInkSubtle.opacity(0.7))
            Text(value)
                .font(scaledSystemFont(16, weight: .semibold, design: .serif))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(lnPanelEdge, lineWidth: 1))
        )
    }
}

// =============================================================================
// MARK: - Card 06, Param Savings Race
// =============================================================================

private enum LNVariant: String, CaseIterable, Identifiable {
    case conv, dense
    var id: String { rawValue }

    var name: String {
        switch self {
        case .conv:  return "Conv (5×5)"
        case .dense: return "Fully connected"
        }
    }

    var paramK: Double {
        switch self {
        case .conv:  return 0.156   // 156 weights → shown in thousands
        case .dense: return 780.0   // ~780k weights
        }
    }

    var accuracy: Double {
        switch self {
        case .conv:  return 0.992
        case .dense: return 0.870
        }
    }
}

struct LeNetParamView: View {
    @ObservedObject var state: DailyLoopState
    @State private var visible: Set<LNVariant> = [.conv, .dense]
    @State private var active: LNVariant = .conv
    @State private var visited: Set<LNVariant> = [.conv, .dense]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 06 · PARAM SAVINGS")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Same accuracy. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(lnInk)
                + Text("A fraction of the weights.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Tap a layer. Conv (teal) reuses one filter across the whole image. Dense (amber) gives every pixel its own weight. Five thousand times more parameters, no accuracy gain.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                variantChips
                    .padding(.bottom, 14)

                paramBars
                    .padding(.bottom, 14)

                accuracyTile
                    .padding(.bottom, 14)

                Text(verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .italic()
                    .foregroundStyle(lnInkSubtle)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { updateGate() }
    }

    private func updateGate() {
        if visited.count >= LNVariant.allCases.count {
            state.customCardComplete.insert(5)
        }
    }

    private var verdict: String {
        switch active {
        case .conv:
            return "Conv layer: 156 weights for the whole image. 99.2% on MNIST. The architecture respects the spatial structure."
        case .dense:
            return "Fully connected at the same receptive field: ~780,000 weights. 87% on MNIST. More parameters, worse generalisation, the lesson of LeNet."
        }
    }

    private var variantChips: some View {
        HStack(spacing: 8) {
            ForEach(LNVariant.allCases) { v in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        active = v
                    }
                    visited.insert(v)
                    updateGate()
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(v == .conv ? tealAccent : amberAccent)
                            .frame(width: 8, height: 8)
                        Text(v.name)
                            .font(scaledSystemFont(11, weight: active == v ? .semibold : .regular, design: .serif))
                            .foregroundStyle(active == v ? lnInk : lnInkSubtle)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(active == v
                                  ? (v == .conv ? tealAccent.opacity(0.10) : amberAccent.opacity(0.12))
                                  : Color.white)
                            .overlay(Capsule().stroke(lnPanelEdge, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var paramBars: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRAINABLE PARAMETERS")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("LOG SCALE")
                    .font(scaledSystemFont(8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(lnInkSubtle.opacity(0.7))
            }

            ForEach(LNVariant.allCases) { v in
                paramRow(v)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(lnPanelEdge, lineWidth: 1))
        )
    }

    private func paramRow(_ v: LNVariant) -> some View {
        let color: Color = v == .conv ? tealAccent : amberAccent
        // Log10 mapping: 0.156k → ~5.2; 780k → ~5.89. Map to 0...1 width.
        let log = log10(max(v.paramK * 1000, 1))
        let frac = min(1, max(0, (log - 1.5) / 4.5))
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(v.name)
                    .font(scaledSystemFont(11, weight: .semibold, design: .serif))
                    .foregroundStyle(active == v ? color : lnInk)
                Spacer()
                Text(formatWeights(v.paramK))
                    .font(scaledSystemFont(12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.6), color],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * frac)
                }
            }
            .frame(height: 10)
        }
    }

    private func formatWeights(_ k: Double) -> String {
        let weights = Int(k * 1000)
        if weights >= 1000 {
            return String(format: "%.0fk weights", Double(weights) / 1000)
        }
        return "\(weights) weights"
    }

    private var accuracyTile: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MNIST ACCURACY")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
            }
            HStack(spacing: 16) {
                ForEach(LNVariant.allCases) { v in
                    accColumn(v)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(lnPanelBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(lnPanelEdge, lineWidth: 1))
        )
    }

    private func accColumn(_ v: LNVariant) -> some View {
        let color: Color = v == .conv ? tealAccent : amberAccent
        return VStack(alignment: .leading, spacing: 4) {
            Text(v.name)
                .font(scaledSystemFont(9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(lnInkSubtle)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", v.accuracy * 100))
                    .font(scaledSystemFont(28, weight: .regular, design: .serif))
                    .foregroundStyle(color)
                Text("%")
                    .font(scaledSystemFont(14, design: .serif))
                    .foregroundStyle(lnInkSubtle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

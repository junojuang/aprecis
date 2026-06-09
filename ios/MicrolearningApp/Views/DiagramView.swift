import SwiftUI

// MARK: - Dispatcher

struct DiagramView: View {
    let spec: DiagramSpec

    var body: some View {
        Group {
            switch spec.type {
            case .flow:
                if let nodes = spec.nodes {
                    FlowDiagram(nodes: nodes, edges: spec.edges ?? [], caption: spec.caption)
                }
            case .barChart:
                if let bars = spec.bars {
                    BarChartDiagram(bars: bars, yLabel: spec.yLabel, caption: spec.caption)
                }
            case .comparison:
                if let items = spec.items {
                    ComparisonDiagram(
                        leftLabel: spec.leftLabel ?? "Before",
                        rightLabel: spec.rightLabel ?? "After",
                        items: items,
                        caption: spec.caption
                    )
                }
            case .attentionHeatmap:
                if let tokens = spec.tokens, let weights = spec.weights {
                    AttentionHeatmapDiagram(tokens: tokens, weights: weights)
                }
            case .multiHead:
                if let heads = spec.heads, let tokens = spec.tokens {
                    MultiHeadDiagram(heads: heads, tokens: tokens)
                }
            case .sineWaves:
                SineWavesDiagram(caption: spec.caption)
            case .cycle:
                if let steps = spec.steps, !steps.isEmpty {
                    CycleDiagram(steps: steps, caption: spec.caption)
                }
            case .numberBox:
                if let value = spec.value, !value.isEmpty {
                    NumberBoxDiagram(
                        value: value,
                        label: spec.valueLabel ?? "",
                        sublabel: spec.valueSublabel,
                        caption: spec.caption
                    )
                }
            case .equation:
                if let formula = spec.formula, !formula.isEmpty {
                    EquationDiagram(formula: formula, terms: spec.terms ?? [], caption: spec.caption)
                }
            case .custom:
                EmptyView()
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

// MARK: - Attention Heatmap

struct AttentionHeatmapDiagram: View {
    let tokens: [String]
    let weights: [[Double]]
    @State private var activeRow: Int? = nil

    private let cellSize: CGFloat = 34
    private let teal = Color(hex: "1a8a8a")
    private let muted = Color(hex: "8a8f9a")

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Column headers
            HStack(spacing: 0) {
                Spacer().frame(width: cellSize + 4)
                ForEach(tokens.indices, id: \.self) { j in
                    Text(tokens[j])
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(activeRow == j ? teal : muted)
                        .frame(width: cellSize)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.bottom, 2)

            // Rows
            ForEach(weights.indices, id: \.self) { i in
                rowView(i)
            }

            // Legend
            HStack(spacing: 6) {
                Spacer().frame(width: cellSize + 4)
                LinearGradient(
                    gradient: Gradient(colors: [teal.opacity(0.05), teal.opacity(0.95)]),
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 52, height: 5)
                .clipShape(Capsule())

                Text("low → high")
                    .font(.system(size: 8))
                    .foregroundStyle(muted)

                Spacer()

                if let row = activeRow, row < tokens.count {
                    Text("\"\(tokens[row])\" attends →")
                        .font(.system(size: 8))
                        .italic()
                        .foregroundStyle(teal)
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func rowView(_ i: Int) -> some View {
        let isActive = activeRow == i
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                activeRow = activeRow == i ? nil : i
            }
        } label: {
            HStack(spacing: 0) {
                Text(i < tokens.count ? tokens[i] : "")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isActive ? teal : muted)
                    .frame(width: cellSize, alignment: .trailing)
                    .padding(.trailing, 4)

                ForEach(weights[i].indices, id: \.self) { j in
                    let w = weights[i][j]
                    let alpha = isActive ? min(w * 1.35, 0.98) : w * 0.88
                    let dimmed = (activeRow != nil && !isActive) ? 0.3 : 1.0

                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(teal.opacity(alpha))
                            .frame(width: cellSize - 2, height: cellSize - 2)
                            .opacity(dimmed)

                        if isActive && w > 0.12 {
                            Text("\(Int(w * 100))")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(w > 0.35 ? .white : teal)
                        }
                    }
                    .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Multi-Head Attention

struct MultiHeadDiagram: View {
    let heads: [HeadSpec]
    let tokens: [String]
    @State private var activeHead: Int? = nil

    var body: some View {
        VStack(spacing: 4) {
            Text("Tap a head to inspect")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color(hex: "8a8f9a"))
                .textCase(.uppercase)
                .padding(.bottom, 4)

            ForEach(heads.indices, id: \.self) { i in
                headRow(i)
            }
        }
    }

    @ViewBuilder
    private func headRow(_ i: Int) -> some View {
        let head = heads[i]
        let isActive = activeHead == i
        let headColor = Color(hex: head.color)

        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeHead = activeHead == i ? nil : i
                }
            } label: {
                HStack(spacing: 5) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("H\(i + 1)")
                            .font(.system(size: 7, weight: .bold))
                        Text(head.name)
                            .font(.system(size: 7))
                    }
                    .foregroundStyle(isActive ? headColor : Color(hex: "8a8f9a"))
                    .frame(width: 44, alignment: .trailing)

                    ForEach(head.weights.indices, id: \.self) { j in
                        let w = head.weights[j]
                        let barH: CGFloat = isActive ? 26 : 15
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(headColor.opacity(w * 0.92 + 0.04))
                                .frame(height: barH)
                            if isActive && w > 0.2 && j < tokens.count {
                                Text(tokens[j])
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.plain)

            if isActive {
                HStack(spacing: 0) {
                    Spacer().frame(width: 49)
                    (Text("Head \(i + 1) · ") + Text(head.name).bold() + Text(": \(head.desc)"))
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "1a8a8a"))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(hex: "e8f5f5"))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Sine Waves (Positional Encoding)

struct SineWavesDiagram: View {
    let caption: String?
    @State private var progress: Double = 0

    private struct Wave {
        let freq: Double; let color: Color; let lineWidth: CGFloat; let opacity: Double; let label: String
    }

    private let waves: [Wave] = [
        Wave(freq: 1, color: Color(hex: "1a8a8a"), lineWidth: 2.0, opacity: 0.95, label: "dim 0 (f=1×)"),
        Wave(freq: 2, color: Color(hex: "e8a020"), lineWidth: 1.6, opacity: 0.85, label: "dim 1 (f=2×)"),
        Wave(freq: 4, color: Color(hex: "7b4ba4"), lineWidth: 1.4, opacity: 0.75, label: "dim 2 (f=4×)"),
        Wave(freq: 8, color: Color(hex: "2d7abf"), lineWidth: 1.2, opacity: 0.65, label: "dim 3 (f=8×)"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            Canvas { ctx, size in
                let steps = 60
                let drawn = Int(Double(steps) * progress)
                guard drawn > 0 else { return }
                for wave in waves {
                    var path = Path()
                    for i in 0...drawn {
                        let x = (Double(i) / Double(steps)) * size.width
                        let y = size.height / 2 - sin(Double(i) * wave.freq * .pi / 30) * (size.height / 2 - 8)
                        let pt = CGPoint(x: x, y: y)
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                    ctx.stroke(path, with: .color(wave.color.opacity(wave.opacity)), lineWidth: wave.lineWidth)
                }
            }
            .frame(height: 72)

            // Legend, 2×2 grid
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    legendItem(waves[0])
                    legendItem(waves[1])
                }
                HStack(spacing: 16) {
                    legendItem(waves[2])
                    legendItem(waves[3])
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8)) { progress = 1.0 }
        }
    }

    private func legendItem(_ wave: Wave) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(wave.color.opacity(wave.opacity))
                .frame(width: 14, height: 2.5)
            Text(wave.label)
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "8a8f9a"))
        }
    }
}

// MARK: - Flow Diagram

struct FlowDiagram: View {
    let nodes: [DiagramNode]
    let edges: [DiagramEdge]
    let caption: String?

    var body: some View {
        VStack(spacing: 0) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .padding(.bottom, 8)
            }

            ForEach(Array(nodes.enumerated()), id: \.element.id) { idx, node in
                VStack(spacing: 0) {
                    FlowNodeView(node: node)

                    if idx < nodes.count - 1 {
                        let edgeLabel = edges.first(where: { $0.from == node.id })?.label
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color(hex: "c8e8e8"))
                                .frame(width: 1.5, height: 14)
                            if let lbl = edgeLabel {
                                Text(lbl)
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color(hex: "8a8f9a"))
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(Color(hex: "1a8a8a"))
                        }
                    }
                }
            }
        }
    }
}

private struct FlowNodeView: View {
    let node: DiagramNode

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(nodeColor)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "1a1a1a"))
                if let sub = node.sublabel {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8a8f9a"))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "e5f4f4"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var nodeColor: Color {
        node.color.map { Color(hex: $0) } ?? Color(hex: "1a8a8a")
    }
}

// MARK: - Bar Chart

struct BarChartDiagram: View {
    let bars: [BarSpec]
    let yLabel: String?
    let caption: String?
    @State private var progress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            ForEach(bars.indices, id: \.self) { i in
                barRow(bars[i])
            }

            if let yLabel {
                Text(yLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "8a8f9a"))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.15)) { progress = 1.0 }
        }
    }

    private func barColor(_ bar: BarSpec) -> Color {
        bar.color.map { Color(hex: $0) } ?? Color(hex: "1a8a8a")
    }

    private func barRow(_ bar: BarSpec) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bar.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "1a1a1a"))
                Spacer()
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", bar.value))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(barColor(bar))
                    if let note = bar.note {
                        Text(note)
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "e8a020"))
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "e5f4f4"))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(bar))
                        .frame(width: geo.size.width * CGFloat(min(bar.value / 100.0, 1.0)) * progress, height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Comparison Table

struct ComparisonDiagram: View {
    let leftLabel: String
    let rightLabel: String
    let items: [ComparisonItem]
    let caption: String?

    var body: some View {
        VStack(spacing: 0) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .padding(.bottom, 8)
            }

            // Header row
            HStack(spacing: 0) {
                Spacer().frame(width: 86)
                Text(leftLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .frame(maxWidth: .infinity)
                Text(rightLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "1a8a8a"))
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 6)

            Divider()

            ForEach(items.indices, id: \.self) { i in
                comparisonRow(items[i], alt: i % 2 != 0)
                Divider()
            }
        }
    }

    private func comparisonRow(_ item: ComparisonItem, alt: Bool) -> some View {
        HStack(spacing: 0) {
            Text(item.aspect)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "8a8f9a"))
                .frame(width: 86, alignment: .leading)
                .padding(.vertical, 8)

            Text(item.before)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "1a1a1a"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            Text(item.after)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "1a8a8a"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .background(alt ? Color(hex: "f7f4ef") : Color.clear)
    }
}

// MARK: - Cycle
//
// Numbered steps arranged around a loop. Handles 2 to 6 steps; beyond that it
// compresses gracefully into a vertical list with a wrap-around arrow.

struct CycleDiagram: View {
    let steps: [StepSpec]
    let caption: String?
    @State private var activeIndex: Int? = nil

    private let ink = Color(hex: "1a1a1a")
    private let teal = Color(hex: "1a8a8a")
    private let tealTint = Color(hex: "e5f4f4")
    private let muted = Color(hex: "8a8f9a")

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(muted)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            if steps.count <= 6 {
                radialLayout
            } else {
                verticalLayout
            }
        }
    }

    private var radialLayout: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, 240)
            let radius = size / 2 - 38
            let center = CGPoint(x: geo.size.width / 2, y: size / 2)

            ZStack {
                // Loop ring
                Circle()
                    .stroke(teal.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Arrow hint at top of ring
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(teal.opacity(0.7))
                    .position(x: center.x, y: center.y - radius)

                ForEach(steps.indices, id: \.self) { i in
                    nodeView(for: i)
                        .position(position(for: i, center: center, radius: radius))
                }
            }
        }
        .frame(height: 240)
    }

    private var verticalLayout: some View {
        VStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    numberCircle(i, active: activeIndex == i)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(steps[i].label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ink)
                        if let sub = steps[i].sublabel {
                            Text(sub)
                                .font(.system(size: 9))
                                .foregroundStyle(muted)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(activeIndex == i ? tealTint : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeIndex = activeIndex == i ? nil : i
                    }
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(teal)
                Text("repeats")
                    .font(.system(size: 9))
                    .foregroundStyle(muted)
            }
            .padding(.top, 2)
        }
    }

    private func position(for i: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        // Start at top, proceed clockwise.
        let angle = -.pi / 2 + (2 * .pi * Double(i)) / Double(steps.count)
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    @ViewBuilder
    private func nodeView(for i: Int) -> some View {
        let isActive = activeIndex == i
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                activeIndex = activeIndex == i ? nil : i
            }
        } label: {
            VStack(spacing: 3) {
                numberCircle(i, active: isActive)
                Text(steps[i].label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isActive ? teal : ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if isActive, let sub = steps[i].sublabel {
                    Text(sub)
                        .font(.system(size: 8))
                        .foregroundStyle(muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 82)
        }
        .buttonStyle(.plain)
    }

    private func numberCircle(_ i: Int, active: Bool) -> some View {
        ZStack {
            Circle()
                .fill(active ? teal : tealTint)
                .frame(width: 26, height: 26)
            Circle()
                .stroke(teal.opacity(active ? 1.0 : 0.35), lineWidth: 1.5)
                .frame(width: 26, height: 26)
            Text("\(i + 1)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(active ? .white : teal)
        }
    }
}

// MARK: - Number Box
//
// One headline statistic. Intentionally dramatic, giant figure, label underneath,
// optional secondary line for context.

struct NumberBoxDiagram: View {
    let value: String
    let label: String
    let sublabel: String?
    let caption: String?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "1a8a8a"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)

                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "1a1a1a"))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                }

                if let sublabel, !sublabel.isEmpty {
                    Text(sublabel)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8a8f9a"))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20).padding(.horizontal, 16)
            .background(Color(hex: "e5f4f4").opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "1a8a8a").opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Equation
//
// Monospaced formula with a labelled legend underneath. Each term is tappable
// tap a symbol to highlight it in the formula.

struct EquationDiagram: View {
    let formula: String
    let terms: [EquationTerm]
    let caption: String?
    @State private var activeSymbol: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let caption {
                Text(caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "8a8f9a"))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            formulaView
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18).padding(.horizontal, 14)
                .background(Color(hex: "e5f4f4").opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "1a8a8a").opacity(0.18), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if !terms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(terms.indices, id: \.self) { i in
                        termRow(terms[i])
                    }
                }
            }
        }
    }

    private var formulaView: some View {
        Text(formula)
            .font(.system(size: 17, weight: .semibold, design: .serif).italic())
            .foregroundStyle(Color(hex: "1a1a1a"))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .lineLimit(3)
    }

    @ViewBuilder
    private func termRow(_ term: EquationTerm) -> some View {
        let isActive = activeSymbol == term.symbol
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeSymbol = activeSymbol == term.symbol ? nil : term.symbol
            }
        } label: {
            HStack(spacing: 10) {
                Text(term.symbol)
                    .font(.system(size: 13, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(isActive ? .white : Color(hex: "1a8a8a"))
                    .frame(width: 28, height: 24)
                    .background(isActive ? Color(hex: "1a8a8a") : Color(hex: "e5f4f4"))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(term.meaning)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "1a1a1a"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

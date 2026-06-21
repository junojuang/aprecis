import SwiftUI

// MARK: - VisualRendererView

struct VisualRendererView: View {
    let schema: VisualSchema

    var body: some View {
        switch schema.type {
        case .flow:       FlowRenderer(schema: schema)
        case .diagram:    BranchingRenderer(schema: schema)
        case .comparison: ComparisonRenderer(schema: schema)
        }
    }
}

// MARK: - Shared constants

private enum VS {
    static let nodeH:   CGFloat = 42
    static let nodeW:   CGFloat = 148
    static let hGap:    CGFloat = 10
    static let vGap:    CGFloat = 48   // vertical space between layers (includes arrow)
    static let padV:    CGFloat = 12
    static let arrow    = tealAccent.opacity(0.65)
    static let arrowFill = tealAccent.opacity(0.75)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Flow Renderer (linear sequential chain, self-sizing VStack)
// ─────────────────────────────────────────────────────────────────────────────

private struct FlowRenderer: View {
    let schema: VisualSchema

    /// Follow edges from root to produce an ordered node list
    private var orderedNodes: [VisualNode] {
        guard !schema.nodes.isEmpty else { return [] }
        let targets = Set(schema.edges.map { $0.to })
        let rootId = schema.nodes.first(where: { !targets.contains($0.id) })?.id
            ?? schema.nodes[0].id

        var result: [VisualNode] = []
        var visited = Set<String>()
        var current = rootId

        while true {
            guard let node = schema.nodes.first(where: { $0.id == current }),
                  !visited.contains(current) else { break }
            result.append(node)
            visited.insert(current)
            guard let nextId = schema.edges
                .first(where: { $0.from == current && !visited.contains($0.to) })?.to
            else { break }
            current = nextId
        }
        for node in schema.nodes where !visited.contains(node.id) {
            result.append(node)
        }
        return result
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ForEach(Array(orderedNodes.enumerated()), id: \.element.id) { i, node in
                FlowNodeView(label: node.label)

                if i < orderedNodes.count - 1 {
                    let nextId = orderedNodes[i + 1].id
                    let edgeLabel = schema.edges
                        .first(where: { $0.from == node.id && $0.to == nextId })?.label
                    FlowArrowView(label: edgeLabel)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, VS.padV)
        .frame(maxWidth: .infinity)
    }
}

private struct FlowNodeView: View {
    let label: String
    var body: some View {
        Text(label)
            .scaledFont(size: 13, weight: .semibold)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: VS.nodeH)
            .background(tealAccent)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct FlowArrowView: View {
    let label: String?
    var body: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(VS.arrow)
                .frame(width: 1.5, height: 12)
            if let label, !label.isEmpty {
                Text(label)
                    .scaledFont(size: 9, weight: .medium)
                    .foregroundStyle(mutedText)
                    .padding(.vertical, 1)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .scaledFont(size: 7)
                .foregroundStyle(VS.arrowFill)
            Rectangle()
                .fill(VS.arrow)
                .frame(width: 1.5, height: 4)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Branching Renderer (DAG layout with layered positioning)
// ─────────────────────────────────────────────────────────────────────────────

private struct BranchingRenderer: View {
    let schema: VisualSchema

    // ── BFS layer assignment ───────────────────────────────────────────────

    private var nodeDepth: [String: Int] {
        let targets = Set(schema.edges.map { $0.to })
        var visited: [String: Int] = [:]
        // All nodes with no incoming edges are roots
        var queue: [(String, Int)] = schema.nodes
            .filter { !targets.contains($0.id) }
            .map { ($0.id, 0) }
        if queue.isEmpty, let first = schema.nodes.first {
            queue = [(first.id, 0)]
        }

        var qi = 0
        while qi < queue.count {
            let (id, d) = queue[qi]; qi += 1
            if visited[id] != nil { continue }
            visited[id] = d
            for edge in schema.edges where edge.from == id {
                if visited[edge.to] == nil { queue.append((edge.to, d + 1)) }
            }
        }
        // Orphaned nodes get the next available layer
        for node in schema.nodes where visited[node.id] == nil {
            visited[node.id] = (visited.values.max() ?? 0) + 1
        }
        return visited
    }

    private var layers: [[VisualNode]] {
        let depth = nodeDepth
        let maxD = depth.values.max() ?? 0
        var result = Array(repeating: [VisualNode](), count: maxD + 1)
        for node in schema.nodes { result[depth[node.id]!].append(node) }
        return result.filter { !$0.isEmpty }
    }

    private func totalHeight() -> CGFloat {
        let n = CGFloat(layers.count)
        return VS.padV + n * VS.nodeH + max(0, n - 1) * VS.vGap + VS.padV
    }

    // ── Node position computation ──────────────────────────────────────────

    private func positions(width: CGFloat) -> [String: CGPoint] {
        var pos: [String: CGPoint] = [:]
        let ls = layers
        for (li, layer) in ls.enumerated() {
            let y = VS.padV + CGFloat(li) * (VS.nodeH + VS.vGap) + VS.nodeH / 2
            let count = CGFloat(layer.count)
            let totalW = count * VS.nodeW + max(0, count - 1) * VS.hGap
            let startX = (width - totalW) / 2 + VS.nodeW / 2
            for (ni, node) in layer.enumerated() {
                pos[node.id] = CGPoint(x: startX + CGFloat(ni) * (VS.nodeW + VS.hGap), y: y)
            }
        }
        return pos
    }

    var body: some View {
        GeometryReader { geo in
            let pos = positions(width: geo.size.width)

            ZStack {
                // Draw edges first (behind nodes)
                Canvas { ctx, _ in
                    for edge in schema.edges {
                        guard let from = pos[edge.from], let to = pos[edge.to] else { continue }
                        drawEdge(ctx: &ctx, from: from, to: to)
                    }
                }

                // Draw nodes
                ForEach(schema.nodes) { node in
                    if let p = pos[node.id] {
                        BranchNodeView(label: node.label)
                            .frame(width: VS.nodeW, height: VS.nodeH)
                            .position(p)
                    }
                }
            }
        }
        .frame(height: totalHeight())
    }

    private func drawEdge(ctx: inout GraphicsContext, from: CGPoint, to: CGPoint) {
        let startY = from.y + VS.nodeH / 2
        let endY   = to.y   - VS.nodeH / 2 - 8

        var path = Path()
        path.move(to: CGPoint(x: from.x, y: startY))

        if abs(from.x - to.x) < 2 {
            // Straight vertical
            path.addLine(to: CGPoint(x: to.x, y: endY))
        } else {
            // Smooth bezier curve
            let midY = (startY + endY) / 2
            path.addCurve(
                to:       CGPoint(x: to.x,   y: endY),
                control1: CGPoint(x: from.x, y: midY),
                control2: CGPoint(x: to.x,   y: midY)
            )
        }

        ctx.stroke(path, with: .color(VS.arrow),
                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        // Arrowhead
        let a: CGFloat = 6
        var arrowHead = Path()
        arrowHead.move(to: CGPoint(x: to.x,     y: endY))
        arrowHead.addLine(to: CGPoint(x: to.x - a / 2, y: endY - a))
        arrowHead.addLine(to: CGPoint(x: to.x + a / 2, y: endY - a))
        arrowHead.closeSubpath()
        ctx.fill(arrowHead, with: .color(VS.arrowFill))
    }
}

private struct BranchNodeView: View {
    let label: String
    var body: some View {
        Text(label)
            .scaledFont(size: 12, weight: .semibold)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tealAccent)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Comparison Renderer (two columns: old vs new)
// ─────────────────────────────────────────────────────────────────────────────

private struct ComparisonRenderer: View {
    let schema: VisualSchema

    var body: some View {
        let mid = (schema.nodes.count + 1) / 2
        let left  = Array(schema.nodes.prefix(mid))
        let right = Array(schema.nodes.dropFirst(mid))

        HStack(alignment: .top, spacing: 0) {
            CompareColumn(nodes: left, title: "Before", accent: mutedText)
            Rectangle().fill(borderColor).frame(width: 1)
            CompareColumn(nodes: right, title: "This Paper", accent: tealAccent)
        }
        .padding(.vertical, VS.padV)
    }
}

private struct CompareColumn: View {
    let nodes: [VisualNode]
    let title: String
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .scaledFont(size: 9, weight: .bold)
                .tracking(0.8)
                .foregroundStyle(accent)
                .padding(.bottom, 2)

            ForEach(nodes) { node in
                Text(node.label)
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundStyle(accent == tealAccent ? tealAccent : inkColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(accent == tealAccent ? tealLight : Color(hex: "f2f2f2"))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }
}

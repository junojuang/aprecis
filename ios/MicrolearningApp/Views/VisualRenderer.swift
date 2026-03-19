import SwiftUI

// MARK: - VisualRendererView

struct VisualRendererView: View {
    let schema: VisualSchema

    var body: some View {
        switch schema.type {
        case .flow:       FlowRenderer(schema: schema)
        case .comparison: ComparisonRenderer(schema: schema)
        case .diagram:    DiagramRenderer(schema: schema)
        }
    }
}

// MARK: - Shared constants

private enum VisualStyle {
    static let nodeWidth: CGFloat = 140
    static let nodeHeight: CGFloat = 44
    static let nodeCornerRadius: CGFloat = 10
    static let nodeFill = Color.white.opacity(0.12)
    static let nodeBorder = Color.white.opacity(0.35)
    static let nodeTextColor = Color.white
    static let edgeColor = Color.white.opacity(0.6)
    static let arrowSize: CGFloat = 8
}

// MARK: - Flow Renderer (vertical chain)

private struct FlowRenderer: View {
    let schema: VisualSchema

    var body: some View {
        GeometryReader { geo in
            let nodeCount = schema.nodes.count
            guard nodeCount > 0 else { return AnyView(EmptyView()) }

            let spacing: CGFloat = 20
            let totalNodeHeight = CGFloat(nodeCount) * VisualStyle.nodeHeight
            let totalSpacing = CGFloat(nodeCount - 1) * spacing
            let totalArrowSpace = CGFloat(max(nodeCount - 1, 0)) * 30
            let contentHeight = totalNodeHeight + totalSpacing + totalArrowSpace
            let startY = max((geo.size.height - contentHeight) / 2, 8)
            let centerX = geo.size.width / 2

            // Build position map for edge drawing
            var positions: [String: CGPoint] = [:]
            let stride = VisualStyle.nodeHeight + spacing + 30
            for (i, node) in schema.nodes.enumerated() {
                positions[node.id] = CGPoint(
                    x: centerX,
                    y: startY + CGFloat(i) * stride + VisualStyle.nodeHeight / 2
                )
            }

            return AnyView(
                ZStack {
                    // Draw edges
                    Canvas { ctx, _ in
                        for edge in schema.edges {
                            guard let from = positions[edge.from],
                                  let to = positions[edge.to] else { continue }
                            drawArrow(ctx: &ctx, from: from, to: to)
                        }
                    }

                    // Draw nodes
                    ForEach(schema.nodes) { node in
                        if let pos = positions[node.id] {
                            NodeView(label: node.label)
                                .position(pos)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            )
        }
    }
}

// MARK: - Diagram Renderer (hub and spoke)

private struct DiagramRenderer: View {
    let schema: VisualSchema

    var body: some View {
        GeometryReader { geo in
            let nodes = schema.nodes
            guard !nodes.isEmpty else { return AnyView(EmptyView()) }

            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) * 0.33
            let hubNode = nodes[0]
            let spokeNodes = nodes.dropFirst()
            let spokeCount = spokeNodes.count

            var positions: [String: CGPoint] = [hubNode.id: center]

            for (i, node) in spokeNodes.enumerated() {
                let angle = (2 * Double.pi / Double(max(spokeCount, 1))) * Double(i) - Double.pi / 2
                positions[node.id] = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
            }

            return AnyView(
                ZStack {
                    Canvas { ctx, _ in
                        for edge in schema.edges {
                            guard let from = positions[edge.from],
                                  let to = positions[edge.to] else { continue }
                            drawArrow(ctx: &ctx, from: from, to: to)
                        }
                    }

                    ForEach(nodes) { node in
                        if let pos = positions[node.id] {
                            NodeView(label: node.label, isHub: node.id == hubNode.id)
                                .position(pos)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            )
        }
    }
}

// MARK: - Comparison Renderer (two columns)

private struct ComparisonRenderer: View {
    let schema: VisualSchema

    var body: some View {
        VStack(spacing: 12) {
            let midpoint = (schema.nodes.count + 1) / 2
            let leftNodes = Array(schema.nodes.prefix(midpoint))
            let rightNodes = Array(schema.nodes.dropFirst(midpoint))

            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 10) {
                    Text("A")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    ForEach(leftNodes) { node in
                        NodeView(label: node.label)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.white.opacity(0.2))

                VStack(spacing: 10) {
                    Text("B")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    ForEach(rightNodes) { node in
                        NodeView(label: node.label)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - NodeView

private struct NodeView: View {
    let label: String
    var isHub: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: isHub ? 14 : 12, weight: isHub ? .bold : .medium))
            .foregroundColor(VisualStyle.nodeTextColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: isHub ? VisualStyle.nodeWidth + 20 : VisualStyle.nodeWidth,
                   height: isHub ? VisualStyle.nodeHeight + 6 : VisualStyle.nodeHeight)
            .background(isHub ? Color.white.opacity(0.2) : VisualStyle.nodeFill)
            .clipShape(RoundedRectangle(cornerRadius: VisualStyle.nodeCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VisualStyle.nodeCornerRadius, style: .continuous)
                    .stroke(isHub ? Color.white.opacity(0.6) : VisualStyle.nodeBorder, lineWidth: 1)
            )
    }
}

// MARK: - Arrow drawing helper (free function)

private func drawArrow(ctx: inout GraphicsContext, from: CGPoint, to: CGPoint) {
    let dx = to.x - from.x
    let dy = to.y - from.y
    let length = sqrt(dx * dx + dy * dy)
    guard length > 0 else { return }

    let ux = dx / length
    let uy = dy / length

    // Offset start/end so arrow touches node edges, not centers
    let margin: CGFloat = VisualStyle.nodeHeight / 2 + 4
    let startX = from.x + ux * margin
    let startY = from.y + uy * margin
    let endX = to.x - ux * margin
    let endY = to.y - uy * margin

    var linePath = Path()
    linePath.move(to: CGPoint(x: startX, y: startY))
    linePath.addLine(to: CGPoint(x: endX, y: endY))

    ctx.stroke(
        linePath,
        with: .color(VisualStyle.edgeColor),
        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
    )

    // Arrowhead triangle
    let a = VisualStyle.arrowSize
    let nx = -uy  // normal x
    let ny = ux   // normal y

    var arrow = Path()
    arrow.move(to: CGPoint(x: endX, y: endY))
    arrow.addLine(to: CGPoint(x: endX - ux * a + nx * (a / 2),
                              y: endY - uy * a + ny * (a / 2)))
    arrow.addLine(to: CGPoint(x: endX - ux * a - nx * (a / 2),
                              y: endY - uy * a - ny * (a / 2)))
    arrow.closeSubpath()

    ctx.fill(arrow, with: .color(VisualStyle.edgeColor))
}

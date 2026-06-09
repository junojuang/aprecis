import SwiftUI

// MARK: - ResNet bespoke interactives
//
// AlexNet made depth pay off at eight layers. ResNet (2015) asked why it
// stopped there, and unlocked a hundred. These visuals are about the skip
// connection: depth that hurts, a gradient that survives the trip down,
// and a tower of blocks that can choose to do nothing.

// MARK: - Fixed pseudo-noise
//
// A deterministic error sequence so the tower drifts the same way on every
// render. No randomness inside a view body.

private let resNetDrift: [Double] = [
     0.04, -0.06,  0.05,  0.03, -0.07,  0.06, -0.04,  0.05,  0.07, -0.05,
     0.06,  0.04, -0.06,  0.05, -0.07,  0.06,  0.05, -0.04,  0.06,  0.05,
     0.07, -0.05,  0.06,  0.05, -0.06,  0.07,  0.05, -0.04,  0.06,  0.05,
     0.06,  0.07, -0.05,  0.06,  0.05,  0.07, -0.06,  0.05,  0.06,  0.07,
     0.05,  0.06, -0.05,  0.07,  0.06,  0.05,  0.07,  0.06,  0.05,  0.07,
]

// MARK: - ResNetGlyph (cover hero)
//
// A tall stack of blocks with curved shortcut arcs leaping past them. A
// pulse runs down and stays bright the whole way, because of the arcs.

struct ResNetGlyph: View {
    @State private var t: Double = 0

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = 6
            let blockY: (Int) -> CGFloat = { i in
                h * CGFloat(0.12 + 0.76 * Double(i) / Double(n - 1))
            }
            ZStack {
                ForEach(0..<n - 1, id: \.self) { i in
                    Path { p in
                        let y0 = blockY(i), y1 = blockY(i + 1)
                        p.move(to: CGPoint(x: w * 0.5, y: y0))
                        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: y1),
                                       control: CGPoint(x: w * 0.86, y: (y0 + y1) / 2))
                    }
                    .stroke(tealAccent.opacity(0.55),
                            style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                }
                ForEach(0..<n, id: \.self) { i in
                    let lit = t * Double(n) >= Double(i)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(lit ? tealAccent.opacity(0.9) : ink.opacity(0.16))
                        .frame(width: w * 0.34, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(ink.opacity(0.3), lineWidth: 1))
                        .position(x: w * 0.5, y: blockY(i))
                        .shadow(color: lit ? tealAccent.opacity(0.6) : .clear, radius: 6)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                t = 1
            }
        }
    }
}

// MARK: - DegradeStudio (interactive 1)
//
// Drag the depth dial. A plain deep network's training error falls, then
// rises again past a point: deeper makes it worse, and not from
// overfitting. Flip to residual and the error just keeps falling.

struct DegradeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var depth: Double = 8
    @State private var residual = false
    @State private var sawDeep = false
    @State private var toggled = false

    private var error: Double {
        let d = depth
        if residual {
            return max(0.03, 0.42 * exp(-d / 26))
        } else {
            // falls, bottoms near 20 layers, then degrades
            let base = 0.42 * exp(-d / 16)
            let degrade = max(0, (d - 20) / 100)
            return min(0.6, base + degrade)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("DEEPER, OR WORSE?")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Drag the depth dial. Watch the training error, the error on data the network has already seen. For a plain stack, going deeper past a point makes it worse. That is not overfitting; it is the network failing to train at all.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            errorPlot
            depthSlider
            modeToggle
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var errorPlot: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let curve: (Double) -> Double = { d in
                if residual { return max(0.03, 0.42 * exp(-d / 26)) }
                let base = 0.42 * exp(-d / 16)
                return min(0.6, base + max(0, (d - 20) / 100))
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                Path { p in
                    for i in 0...80 {
                        let d = 2 + 54 * Double(i) / 80
                        let x = w * CGFloat(Double(i) / 80)
                        let y = h - h * CGFloat(curve(d) / 0.6) * 0.9 - h * 0.05
                        i == 0 ? p.move(to: CGPoint(x: x, y: y))
                               : p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(residual ? tealAccent : Color(hex: "c2557a"), lineWidth: 2.5)
                .animation(.easeInOut(duration: 0.3), value: residual)

                let cx = w * CGFloat((depth - 2) / 54)
                let cy = h - h * CGFloat(error / 0.6) * 0.9 - h * 0.05
                Circle().fill(inkColor).frame(width: 12, height: 12)
                    .position(x: cx, y: cy)
            }
        }
        .frame(height: 150)
    }

    private var depthSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEPTH  \(Int(depth)) layers")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(mutedText)
            Slider(value: $depth, in: 2...56) { editing in
                if !editing && depth > 40 { sawDeep = true; check() }
            }
            .tint(tealAccent)
        }
    }

    private var modeToggle: some View {
        Button {
            residual.toggle(); toggled = true
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(); check()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: residual ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(residual ? tealAccent : inkColor.opacity(0.3))
                Text(residual ? "Residual stack (skip connections on)"
                              : "Plain stack (no skip connections)")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(residual ? tealAccent.opacity(0.07) : inkColor.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(sawDeep && toggled ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(sawDeep && toggled
                 ? "The residual stack keeps improving with depth. The plain one cannot."
                 : "Training error \(String(format: "%.2f", error)) at \(Int(depth)) layers")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func check() {
        if sawDeep && toggled {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - SkipFlowStudio (interactive 2)
//
// Send a gradient backward down a stack of blocks. With no skip, each block
// shrinks it, so by the bottom there is almost nothing left to learn from.
// Turn the shortcuts on and the gradient arrives intact.

struct SkipFlowStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let blocks = 6
    @State private var skip = false
    @State private var arrived: [Double] = []
    @State private var sends = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("SEND THE GRADIENT BACK")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The learning signal enters at the top and travels down. Each plain block shrinks it. The skip connection gives it a clean path that does not shrink, so it reaches the earliest layers strong enough to teach them.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            tower
            skipToggle
            statusRow
            sendButton
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tower: some View {
        VStack(spacing: 8) {
            ForEach(0..<blocks, id: \.self) { i in
                let strength = i < arrived.count ? arrived[i] : 0
                HStack(spacing: 10) {
                    Text("L\(blocks - i)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(mutedText)
                        .frame(width: 26)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(inkColor.opacity(0.05))
                            RoundedRectangle(cornerRadius: 8)
                                .fill(strength > 0.4 ? tealAccent
                                      : strength > 0.12 ? amberAccent
                                      : Color(hex: "c2557a"))
                                .frame(width: max(strength > 0 ? 6 : 0,
                                                  g.size.width * CGFloat(strength)))
                        }
                    }
                    .frame(height: 26)
                    Text(String(format: "%.0f%%", strength * 100))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(mutedText)
                        .frame(width: 38, alignment: .trailing)
                }
            }
        }
        .animation(.snappy(duration: 0.4), value: arrived)
    }

    private var skipToggle: some View {
        Button {
            skip.toggle(); arrived = []
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: skip ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(skip ? tealAccent : inkColor.opacity(0.3))
                Text(skip ? "Skip connections on" : "Skip connections off")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(skip ? tealAccent.opacity(0.07) : inkColor.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        let bottom = arrived.last ?? 0
        return HStack(spacing: 8) {
            Circle().fill(sends >= 2 ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(sends >= 2
                 ? "With skips on, the signal reaches the bottom almost whole. Off, it dies on the way down."
                 : arrived.isEmpty ? "Send a gradient backward and watch it travel."
                   : "Reached the bottom layer at \(Int(bottom * 100))% strength.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sendButton: some View {
        Button { send() } label: {
            Text("Send gradient backward")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12).fill(inkColor))
        }
        .buttonStyle(.plain)
    }

    private func send() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        arrived = []
        var s = 1.0
        func step(_ i: Int) {
            guard i < blocks else {
                sends += 1
                if sends == 2 {
                    progress.markExplored(cardId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                return
            }
            // plain block multiplies by 0.55; skip path keeps it near 1
            s = skip ? s * 0.96 : s * 0.55
            withAnimation(.snappy(duration: 0.25)) { arrived.append(s) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { step(i + 1) }
        }
        step(0)
    }
}

// MARK: - IdentityTowerStudio (interactive 3)
//
// Stack do-nothing blocks. A residual block can pass its input straight
// through by learning F(x) = 0; the input survives any depth. A plain
// block must learn to copy its input, and the small copy errors compound.

struct IdentityTowerStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var depth: Double = 6
    @State private var sawDeep = false

    private var plainOut: Double {
        1.0 + resNetDrift.prefix(Int(depth)).reduce(0, +)
    }
    private var residualOut: Double {
        1.0 + resNetDrift.prefix(Int(depth)).reduce(0, +) * 0.05
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("A TOWER OF DO-NOTHING BLOCKS")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Suppose the best thing a layer can do is leave its input alone. A residual block manages it for free: learn F(x) = 0 and the output is just x. A plain block has to learn to copy, and tiny errors pile up with depth.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            readout("Input fed in", value: 1.0, tint: inkColor.opacity(0.6))
            readout("Plain stack output", value: plainOut, tint: Color(hex: "c2557a"))
            readout("Residual stack output", value: residualOut, tint: tealAccent)
            depthSlider
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func readout(_ label: String, value: Double, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
            Spacer()
            Text(String(format: "%.3f", value))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.07)))
    }

    private var depthSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEPTH  \(Int(depth)) blocks")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(mutedText)
            Slider(value: $depth, in: 1...50) { editing in
                if !editing && depth >= 30 {
                    sawDeep = true
                    progress.markExplored(cardId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .tint(tealAccent)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(sawDeep ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(sawDeep
                 ? "Deep, the plain output has drifted far from its input. The residual one barely moved."
                 : "Drag toward 50 blocks and compare the two outputs.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - FeatureHierarchyArt (illustrated)
//
// The big-idea card for ResNet, grounded in image recognition: a network
// reads a photo in stages, pixels -> edges -> parts -> object. One stage per
// layer, so depth is just how many stages of seeing the network gets.

struct FeatureHierarchyArt: View {
    var body: some View {
        HStack(spacing: 5) {
            stage(label: "pixels") { pixelsGlyph }
            arrow
            stage(label: "edges") { edgesGlyph }
            arrow
            stage(label: "parts") { partsGlyph }
            arrow
            stage(label: "object") { objectGlyph }
        }
        .frame(maxWidth: .infinity)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(mutedText)
    }

    private func stage<G: View>(label: String, @ViewBuilder glyph: () -> G) -> some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(borderColor, lineWidth: 0.8))
                glyph().padding(11)
            }
            .frame(width: 60, height: 60)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold)).tracking(1)
                .foregroundStyle(mutedText)
        }
    }

    // A 4x4 grid of grey cells: raw dots of colour.
    private var pixelsGlyph: some View {
        let shades: [Double] = [0.18, 0.5, 0.3, 0.62, 0.44, 0.24, 0.7, 0.36,
                                0.58, 0.34, 0.5, 0.2, 0.3, 0.66, 0.4, 0.54]
        return VStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(inkColor.opacity(shades[r * 4 + c]))
                    }
                }
            }
        }
    }

    // Three diagonal strokes: the first thing a network groups pixels into.
    private var edgesGlyph: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ForEach(0..<3, id: \.self) { i in
                Path { p in
                    let x = w * (0.2 + 0.3 * Double(i))
                    p.move(to: CGPoint(x: x, y: h * 0.92))
                    p.addLine(to: CGPoint(x: x + w * 0.34, y: h * 0.08))
                }
                .stroke(inkColor.opacity(0.78),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }
    }

    // A corner and an arc: edges combined into parts.
    private var partsGlyph: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.12, y: h * 0.1))
                    p.addLine(to: CGPoint(x: w * 0.12, y: h * 0.7))
                    p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.7))
                }
                .stroke(inkColor.opacity(0.78),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                Path { p in
                    p.addArc(center: CGPoint(x: w * 0.78, y: h * 0.34),
                             radius: w * 0.3,
                             startAngle: .degrees(90), endAngle: .degrees(220),
                             clockwise: false)
                }
                .stroke(tealAccent,
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }
    }

    // A solid teal shape: the whole object the stages add up to.
    private var objectGlyph: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Ellipse()
                    .fill(tealAccent)
                    .frame(width: w * 0.78, height: h * 0.6)
                    .position(x: w * 0.5, y: h * 0.62)
                Circle()
                    .fill(tealAccent)
                    .frame(width: w * 0.42, height: w * 0.42)
                    .position(x: w * 0.5, y: h * 0.3)
            }
        }
    }
}

// MARK: - DegradationPlotArt (illustrated)
//
// The puzzle card: the paper's own famous result. A deeper (56-layer) network
// flattens at a HIGHER training error than a shallower (20-layer) one. Deeper,
// yet worse, and on data it has already seen.

struct DegradationPlotArt: View {
    // Sampled error curves, high on the left, settling toward a floor.
    private func curve(start: CGFloat, floor: CGFloat, k: CGFloat) -> [CGFloat] {
        (0...28).map { i in
            let t = CGFloat(i) / 28
            return floor + (start - floor) * exp(-k * t)
        }
    }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let pad: CGFloat = 18
            let plot = CGRect(x: pad, y: pad, width: w - pad * 2, height: h - pad * 2.4)
            // error 0...1 maps top(high) -> bottom(low)
            let pt: (Int, CGFloat, Int) -> CGPoint = { i, e, n in
                CGPoint(x: plot.minX + plot.width * CGFloat(i) / CGFloat(n - 1),
                        y: plot.minY + plot.height * e)
            }
            let deep = curve(start: 0.9, floor: 0.46, k: 3.0)
            let shallow = curve(start: 0.86, floor: 0.16, k: 3.4)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: 0.8))

                // axes
                Path { p in
                    p.move(to: CGPoint(x: plot.minX, y: plot.minY))
                    p.addLine(to: CGPoint(x: plot.minX, y: plot.maxY))
                    p.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
                }
                .stroke(inkColor.opacity(0.25), lineWidth: 1)

                line(deep, color: amberAccent, pt: pt)
                line(shallow, color: tealAccent, pt: pt)

                Text("56-layer")
                    .font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundStyle(amberAccent)
                    .position(x: plot.maxX - 30, y: pt(0, deep[20], deep.count).y - 11)
                Text("20-layer")
                    .font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundStyle(tealAccent)
                    .position(x: plot.maxX - 30, y: pt(0, shallow[20], shallow.count).y + 12)

                Text("TRAINING ERROR")
                    .font(.system(size: 8, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText)
                    .rotationEffect(.degrees(-90))
                    .position(x: plot.minX - 8, y: plot.midY)
                Text("TRAINING TIME \u{2192}")
                    .font(.system(size: 8, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText)
                    .position(x: plot.midX, y: plot.maxY + 13)
            }
        }
    }

    private func line(_ pts: [CGFloat], color: Color,
                      pt: (Int, CGFloat, Int) -> CGPoint) -> some View {
        Path { p in
            for (i, e) in pts.enumerated() {
                let q = pt(i, e, pts.count)
                if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - FadingSignalArt (illustrated)
//
// The cause card: the error signal is sent backward through every layer and
// shrinks a little at each one. Down a deep plain stack it fades to a whisper,
// so the earliest layers never learn.

struct FadingSignalArt: View {
    private let n = 8

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let topY = h * 0.14, botY = h * 0.86
            let rowY: (Int) -> CGFloat = { i in
                topY + (botY - topY) * CGFloat(i) / CGFloat(self.n - 1)
            }
            let strength: (Int) -> Double = { 1.0 - 0.92 * Double($0) / Double(self.n - 1) }

            ZStack {
                // the layer stack
                ForEach(0..<n, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(inkColor.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(inkColor.opacity(0.22), lineWidth: 1))
                        .frame(width: w * 0.4, height: 13)
                        .position(x: w * 0.36, y: rowY(i))
                }
                // the fading signal: a tapering wedge beside the stack
                Path { p in
                    let x = w * 0.72
                    p.move(to: CGPoint(x: x - 13, y: topY - 8))
                    p.addLine(to: CGPoint(x: x + 13, y: topY - 8))
                    p.addLine(to: CGPoint(x: x + 1.5, y: botY + 8))
                    p.addLine(to: CGPoint(x: x - 1.5, y: botY + 8))
                    p.closeSubpath()
                }
                .fill(LinearGradient(
                    colors: [tealAccent, tealAccent.opacity(0.06)],
                    startPoint: .top, endPoint: .bottom))
                // strength dots, one per layer, shrinking down
                ForEach(0..<n, id: \.self) { i in
                    Circle()
                        .fill(tealAccent.opacity(0.35 + 0.65 * strength(i)))
                        .frame(width: 4 + 10 * strength(i), height: 4 + 10 * strength(i))
                        .position(x: w * 0.72, y: rowY(i))
                }
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.72, y: topY - 20)

                Text("STRONG")
                    .font(.system(size: 8, weight: .bold)).tracking(1)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.93, y: topY)
                Text("A WHISPER")
                    .font(.system(size: 8, weight: .bold)).tracking(1)
                    .foregroundStyle(mutedText)
                    .position(x: w * 0.9, y: botY)
            }
        }
    }
}

// MARK: - ResidualBlockArt (illustrated)
//
// The fix card: one residual block. The input splits, runs through two layers
// on the main path, and rejoins its untouched self at a sum node. The skip
// wire is the whole paper.

struct ResidualBlockArt: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let mainX = w * 0.42
            let topY = h * 0.1, l1Y = h * 0.37, l2Y = h * 0.6
            let sumY = h * 0.82
            let skipX = w * 0.78

            ZStack {
                // main path wire
                Path { p in
                    p.move(to: CGPoint(x: mainX, y: topY))
                    p.addLine(to: CGPoint(x: mainX, y: sumY))
                }
                .stroke(inkColor.opacity(0.3), lineWidth: 1.6)

                // skip wire: input down the side, back to the sum
                Path { p in
                    p.move(to: CGPoint(x: mainX, y: topY + 3))
                    p.addLine(to: CGPoint(x: skipX, y: topY + 3))
                    p.addLine(to: CGPoint(x: skipX, y: sumY))
                    p.addLine(to: CGPoint(x: mainX + 13, y: sumY))
                }
                .stroke(tealAccent,
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))

                // two layer boxes on the main path
                layerBox.position(x: mainX, y: l1Y)
                layerBox.position(x: mainX, y: l2Y)

                // input node
                nodeChip("x", tint: inkColor).position(x: mainX, y: topY)
                // sum node
                Circle()
                    .fill(tealAccent)
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "plus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white))
                    .position(x: mainX, y: sumY)
                // output node
                nodeChip("output", tint: inkColor)
                    .position(x: mainX, y: h * 0.97)
                Path { p in
                    p.move(to: CGPoint(x: mainX, y: sumY + 15))
                    p.addLine(to: CGPoint(x: mainX, y: h * 0.93))
                }
                .stroke(inkColor.opacity(0.3), lineWidth: 1.6)

                Text("skip")
                    .font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundStyle(tealAccent)
                    .position(x: skipX + 16, y: (topY + sumY) / 2)
                Text("F(x)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(mutedText)
                    .position(x: mainX - 34, y: (l1Y + l2Y) / 2)
            }
        }
    }

    private var layerBox: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(inkColor.opacity(0.3), lineWidth: 1))
            .overlay(Text("layer")
                .font(.system(size: 9, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.7)))
            .frame(width: 74, height: 26)
    }

    private func nodeChip(_ s: String, tint: Color) -> some View {
        Text(s)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(Capsule().fill(tint))
    }
}

// MARK: - DepthLeapArt (illustrated)
//
// The payoff card: depth by year. AlexNet's 8 layers, then VGG and GoogLeNet,
// then ResNet's 152, a leap nothing before it could survive. Bars scale by
// the square root of depth so the smaller networks stay visible.

struct DepthLeapArt: View {
    private struct Net { let name: String; let depth: Int; let year: String }
    private let nets: [Net] = [
        .init(name: "AlexNet",   depth: 8,   year: "2012"),
        .init(name: "VGG",       depth: 19,  year: "2014"),
        .init(name: "GoogLeNet", depth: 22,  year: "2014"),
        .init(name: "ResNet",    depth: 152, year: "2015"),
    ]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let maxBar = h * 0.7
            let scale = maxBar / CGFloat(sqrt(152.0))
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(nets.indices, id: \.self) { i in
                    let net = nets[i]
                    let isLast = i == nets.count - 1
                    let barH = CGFloat(sqrt(Double(net.depth))) * scale
                    VStack(spacing: 5) {
                        Text("\(net.depth)")
                            .font(.system(size: isLast ? 16 : 11,
                                          weight: .bold, design: .serif))
                            .foregroundStyle(isLast ? tealAccent : inkColor.opacity(0.7))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isLast ? tealAccent : inkColor.opacity(0.16))
                            .frame(width: w * 0.12, height: barH)
                        Text(net.name)
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(isLast ? tealAccent : mutedText)
                        Text(net.year)
                            .font(.system(size: 8))
                            .foregroundStyle(mutedText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

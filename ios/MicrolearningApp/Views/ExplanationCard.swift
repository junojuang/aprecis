import SwiftUI

// MARK: - Explanation Card
//
// New slot 4 in the foundational deck. Sits between the interactive diagram
// (slot 3) and the first viz (slot 5). The point is reinforcement: after the
// reader has tapped through a bespoke studio diagram, this card recaps what
// they just saw with a static mini-diagram and 3 short narrative paragraphs.
//
// Premium: each paper supplies its own `DLExplanationMini` case so the mini-
// recap visually rhymes with the studio diagram it follows. The rest of the
// card (eyebrow, title, paragraphs, takeaway) is paper-specific copy.
//
// Glossary-aware: paragraph bodies route through `GlossText` so inline domain
// terms remain tappable. Non-foundational loops never see this card because
// `DailyLoopContent.explanationCard` defaults to nil.

private let exInk        = Color(hex: "0f1117")
private let exInkSoft    = Color(hex: "2a2d36")
private let exInkMute    = Color(hex: "4a4e58")
private let exDim        = Color(hex: "8a8f9a")
private let exRule       = Color(hex: "d8d2c4")
private let exPaper2     = Color(hex: "efeae1")
private let exPaper3     = Color(hex: "e6e1d6")

struct ExplanationCard: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent

    var body: some View {
        // Foundational loops always set explanationCard. Render a tasteful
        // empty state if a caller ever wires this view without one rather
        // than crashing on `!`.
        if let ec = content.explanationCard {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header(eyebrow: ec.eyebrow)
                    title(ec.titleSegments)

                    miniDiagramFrame(kind: ec.mini)
                        .padding(.top, 6)
                        .padding(.bottom, 22)

                    paragraphs(ec.paragraphs)

                    Rectangle().fill(exRule).frame(height: 1)
                        .padding(.vertical, 22)

                    takeaway(ec.takeaway)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        } else {
            Color.clear
        }
    }

    // MARK: Header

    private func header(eyebrow: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(amberAccent).frame(width: 5, height: 5)
            Text(eyebrow)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(amberAccent)
            Spacer()
            Text("RECAP")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(exDim)
        }
        .padding(.bottom, 14)
    }

    private func title(_ segs: [DLSegment]) -> some View {
        let txt = segs.reduce(Text("")) { acc, seg in
            switch seg {
            case .plain(let s):     return acc + Text(s)
            case .highlight(let s): return acc + Text(s).italic().foregroundColor(tealAccent)
            }
        }
        return txt
            .font(.system(size: 26, weight: .regular, design: .serif))
            .foregroundStyle(exInk)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 18)
    }

    // MARK: Paragraphs

    private func paragraphs(_ paras: [DLExplanationPara]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(paras.enumerated()), id: \.offset) { _, p in
                VStack(alignment: .leading, spacing: 6) {
                    if let kicker = p.kicker {
                        Text(kicker)
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(tealAccent)
                    }
                    GlossText(
                        raw: p.body,
                        glossary: content.glossary,
                        font: .system(size: 14, design: .serif),
                        color: exInkSoft,
                        lineSpacing: 4
                    )
                }
            }
        }
    }

    private func takeaway(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(tealAccent)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
            Text(s)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(exInk)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 24, alignment: .leading)
    }

    // MARK: Mini diagram frame

    @ViewBuilder
    private func miniDiagramFrame(kind: DLExplanationMini) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(exPaper2)
            RoundedRectangle(cornerRadius: 14)
                .stroke(exRule, lineWidth: 1)
            miniBody(kind: kind)
                .padding(.horizontal, 18)
                .padding(.vertical, 22)
        }
        .frame(height: 150)
    }

    @ViewBuilder
    private func miniBody(kind: DLExplanationMini) -> some View {
        switch kind {
        case .perceptron: PerceptronMini()
        case .backprop:   BackpropMini()
        case .lenet:      LeNetMini()
        case .alexnet:    AlexNetMini()
        case .word2vec:   Word2VecMini()
        case .seq2seq:    Seq2SeqMini()
        case .gans:       GANsMini()
        case .resnet:     ResNetMini()
        case .transformer: TransformerMini()
        case .gpt3:       GPT3Mini()
        case .bert:       BERTMini()
        }
    }
}

// MARK: - Bespoke per-paper mini diagrams
//
// Each mini is a compact static SwiftUI sketch sized to fit a ~150pt high card
// recess. Shapes only, no third-party charts. The visual should be a faithful
// echo of the studio diagram on the previous card so the reader recognises it
// instantly. Type is kept small; the words live in the paragraphs below.

private struct MiniNode: View {
    let label: String
    var sub: String? = nil
    var tint: Color = tealAccent
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(exInk)
            if let s = sub {
                Text(s)
                    .font(.system(size: 9, design: .serif))
                    .italic()
                    .foregroundStyle(exInkMute)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct MiniArrow: View {
    var dashed: Bool = false
    var tint: Color = tealAccent
    var body: some View {
        HStack(spacing: 2) {
            Rectangle()
                .fill(tint.opacity(0.7))
                .frame(width: 14, height: dashed ? 0 : 1)
                .overlay(
                    Group {
                        if dashed {
                            HStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Rectangle().fill(tint.opacity(0.7)).frame(width: 2, height: 1)
                                }
                            }
                        }
                    }
                )
            Triangle()
                .fill(tint.opacity(0.85))
                .frame(width: 6, height: 6)
                .rotationEffect(.degrees(90))
        }
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// Perceptron · x → Σ → step → y, with a small w halo behind Σ
private struct PerceptronMini: View {
    var body: some View {
        HStack(spacing: 6) {
            MiniNode(label: "xᵢ", sub: "inputs")
            MiniArrow()
            ZStack {
                Text("w")
                    .font(.system(size: 10, design: .serif).italic())
                    .foregroundStyle(amberAccent)
                    .offset(x: -16, y: -16)
                MiniNode(label: "Σ", sub: "weighted sum")
            }
            MiniArrow()
            MiniNode(label: "step", sub: "θ")
            MiniArrow()
            MiniNode(label: "y", sub: "0 / 1", tint: amberAccent)
        }
    }
}

// Backprop · forward (teal) and backward (amber dashed) along x→h→y→L
private struct BackpropMini: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                MiniNode(label: "x")
                MiniArrow()
                MiniNode(label: "h", sub: "σ(W₁x)")
                MiniArrow()
                MiniNode(label: "ŷ", sub: "W₂h")
                MiniArrow()
                MiniNode(label: "L", sub: "loss", tint: amberAccent)
            }
            HStack(spacing: 4) {
                Spacer()
                Text("∂L/∂w")
                    .font(.system(size: 10, design: .serif).italic())
                    .foregroundStyle(amberAccent)
                MiniArrow(dashed: true, tint: amberAccent)
                Text("backward")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(amberAccent)
                Spacer()
            }
            .rotationEffect(.degrees(180))
            .padding(.horizontal, 20)
        }
    }
}

// LeNet · input → conv → pool → conv → fc, shrinking blocks
private struct LeNetMini: View {
    var body: some View {
        HStack(spacing: 4) {
            blk(size: 38, label: "32²")
            MiniArrow()
            blk(size: 32, label: "C1")
            MiniArrow()
            blk(size: 24, label: "S2")
            MiniArrow()
            blk(size: 20, label: "C3")
            MiniArrow()
            MiniNode(label: "FC", sub: "→ digit", tint: amberAccent)
        }
    }
    private func blk(size: CGFloat, label: String) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3)
                .fill(tealAccent.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(tealAccent.opacity(0.55), lineWidth: 1))
                .frame(width: size, height: size)
            Text(label)
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(exInkMute)
        }
    }
}

// AlexNet · five tricks stacked as labelled chips
private struct AlexNetMini: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                chip("ReLU")
                chip("Dropout")
                chip("Augment", tint: amberAccent)
            }
            HStack(spacing: 6) {
                chip("Dual GPU")
                chip("LRN", tint: amberAccent)
                Text("→ 16.4% top-5")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundStyle(exInk)
            }
        }
    }
    private func chip(_ s: String, tint: Color = tealAccent) -> some View {
        Text(s)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}

// Word2Vec · 2D word cluster with the king-queen vector hint
private struct Word2VecMini: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                dot(0.18, 0.62, "cat")
                dot(0.30, 0.58, "dog")
                dot(0.24, 0.70, "fox")
                dot(0.62, 0.28, "king", bold: true)
                dot(0.78, 0.30, "queen", bold: true, tint: amberAccent)
                dot(0.70, 0.74, "Paris")
                dot(0.82, 0.72, "Rome")
                Path { p in
                    p.move(to: pt(geo, 0.62, 0.28))
                    p.addLine(to: pt(geo, 0.78, 0.30))
                }
                .stroke(amberAccent.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
        }
    }
    private func pt(_ g: GeometryProxy, _ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: g.size.width * x, y: g.size.height * y)
    }
    private func dot(_ x: Double, _ y: Double, _ label: String, bold: Bool = false, tint: Color = tealAccent) -> some View {
        GeometryReader { g in
            let p = pt(g, x, y)
            ZStack {
                Circle().fill(tint.opacity(0.7)).frame(width: 6, height: 6)
                    .position(p)
                Text(label)
                    .font(.system(size: bold ? 11 : 10, weight: bold ? .semibold : .regular, design: .serif))
                    .foregroundStyle(exInk)
                    .position(x: p.x, y: p.y - 12)
            }
        }
    }
}

// Seq2Seq · encoder chain → context vector → decoder chain
private struct Seq2SeqMini: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in cell(tint: tealAccent) }
            MiniArrow()
            cell(label: "c", tint: amberAccent)
            MiniArrow()
            ForEach(0..<3, id: \.self) { _ in cell(tint: tealAccent) }
        }
    }
    private func cell(label: String? = nil, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(tint.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(tint.opacity(0.55), lineWidth: 1))
            if let l = label {
                Text(l)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundStyle(exInk)
            }
        }
        .frame(width: 22, height: 24)
    }
}

// GANs · G ⇄ D with sample arrow + loss
private struct GANsMini: View {
    var body: some View {
        HStack(spacing: 8) {
            MiniNode(label: "z", sub: "noise")
            MiniArrow()
            MiniNode(label: "G", sub: "forger")
            MiniArrow()
            MiniNode(label: "x̂", sub: "fake")
            MiniArrow()
            MiniNode(label: "D", sub: "detector", tint: amberAccent)
            VStack(spacing: 2) {
                Text("real?")
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(exInkMute)
                Text("loss ↺")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(amberAccent)
            }
        }
    }
}

// ResNet · skip arc over a 2-layer block
private struct ResNetMini: View {
    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                MiniNode(label: "x")
                MiniArrow()
                MiniNode(label: "F(x)", sub: "2 conv")
                MiniArrow()
                MiniNode(label: "+", sub: "add", tint: amberAccent)
                MiniArrow()
                MiniNode(label: "y", sub: "F(x)+x")
            }
            // Skip arc
            GeometryReader { g in
                Path { p in
                    let w = g.size.width
                    p.move(to: CGPoint(x: w * 0.10, y: g.size.height * 0.22))
                    p.addQuadCurve(
                        to: CGPoint(x: w * 0.70, y: g.size.height * 0.22),
                        control: CGPoint(x: w * 0.40, y: -10)
                    )
                }
                .stroke(amberAccent.opacity(0.85), style: StrokeStyle(lineWidth: 1.4, dash: [3, 2]))
                Text("skip")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(amberAccent)
                    .position(x: g.size.width * 0.40, y: 4)
            }
        }
    }
}

// Transformer · Q · K · V arrows landing on softmax → out
private struct TransformerMini: View {
    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 6) {
                MiniNode(label: "Q")
                MiniNode(label: "K")
                MiniNode(label: "V", tint: amberAccent)
            }
            VStack(spacing: 4) {
                MiniArrow()
                MiniArrow()
                MiniArrow(tint: amberAccent)
            }
            MiniNode(label: "softmax", sub: "QK ⊤ / √d")
            MiniArrow()
            MiniNode(label: "out", sub: "weighted V", tint: amberAccent)
        }
    }
}

// GPT-3 · 0/1/few-shot prompts → one model
private struct GPT3Mini: View {
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                row("0-shot", n: 0)
                row("1-shot", n: 1)
                row("few-shot", n: 3, tint: amberAccent)
            }
            MiniArrow()
            MiniNode(label: "GPT-3", sub: "175B params", tint: amberAccent)
            MiniArrow()
            MiniNode(label: "out", sub: "completion")
        }
    }
    private func row(_ label: String, n: Int, tint: Color = tealAccent) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(tint)
                .frame(width: 52, alignment: .leading)
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(i < n ? tint.opacity(0.7) : tint.opacity(0.15))
                    .frame(width: 8, height: 6)
            }
        }
    }
}

// BERT · sentence with one masked token, two-sided context arrows landing on it
private struct BERTMini: View {
    private let row = ["the", "cat", "[MASK]", "the", "mat"]
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(Array(row.enumerated()), id: \.offset) { i, w in
                    Text(w)
                        .font(.system(size: 9, weight: .semibold, design: .serif))
                        .foregroundStyle(i == 2 ? .white : exInk)
                        .padding(.horizontal, 5).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5)
                            .fill(i == 2 ? amberAccent : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .stroke(tealAccent.opacity(0.55), lineWidth: i == 2 ? 0 : 1)))
                }
            }
            HStack(spacing: 16) {
                MiniArrow(tint: tealAccent)
                Text("BOTH SIDES")
                    .font(.system(size: 9, weight: .bold)).tracking(1.0)
                    .foregroundStyle(amberAccent)
                MiniArrow(tint: amberAccent)
            }
        }
    }
}

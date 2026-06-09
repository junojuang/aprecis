import SwiftUI

// MARK: - AlexNet bespoke interactives
//
// LeNet proved the convolution. AlexNet (2012) proved that the same idea,
// made deep and fed enough data, beats everything. So these visuals are
// about scale, not the conv itself: a fast activation, a layer that trains
// by forgetting, and the three dials that had to line up at once.

// MARK: - AlexNetGlyph (cover hero)
//
// Eight stacked layers on the dark cover, a signal pulsing up through them,
// the top one fanning into many class outputs. The picture of "deep".

struct AlexNetGlyph: View {
    @State private var pulse: Double = 0

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let layers = 8
            ZStack {
                ForEach(0..<layers, id: \.self) { i in
                    let frac = Double(i) / Double(layers - 1)
                    let y = h * CGFloat(0.9 - 0.8 * frac)
                    let lit = pulse * Double(layers) >= Double(i)
                    let width = w * CGFloat(0.62 - 0.045 * Double(i))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lit ? tealAccent.opacity(0.9) : ink.opacity(0.16))
                        .frame(width: width, height: 10)
                        .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(ink.opacity(0.3), lineWidth: 1))
                        .position(x: w * 0.5, y: y)
                        .shadow(color: lit ? tealAccent.opacity(0.6) : .clear, radius: 6)
                }
                // class fan at the top
                ForEach(0..<7, id: \.self) { k in
                    Circle()
                        .fill(amberAccent.opacity(pulse > 0.92 ? 0.9 : 0.2))
                        .frame(width: 6, height: 6)
                        .position(x: w * (0.2 + 0.1 * Double(k)), y: h * 0.06)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }
}

// MARK: - PhotoToLabelArt (big-idea illustration)
//
// The whole job of the network in one row: a photo on the left, an arrow,
// a name on the right. The photo is a coarse pixel grid, which quietly sets
// up the next card where a window crawls over exactly those pixels.

struct PhotoToLabelArt: View {
    @State private var revealed = false

    private let n = 5

    // A vague "subject on ground under sky", decided by cell position so the
    // photo reads as a scene without hand-listing every pixel.
    private func cellColor(_ r: Int, _ c: Int) -> Color {
        let dr = Double(r) - 2.4, dc = Double(c) - 2.0
        if dr * dr + dc * dc < 2.3 { return amberAccent.opacity(0.85) }
        if r >= 4 { return tealAccent.opacity(0.32) }
        return Color(hex: "dbe4e6")
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 3) {
                ForEach(0..<n, id: \.self) { r in
                    HStack(spacing: 3) {
                        ForEach(0..<n, id: \.self) { c in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cellColor(r, c))
                                .frame(width: 21, height: 21)
                        }
                    }
                }
            }
            .padding(7)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))

            Image(systemName: "arrow.right")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(inkColor.opacity(0.4))

            Text("\u{201C}dog\u{201D}")
                .font(.system(size: 21, weight: .bold, design: .serif))
                .foregroundStyle(inkColor)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(Capsule().fill(tealAccent.opacity(0.15))
                    .overlay(Capsule().stroke(tealAccent.opacity(0.5), lineWidth: 1)))
                .scaleEffect(revealed ? 1 : 0.7)
                .opacity(revealed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(0.45)) {
                revealed = true
            }
        }
    }
}

// MARK: - ConvWindowArt (convolution illustration)
//
// One small window slid across the image. It steps from spot to spot on a
// timer, the same pattern hunt at every position. That sliding is the
// convolution; the card's prose and caption carry the stacking.

struct ConvWindowArt: View {
    private let n = 7
    private let cell: CGFloat = 17
    private let gap: CGFloat = 2
    private let stops: [(Int, Int)] = [(0, 0), (1, 3), (3, 4), (4, 1), (2, 2)]

    private func isSubject(_ r: Int, _ c: Int) -> Bool {
        let dr = Double(r) - 3.2, dc = Double(c) - 3.0
        return dr * dr + dc * dc < 4.6
    }

    private func offset(for i: Int) -> CGSize {
        let (r, c) = stops[i]
        return CGSize(width: CGFloat(c) * (cell + gap),
                      height: CGFloat(r) * (cell + gap))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.1)) { ctx in
            let i = Int(ctx.date.timeIntervalSinceReferenceDate / 1.1) % stops.count
            ZStack(alignment: .topLeading) {
                VStack(spacing: gap) {
                    ForEach(0..<n, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<n, id: \.self) { c in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isSubject(r, c)
                                          ? amberAccent.opacity(0.80)
                                          : inkColor.opacity(0.07))
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                RoundedRectangle(cornerRadius: 4)
                    .stroke(tealAccent, lineWidth: 2.5)
                    .frame(width: cell * 3 + gap * 2, height: cell * 3 + gap * 2)
                    .shadow(color: tealAccent.opacity(0.4), radius: 5)
                    .offset(offset(for: i))
                    .animation(.easeInOut(duration: 0.55), value: i)
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - ReLUStudio (interactive 1)
//
// Slide one input through two activations at once. Sigmoid flattens at the
// ends and its gradient dies, so deep nets crawl. ReLU stays a straight
// ramp, gradient a clean 1, so the signal to learn never fades.

struct ReLUStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var x: Double = 2.4
    @State private var moves = 0

    private var sig: Double { 1 / (1 + exp(-x)) }
    private var sigGrad: Double { sig * (1 - sig) }
    private var relu: Double { max(0, x) }
    private var reluGrad: Double { x > 0 ? 1 : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("PICK AN ACTIVATION")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Slide the input. Watch each activation's gradient, the strength of the learning signal it passes back. Sigmoid's dies at the ends. ReLU's does not.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            curvePlot
            slider
            row("Sigmoid", value: sig, grad: sigGrad, warn: sigGrad < 0.08)
            row("ReLU", value: relu, grad: reluGrad, warn: false)
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var curvePlot: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let px: (Double) -> CGFloat = { v in CGFloat((v + 4) / 8) * w }
            let pySig: (Double) -> CGFloat = { v in h - CGFloat(v) * h * 0.9 - h * 0.05 }
            let pyRelu: (Double) -> CGFloat = { v in h - CGFloat(min(v, 4) / 4) * h * 0.9 - h * 0.05 }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                Path { p in
                    for i in 0...80 {
                        let xv = -4 + 8 * Double(i) / 80
                        let pt = CGPoint(x: px(xv), y: pySig(1 / (1 + exp(-xv))))
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                }.stroke(amberAccent, lineWidth: 2)
                Path { p in
                    for i in 0...80 {
                        let xv = -4 + 8 * Double(i) / 80
                        let pt = CGPoint(x: px(xv), y: pyRelu(max(0, xv)))
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                }.stroke(tealAccent, lineWidth: 2)
                Path { p in
                    p.move(to: CGPoint(x: px(x), y: 0))
                    p.addLine(to: CGPoint(x: px(x), y: h))
                }.stroke(inkColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .frame(height: 150)
    }

    private var slider: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("INPUT  x = \(String(format: "%.1f", x))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(mutedText)
            Slider(value: $x, in: -4...4) { editing in
                if !editing { moves += 1; checkDone() }
            }
            .tint(tealAccent)
        }
    }

    private func row(_ name: String, value: Double, grad: Double, warn: Bool) -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(name == "ReLU" ? tealAccent : amberAccent)
                .frame(width: 64, alignment: .leading)
            Text("out \(String(format: "%.2f", value))")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(inkColor.opacity(0.7))
            Spacer()
            Text("gradient \(String(format: "%.2f", grad))")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(warn ? Color(hex: "c2557a") : inkColor.opacity(0.8))
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(inkColor.opacity(0.04)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(moves >= 3 ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(moves >= 3
                 ? "Push x far out and sigmoid's gradient nearly vanishes. ReLU keeps a clean 1, so deep nets keep learning."
                 : "Slide the input toward the extremes and compare the gradients.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func checkDone() {
        if moves == 3 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - DropoutStudio (interactive 2)
//
// Run training passes. Each pass silences a random half of the layer, so
// every pass trains a different thinned network. No neuron can lean on a
// fixed partner, so none of them overfit a quirk.

struct DropoutStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let rows = 4
    private let cols = 5
    @State private var dropped: Set<Int> = []
    @State private var passes = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("RUN TRAINING PASSES")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Each pass drops a random half of the neurons. The network still has to produce an answer with whoever is left, so no neuron can rely on a fixed partner.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            grid
            statusRow
            button
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var grid: some View {
        VStack(spacing: 10) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 10) {
                    ForEach(0..<cols, id: \.self) { c in
                        let i = r * cols + c
                        let off = dropped.contains(i)
                        Circle()
                            .fill(off ? inkColor.opacity(0.08) : tealAccent)
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(borderColor, lineWidth: 1))
                            .overlay(off ? Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(mutedText) : nil)
                            .animation(.snappy(duration: 0.25), value: off)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(passes >= 5 ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(passes >= 5
                 ? "Five passes, five different networks trained. At test time all neurons return, an averaged ensemble."
                 : "Pass \(passes) of 5 \u{00B7} a different thinned network each time")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var button: some View {
        Button { runPass() } label: {
            Text(passes >= 5 ? "Done \u{2713}" : "Run a training pass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(passes >= 5 ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(passes >= 5 ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(passes >= 5)
    }

    private func runPass() {
        guard passes < 5 else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        let n = rows * cols
        var pick: Set<Int> = []
        while pick.count < n / 2 { pick.insert(Int.random(in: 0..<n)) }
        withAnimation(.snappy(duration: 0.3)) { dropped = pick }
        passes += 1
        if passes == 5 {
            withAnimation(.snappy(duration: 0.3)) { dropped = [] }
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - ScaleStudio (interactive 3)
//
// AlexNet's real lesson: no single trick won, three things had to line up
// at once. Flip each dial and watch the accuracy bar. Only with all three
// does the result clear the old wall.

struct ScaleStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var bigData = false
    @State private var deepNet = false
    @State private var gpu = false

    private var accuracy: Double {
        var a = 0.58
        if bigData { a += 0.12 }
        if deepNet { a += 0.10 }
        if gpu     { a += 0.04 }
        // depth without data overfits: small penalty if deep but no data
        if deepNet && !bigData { a -= 0.06 }
        return a
    }
    private var allOn: Bool { bigData && deepNet && gpu }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("LINE UP THE DIALS")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Deep convolutional nets existed before 2012. What changed was three things arriving together. Flip them and watch the accuracy.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            accuracyBar
            dial("A million labelled images", on: $bigData,
                 detail: "ImageNet: 1.2M photos, not a few thousand")
            dial("A deep, wide network", on: $deepNet,
                 detail: "Eight learned layers, 60M parameters")
            dial("GPU training", on: $gpu,
                 detail: "Two GPUs turn weeks of compute into days")
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accuracyBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ACCURACY").font(.system(size: 10, weight: .bold)).tracking(1.6)
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(allOn ? tealAccent : inkColor.opacity(0.7))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7).fill(inkColor.opacity(0.06))
                    // old-wall marker
                    Rectangle().fill(Color(hex: "c2557a").opacity(0.6))
                        .frame(width: 2)
                        .offset(x: g.size.width * 0.74)
                    RoundedRectangle(cornerRadius: 7)
                        .fill(allOn ? tealAccent : amberAccent)
                        .frame(width: max(6, g.size.width * CGFloat(accuracy)))
                }
            }
            .frame(height: 24)
            .animation(.snappy(duration: 0.35), value: accuracy)
            Text("Rose line: the best result before 2012.")
                .font(.system(size: 11, design: .serif)).italic()
                .foregroundStyle(mutedText)
        }
    }

    private func dial(_ title: String, on: Binding<Bool>, detail: String) -> some View {
        Button { on.wrappedValue.toggle(); UIImpactFeedbackGenerator(style: .soft).impactOccurred(); check() } label: {
            HStack(spacing: 12) {
                Image(systemName: on.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on.wrappedValue ? tealAccent : inkColor.opacity(0.3))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor)
                    Text(detail)
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(mutedText)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(on.wrappedValue ? tealAccent.opacity(0.07) : inkColor.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(allOn ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(allOn
                 ? "All three together clear the old wall by a wide margin. That is the 2012 result."
                 : "No single dial is enough. They had to arrive at once.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func check() {
        if allOn {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

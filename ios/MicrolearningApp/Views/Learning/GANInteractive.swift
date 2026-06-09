import SwiftUI

// MARK: - GAN bespoke interactives
//
// Every paper so far trained one network against a fixed answer. GANs
// (2014) train two networks against each other. So these visuals are a
// contest: the reader plays the judge, a fake distribution chases a real
// one, and a noise dial drives the forger's hand.

// A fixed diamond shape on a 5x5 grid, plus a fixed flip order for noise,
// so every render of a sample is deterministic.
private let ganDiamond: Set<Int> = {
    var s = Set<Int>()
    for r in 0..<5 { for c in 0..<5 where abs(r - 2) + abs(c - 2) <= 2 { s.insert(r * 5 + c) } }
    return s
}()
private let ganFlipOrder = [7, 17, 1, 23, 11, 13, 5, 19, 3, 21, 9, 15]
private let ganTruth = [true, false, true, false, false, true, false, true]

// MARK: - GANGlyph (cover hero)
//
// Two boxes, generator and judge, with a sample passing between them and a
// verdict flashing back. The adversarial loop, looping.

struct GANGlyph: View {
    @State private var t: Double = 0

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let gPos = CGPoint(x: w * 0.22, y: h * 0.5)
            let dPos = CGPoint(x: w * 0.78, y: h * 0.5)
            ZStack {
                box("G", at: gPos, tint: amberAccent)
                box("D", at: dPos, tint: tealAccent)
                // sample travelling G -> D
                RoundedRectangle(cornerRadius: 3)
                    .fill(ink.opacity(0.7))
                    .frame(width: 16, height: 16)
                    .position(x: gPos.x + (dPos.x - gPos.x) * CGFloat(t), y: h * 0.5)
                // verdict pulse D -> G
                Circle()
                    .fill(t > 0.9 ? Color(hex: "c2557a") : .clear)
                    .frame(width: 10, height: 10)
                    .position(x: dPos.x - 20, y: h * 0.3)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                t = 1
            }
        }
    }

    private func box(_ label: String, at p: CGPoint, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(tint.opacity(0.9))
            .frame(width: 64, height: 64)
            .overlay(Text(label)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white))
            .position(p)
    }
}

// MARK: - ForgeryLadderArt (big-idea illustration)
//
// Three rounds of a forgery. Each canvas is a touch more convincing than
// the last, the verdict flipping from "caught" to "fooled". The contest
// sharpens the fake, with no teacher in the room.

struct ForgeryLadderArt: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.95)) { ctx in
            let active = Int(ctx.date.timeIntervalSinceReferenceDate / 0.95) % 3
            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { i in
                    roundCard(i, active: i == active)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func roundCard(_ i: Int, active: Bool) -> some View {
        let fooled = i == 2
        return VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 62, height: 62)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(active ? tealAccent : borderColor, lineWidth: active ? 2 : 1))
                face(detail: i)
            }
            HStack(spacing: 4) {
                Image(systemName: fooled ? "checkmark" : "xmark")
                    .font(.system(size: 9, weight: .bold))
                Text(fooled ? "fooled" : "caught")
                    .font(.system(size: 10, weight: .bold, design: .serif))
            }
            .foregroundStyle(fooled ? tealAccent : Color(hex: "c2557a"))
        }
        .scaleEffect(active ? 1.06 : 1)
        .animation(.snappy(duration: 0.3), value: active)
    }

    // The forged portrait, gaining detail each round: blob, then eyes,
    // then a smile. Cruder fakes get caught; the polished one passes.
    private func face(detail: Int) -> some View {
        ZStack {
            Circle()
                .fill(amberAccent.opacity(0.30 + 0.22 * Double(detail)))
                .frame(width: 34, height: 34)
            if detail >= 1 {
                HStack(spacing: 8) {
                    Circle().fill(inkColor).frame(width: 4, height: 4)
                    Circle().fill(inkColor).frame(width: 4, height: 4)
                }
                .offset(y: -3)
            }
            if detail >= 2 {
                Capsule()
                    .fill(inkColor)
                    .frame(width: 12, height: 3)
                    .offset(y: 8)
            }
        }
    }
}

// MARK: - SpotFakeStudio (interactive 1)
//
// You are the discriminator. Each round shows one sample, real or forged.
// Call it. The generator learns from every round, so the forgeries get
// steadily harder to catch, exactly the squeeze a real discriminator feels.

struct SpotFakeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var round = 0
    @State private var score = 0
    @State private var feedback: String? = nil

    private let totalRounds = 6
    private var done: Bool { round >= totalRounds }
    private var isReal: Bool { ganTruth[round % ganTruth.count] }

    /// The sample grid for this round. A fake flips a few cells; the number
    /// of flips shrinks as the generator improves.
    private var sample: Set<Int> {
        guard !isReal else { return ganDiamond }
        var s = ganDiamond
        let noise = max(1, 5 - round)
        for idx in ganFlipOrder.prefix(noise) {
            if s.contains(idx) { s.remove(idx) } else { s.insert(idx) }
        }
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("YOU ARE THE JUDGE")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Each round shows one sample. Some are real, some are forged by the generator. Call each one. The generator learns as you go, so the forgeries get harder.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if done { resultCard } else { sampleGrid; choiceButtons }
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sampleGrid: some View {
        let s = sample
        return GeometryReader { g in
            let cell = g.size.width / 5
            ForEach(0..<25, id: \.self) { i in
                let cx = cell * (CGFloat(i % 5) + 0.5)
                let cy = cell * (CGFloat(i / 5) + 0.5)
                let on = s.contains(i)
                RoundedRectangle(cornerRadius: 4)
                    .fill(inkColor.opacity(on ? 0.9 : 0.05))
                    .frame(width: cell - 4, height: cell - 4)
                    .position(x: cx, y: cy)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 190)
        .frame(maxWidth: .infinity)
    }

    private var choiceButtons: some View {
        HStack(spacing: 10) {
            judgeButton("Real", real: true)
            judgeButton("Forged", real: false)
        }
    }

    private func judgeButton(_ label: String, real: Bool) -> some View {
        Button { judge(callReal: real) } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(real ? tealAccent : Color(hex: "c2557a")))
        }
        .buttonStyle(.plain)
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            Text("\(score) / \(totalRounds)")
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundStyle(tealAccent)
            Text("The early forgeries were crude. The last ones were nearly perfect, because the generator improved every round. That escalation is the whole game.")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(tealAccent.opacity(0.08)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(feedback ?? (done ? "The contest is over."
                                   : "Round \(round + 1) of \(totalRounds)"))
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func judge(callReal: Bool) {
        guard !done else { return }
        let correct = callReal == isReal
        if correct { score += 1 }
        UIImpactFeedbackGenerator(style: correct ? .light : .heavy).impactOccurred()
        feedback = correct
            ? "Correct, that one was \(isReal ? "real" : "forged")."
            : "Caught out, that one was \(isReal ? "real" : "forged")."
        withAnimation(.snappy(duration: 0.25)) { round += 1 }
        if done {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - ConvergeStudio (interactive 2)
//
// The generator's output distribution starts in the wrong place, wide and
// off-centre. Each training round pulls it toward the real distribution.
// After enough rounds the two bell curves sit on top of each other.

struct ConvergeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let realMean = 0.62
    private let realStd = 0.12
    @State private var genMean = 0.22
    @State private var genStd = 0.30
    @State private var rounds = 0

    private var overlap: Double {
        let dm = abs(genMean - realMean)
        let ds = abs(genStd - realStd)
        return max(0, 1 - dm * 2.4 - ds * 1.6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("CHASE THE REAL DATA")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The teal curve is the real data. The amber curve is what the generator produces. Each training round, the generator adjusts to look more real.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            distPlot
            overlapBar
            statusRow
            button
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bell(_ x: Double, mean: Double, std: Double) -> Double {
        exp(-pow((x - mean) / std, 2) / 2)
    }

    private var distPlot: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let curve: (Double, Double, Color) -> Path = { mean, std, _ in
                Path { p in
                    for i in 0...90 {
                        let x = Double(i) / 90
                        let y = h - h * CGFloat(self.bell(x, mean: mean, std: std)) * 0.86 - h * 0.06
                        let pt = CGPoint(x: w * CGFloat(x), y: y)
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                }
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                curve(realMean, realStd, tealAccent)
                    .fill(tealAccent.opacity(0.18))
                curve(realMean, realStd, tealAccent)
                    .stroke(tealAccent, lineWidth: 2)
                curve(genMean, genStd, amberAccent)
                    .stroke(amberAccent, lineWidth: 2.5)
                    .animation(.snappy(duration: 0.4), value: genMean)
            }
        }
        .frame(height: 160)
    }

    private var overlapBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("DISTRIBUTION MATCH")
                    .font(.system(size: 10, weight: .bold)).tracking(1.6)
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(Int(overlap * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(overlap > 0.85 ? tealAccent : inkColor.opacity(0.7))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7).fill(inkColor.opacity(0.06))
                    RoundedRectangle(cornerRadius: 7)
                        .fill(overlap > 0.85 ? tealAccent : amberAccent)
                        .frame(width: max(6, g.size.width * CGFloat(overlap)))
                }
            }
            .frame(height: 20)
            .animation(.snappy(duration: 0.4), value: overlap)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(overlap > 0.85 ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(overlap > 0.85
                 ? "The two curves sit on top of each other. The forgeries are now indistinguishable from real data."
                 : "Round \(rounds) \u{00B7} the generator is still off")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var button: some View {
        Button { train() } label: {
            Text(overlap > 0.85 ? "Matched \u{2713}" : "Train one round")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(overlap > 0.85 ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(overlap > 0.85 ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(overlap > 0.85)
    }

    private func train() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.snappy(duration: 0.4)) {
            genMean += (realMean - genMean) * 0.5
            genStd += (realStd - genStd) * 0.5
            rounds += 1
        }
        if overlap > 0.85 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - LatentStudio (interactive 3)
//
// The generator is a function from random noise to a sample. Move the two
// noise dials and watch the output morph. Nothing here is stored; the
// pattern is computed fresh from the dials, the way a generator works.

struct LatentStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var z1: Double = 0
    @State private var z2: Double = 0
    @State private var moved: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("DRIVE THE FORGER")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("A generator turns random noise into a sample. The two dials are that noise. Move them and the output morphs, every setting a different forgery.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            outputGrid
            dial("Noise z\u{2081}", value: $z1, tag: 0)
            dial("Noise z\u{2082}", value: $z2, tag: 1)
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Deterministic noise-to-image map: smooth, so the grid morphs.
    private func cell(_ r: Int, _ c: Int) -> Double {
        let x = Double(c) / 4, y = Double(r) / 4
        let v = sin((x + z1) * 3.1) * cos((y + z2) * 3.1)
              + 0.5 * sin((x + y + z1 * z2) * 4.0)
        return (v + 1.5) / 3.0
    }

    private var outputGrid: some View {
        GeometryReader { g in
            let size = g.size.width / 7
            ForEach(0..<49, id: \.self) { i in
                let r = i / 7, c = i % 7
                RoundedRectangle(cornerRadius: 3)
                    .fill(tealAccent.opacity(0.12 + 0.85 * min(1, max(0, cell(r, c)))))
                    .frame(width: size - 3, height: size - 3)
                    .position(x: size * (CGFloat(c) + 0.5), y: size * (CGFloat(r) + 0.5))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 220)
        .frame(maxWidth: .infinity)
        .animation(.snappy(duration: 0.25), value: z1)
        .animation(.snappy(duration: 0.25), value: z2)
    }

    private func dial(_ label: String, value: Binding<Double>, tag: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label)  =  \(String(format: "%+.2f", value.wrappedValue))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(mutedText)
            Slider(value: value, in: -1...1) { editing in
                if !editing { moved.insert(tag); check() }
            }
            .tint(tealAccent)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(moved.count == 2 ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(moved.count == 2
                 ? "Every dial setting is a different sample, all from one trained generator. That is the prize: novel data on demand."
                 : "Move both noise dials and watch the output change.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func check() {
        if moved.count == 2 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

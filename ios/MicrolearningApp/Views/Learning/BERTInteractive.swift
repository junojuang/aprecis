import SwiftUI

// MARK: - BERT bespoke interactives
//
// 2018, Devlin et al. The encoder that learned by filling in blanks. Where
// GPT-1 only read left to right, BERT looked both ways at once. These visuals
// follow the story: a masked sentence, a word reaching back AND forward, and
// one pretrained body that any task can ride on top of.
//
// Three interactives:
//   MaskedTokenStudio    — tap a mask, watch context from both sides decide.
//   BidirectionalGazeStudio — drag the focus token, see attention fan two ways.
//   PretrainFinetuneStudio — pick a task, the same body grows a tiny head.

// One canonical sentence used across the BERT visuals so the reader meets the
// same words from the cover through every interactive.
private let bertSentence: [String] = ["the", "cat", "sat", "on", "the", "mat"]

// Mask scenarios: which slot is masked, and three plausible refills with the
// loud one tied to the bidirectional context. Tuned so a left-only reader
// could not have picked the winner from the prefix alone.
private struct BertMaskScene {
    let maskIdx: Int
    let candidates: [(word: String, score: Double, note: String)]
}

private let bertScenes: [BertMaskScene] = [
    BertMaskScene(maskIdx: 1, candidates: [
        ("cat",   0.78, "The words after the blank, \u{201C}sat on the mat,\u{201D} sound very cat-like. So BERT picks cat."),
        ("dog",   0.16, "A dog could fit the left side, but dogs don\u{2019}t usually sit on mats."),
        ("kid",   0.06, "A kid sitting on a mat is possible, just rare in the books BERT read."),
    ]),
    BertMaskScene(maskIdx: 2, candidates: [
        ("sat",   0.71, "Both sides agree. \u{201C}The cat\u{201D} before, \u{201C}on the mat\u{201D} after. Sat is the natural fit."),
        ("slept", 0.18, "Slept also fits, just a little less common in this exact shape."),
        ("ran",   0.11, "Ran clashes with \u{201C}on the mat\u{201D}, cats don\u{2019}t run while sitting on a mat."),
    ]),
    BertMaskScene(maskIdx: 5, candidates: [
        ("mat",   0.74, "Cats sit on mats a lot in the books BERT read."),
        ("rug",   0.19, "Rug works too. Slightly less common with \u{201C}the\u{201D} in front."),
        ("floor", 0.07, "Plausible, but \u{201C}the floor\u{201D} is usually said without \u{201C}the.\u{201D}"),
    ]),
]

// MARK: - BERTGlyph (cover hero)
//
// A short sentence laid flat. One token is a glowing square (the mask). Two
// soft pulses sweep in from the left and from the right and meet at the mask.
// Reads in one beat: this thing fills a blank using both sides at once.

struct BERTGlyph: View {
    @State private var t: Double = 0

    private let row: [String] = ["the", "cat", "[MASK]", "the", "mat"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let midY = h * 0.5
            ZStack {
                // The sentence chips.
                HStack(spacing: 9) {
                    ForEach(Array(row.enumerated()), id: \.offset) { i, word in
                        chip(word, isMask: i == 2)
                    }
                }
                .position(x: w * 0.5, y: midY)

                // Two arcs converging on the mask, one from each side.
                arc(from: 0.10, to: 0.50, y: midY - 38, color: tealAccent)
                arc(from: 0.90, to: 0.50, y: midY - 38, color: amberAccent)

                // Halo on the mask.
                Circle()
                    .fill(amberAccent.opacity(0.18))
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.0 + 0.18 * sin(t * .pi * 2))
                    .position(x: w * 0.5, y: midY)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                t = 1
            }
        }
    }

    private func chip(_ word: String, isMask: Bool) -> some View {
        Text(isMask ? "[MASK]" : word)
            .scaledFont(size: 12, weight: .semibold, design: .serif)
            .foregroundStyle(isMask ? .white : Color(hex: "f4f1ea"))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isMask ? amberAccent : Color(hex: "f4f1ea").opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(isMask ? amberAccent : .clear, lineWidth: 1.5))
            )
    }

    private func arc(from: CGFloat, to: CGFloat, y: CGFloat, color: Color) -> some View {
        GeometryReader { g in
            let w = g.size.width
            let p = Path { path in
                let start = CGPoint(x: w * from, y: g.size.height * 0.5)
                let end   = CGPoint(x: w * to,   y: g.size.height * 0.5)
                let mid   = CGPoint(x: (start.x + end.x) / 2, y: y)
                path.move(to: start)
                path.addQuadCurve(to: end, control: mid)
            }
            ZStack {
                p.stroke(color.opacity(0.30), lineWidth: 1.4)
                p.trim(from: max(0, t - 0.4), to: t)
                    .stroke(color, lineWidth: 2.4)
            }
        }
    }
}

// MARK: - ClozeArt (big-idea illustration)
//
// A short sentence with one blank. Two soft beams reach in from the left side
// of the sentence and the right side. They meet on the blank. The shape of
// the card is the whole idea.

struct ClozeArt: View {
    @State private var lit = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // Sentence row.
                HStack(spacing: 8) {
                    chip("the")
                    chip("cat")
                    blankChip()
                    chip("on")
                    chip("the")
                    chip("mat")
                }
                .position(x: w * 0.5, y: geo.size.height * 0.55)

                // Left context beam.
                beam(start: 0.10, end: 0.46, color: tealAccent,
                     y0: geo.size.height * 0.30)
                // Right context beam.
                beam(start: 0.90, end: 0.54, color: amberAccent,
                     y0: geo.size.height * 0.30)

                Text("LEFT CONTEXT")
                    .scaledFont(size: 9, weight: .bold).tracking(1.4)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.18, y: geo.size.height * 0.18)

                Text("RIGHT CONTEXT")
                    .scaledFont(size: 9, weight: .bold).tracking(1.4)
                    .foregroundStyle(amberAccent)
                    .position(x: w * 0.82, y: geo.size.height * 0.18)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) { lit = true }
        }
    }

    private func chip(_ word: String) -> some View {
        Text(word)
            .scaledFont(size: 12, weight: .semibold, design: .serif)
            .foregroundStyle(inkColor.opacity(0.78))
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(inkColor.opacity(0.06)))
    }

    private func blankChip() -> some View {
        Text("?")
            .scaledFont(size: 14, weight: .bold, design: .serif)
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(amberAccent)
                .shadow(color: amberAccent.opacity(0.55), radius: 8))
    }

    private func beam(start: CGFloat, end: CGFloat, color: Color,
                      y0: CGFloat) -> some View {
        GeometryReader { g in
            let w = g.size.width
            let path = Path {
                $0.move(to: CGPoint(x: w * start, y: y0))
                let control = CGPoint(x: w * (start + end) / 2, y: y0 - 10)
                $0.addQuadCurve(to: CGPoint(x: w * end, y: g.size.height * 0.5), control: control)
            }
            ZStack {
                path.stroke(color.opacity(0.20), lineWidth: 1.4)
                path.trim(from: 0, to: lit ? 1 : 0)
                    .stroke(color, lineWidth: 2.2)
                if lit {
                    Circle().fill(color).frame(width: 5, height: 5)
                        .position(x: w * end, y: g.size.height * 0.5)
                }
            }
        }
    }
}

// MARK: - LeftOnlyStrip (hero strip for the old-way prose card)
//
// Two short rows. One reader looks only left. One reader looks both ways.
// Same sentence, the unidirectional one has a question mark to the right
// of the mask because it cannot see what's there yet.

struct LeftOnlyStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row(label: "LEFT-ONLY",  leftLit: true,  rightLit: false, accent: tealAccent)
            row(label: "BIDIRECTIONAL", leftLit: true, rightLit: true, accent: amberAccent)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(label: String, leftLit: Bool, rightLit: Bool, accent: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .scaledFont(size: 9, weight: .bold).tracking(1.4)
                .foregroundStyle(accent)
                .frame(width: 92, alignment: .leading)
            tokenCell("the",  lit: leftLit)
            tokenCell("cat",  lit: leftLit)
            maskCell()
            tokenCell("the",  lit: rightLit)
            tokenCell("mat",  lit: rightLit)
        }
    }

    private func tokenCell(_ word: String, lit: Bool) -> some View {
        Text(word)
            .scaledFont(size: 10, weight: .semibold, design: .serif)
            .foregroundStyle(lit ? inkColor : inkColor.opacity(0.28))
            .padding(.horizontal, 7).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(lit ? inkColor.opacity(0.07) : inkColor.opacity(0.02)))
    }

    private func maskCell() -> some View {
        Text("?")
            .scaledFont(size: 10, weight: .bold, design: .serif)
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(RoundedRectangle(cornerRadius: 6).fill(amberAccent))
    }
}

// MARK: - BidirectionalGazeArt (illustration for the gaze card)
//
// One word in the middle of the sentence. Soft arcs from every other word
// fan toward it, both sides at once. The same image the reader will then
// drive on the next card.

struct BidirectionalGazeArt: View {
    private let words = ["the", "cat", "sat", "on", "the", "mat"]
    private let focus = 2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let positions: [CGPoint] = (0..<words.count).map { i in
                let frac = Double(i + 1) / Double(words.count + 1)
                return CGPoint(x: w * frac, y: h * 0.75)
            }
            ZStack {
                ForEach(0..<words.count, id: \.self) { i in
                    if i != focus {
                        arc(from: positions[i], to: positions[focus], h: h, color: arcColor(i))
                    }
                }
                ForEach(0..<words.count, id: \.self) { i in
                    chip(words[i], isFocus: i == focus)
                        .position(positions[i])
                }
            }
        }
    }

    private func arcColor(_ i: Int) -> Color {
        i < focus ? tealAccent : amberAccent
    }

    private func arc(from a: CGPoint, to b: CGPoint, h: CGFloat, color: Color) -> some View {
        Path { p in
            p.move(to: a)
            let mid = CGPoint(x: (a.x + b.x) / 2, y: min(a.y, b.y) - 38)
            p.addQuadCurve(to: b, control: mid)
        }
        .stroke(color.opacity(0.55), lineWidth: 1.4)
    }

    private func chip(_ word: String, isFocus: Bool) -> some View {
        Text(word)
            .scaledFont(size: 11, weight: .semibold, design: .serif)
            .foregroundStyle(isFocus ? .white : inkColor.opacity(0.75))
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(isFocus ? inkColor : inkColor.opacity(0.06)))
    }
}

// MARK: - PretrainFinetuneArt (illustration for the pretrain card)
//
// A big shaded slab labelled BERT BODY in the middle. A long ribbon of mixed
// text streams in on the left (the pretraining corpus). A small head sits on
// top of the slab with chips for downstream tasks: Q&A, sentiment, NER.

struct PretrainFinetuneArt: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("WIKIPEDIA + BOOKS")
                    .scaledFont(size: 9, weight: .bold).tracking(1.2)
                    .foregroundStyle(mutedText)
                Rectangle().fill(mutedText.opacity(0.35)).frame(height: 1)
                Image(systemName: "arrow.right")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(mutedText)
            }

            // BERT body slab.
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tealAccent.opacity(0.18))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(tealAccent, lineWidth: 1.5))
                VStack(spacing: 3) {
                    Text("BERT BODY")
                        .scaledFont(size: 11, weight: .bold).tracking(1.6)
                        .foregroundStyle(tealAccent)
                    Text("pretrained encoder · frozen or fine-tuned")
                        .scaledFont(size: 10, design: .serif)
                        .italic()
                        .foregroundStyle(inkColor.opacity(0.6))
                }
            }
            .frame(height: 64)

            // Downstream heads.
            HStack(spacing: 8) {
                Text("ADD ANY HEAD →")
                    .scaledFont(size: 9, weight: .bold).tracking(1.2)
                    .foregroundStyle(mutedText)
                headChip("Q&A", amber: true)
                headChip("Sentiment", amber: false)
                headChip("NER", amber: false)
            }
        }
        .padding(.vertical, 4)
    }

    private func headChip(_ label: String, amber: Bool) -> some View {
        Text(label)
            .scaledFont(size: 10, weight: .semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(amber ? amberAccent : inkColor.opacity(0.7)))
    }
}

// MARK: - MaskedTokenStudio (interactive 1)
//
// Tap any token to mask it. Predictions appear underneath, ranked. A small
// caption explains why the winning prediction needs the right side of the
// sentence, not just the left. Exploration completes after the reader has
// masked at least two slots.

struct MaskedTokenStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var masked: Int? = nil
    @State private var seen: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("TAP A WORD TO HIDE IT")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Tap any word. It disappears. BERT reads the rest of the sentence, both sides, and guesses what was there. Try two different words and see how the guesses change.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sentenceRow
            predictionPanel
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sentenceRow: some View {
        HStack(spacing: 7) {
            ForEach(0..<bertSentence.count, id: \.self) { i in
                Button {
                    selectMask(i)
                } label: {
                    Text(masked == i ? "[MASK]" : bertSentence[i])
                        .scaledFont(size: 13, weight: .semibold, design: .serif)
                        .foregroundStyle(masked == i ? .white : inkColor)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(masked == i ? amberAccent : inkColor.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(masked == i ? amberAccent : .clear, lineWidth: 1.5)))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var predictionPanel: some View {
        let scene = bertScenes.first { $0.maskIdx == masked }
        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundStyle(tealAccent)
                Text("BERT\u{2019}S BEST GUESSES")
                    .scaledFont(size: 10, weight: .bold).tracking(1.6)
                    .foregroundStyle(tealAccent)
                Spacer()
                if let scene {
                    Text("hidden word \(scene.maskIdx + 1)")
                        .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                        .foregroundStyle(mutedText)
                }
            }
            if let scene {
                ForEach(Array(scene.candidates.enumerated()), id: \.offset) { idx, c in
                    candidateRow(idx: idx, word: c.word, score: c.score, note: c.note)
                }
            } else {
                Text("Tap any word above to hide it.")
                    .scaledFont(size: 13, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                    .padding(.vertical, 6)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)))
        .motionAware(.snappy(duration: 0.3), value: masked)
    }

    private func candidateRow(idx: Int, word: String, score: Double, note: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(word)
                .scaledFont(size: 14, weight: .semibold, design: .serif)
                .foregroundStyle(idx == 0 ? amberAccent : inkColor)
                .frame(width: 64, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inkColor.opacity(0.06))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(idx == 0 ? amberAccent : tealAccent.opacity(0.55))
                            .frame(width: max(4, g.size.width * CGFloat(score)))
                    }
                }
                .frame(height: 8)
                Text(note)
                    .scaledFont(size: 11, design: .serif)
                    .foregroundStyle(inkColor.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statusRow: some View {
        let done = seen.count >= 2
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Two different words, two different guesses. BERT reads what is left of the sentence each time, both sides, before picking."
                 : "Words hidden so far: \(seen.count) of 2")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func selectMask(_ i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        masked = (masked == i) ? nil : i
        if let m = masked, bertScenes.contains(where: { $0.maskIdx == m }) {
            seen.insert(m)
            if seen.count >= 2 {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - BidirectionalGazeStudio (interactive 2)
//
// Tap any token to make it the focus. Arcs fan from every other token toward
// it, tinted by which side they come from. The whole point: pretraining
// taught the encoder to lean on both halves at once.

struct BidirectionalGazeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var focus: Int = 2
    @State private var seen: Set<Int> = [2]

    private let words = bertSentence

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("PICK A WORD")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Tap a word. Every other word in the sentence will reach out to it. Teal lines come from the left side. Amber lines come from the right.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            web
            legend
            sumRow
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var web: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let pos: [CGPoint] = (0..<words.count).map { i in
                CGPoint(x: w * (Double(i + 1) / Double(words.count + 1)), y: h * 0.78)
            }
            ZStack {
                ForEach(0..<words.count, id: \.self) { i in
                    if i != focus {
                        BertArc(from: pos[i], to: pos[focus],
                                color: i < focus ? tealAccent : amberAccent)
                    }
                }
                ForEach(0..<words.count, id: \.self) { i in
                    Button { pick(i) } label: {
                        chip(words[i], focus: i == focus)
                    }
                    .buttonStyle(.plain)
                    .position(pos[i])
                }
            }
        }
        .frame(height: 130)
        .padding(.horizontal, 4)
    }

    private func chip(_ word: String, focus: Bool) -> some View {
        Text(word)
            .scaledFont(size: 12, weight: .semibold, design: .serif)
            .foregroundStyle(focus ? .white : inkColor.opacity(0.78))
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(focus ? inkColor : inkColor.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(focus ? amberAccent : .clear, lineWidth: 1.5)))
    }

    private var legend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Capsule().fill(tealAccent).frame(width: 16, height: 3)
                Text("LEFT").scaledFont(size: 10, weight: .bold).tracking(1.2)
                    .foregroundStyle(tealAccent)
            }
            HStack(spacing: 6) {
                Capsule().fill(amberAccent).frame(width: 16, height: 3)
                Text("RIGHT").scaledFont(size: 10, weight: .bold).tracking(1.2)
                    .foregroundStyle(amberAccent)
            }
            Spacer()
        }
    }

    private var sumRow: some View {
        let left = focus
        let right = words.count - focus - 1
        return HStack(spacing: 10) {
            countPill(label: "WORDS ON THE LEFT",  n: left,  color: tealAccent)
            countPill(label: "WORDS ON THE RIGHT", n: right, color: amberAccent)
            Spacer()
        }
    }

    private func countPill(label: String, n: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).scaledFont(size: 9, weight: .bold).tracking(1.2)
                .foregroundStyle(color)
            Text("\(n)").scaledFont(size: 18, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.10)))
    }

    private var statusRow: some View {
        let done = seen.count >= 3
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Three different words, three different webs. Every word listens to every other word, both sides, in one go."
                 : "Words you\u{2019}ve picked: \(seen.count) of 3")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pick(_ i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.35)) { focus = i }
        seen.insert(i)
        if seen.count >= 3 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// Curve from one chip to the focus chip, tinted by side.
private struct BertArc: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    var body: some View {
        Path { p in
            p.move(to: from)
            let mid = CGPoint(x: (from.x + to.x) / 2, y: min(from.y, to.y) - 44)
            p.addQuadCurve(to: to, control: mid)
        }
        .stroke(color.opacity(0.65), lineWidth: 1.6)
    }
}

// MARK: - PretrainFinetuneStudio (interactive 3)
//
// One pretrained body, three task heads. Pick a task: the same encoder
// stays put, a small head lights up on top. The whole BERT recipe in one
// visual.

private struct BertTask: Identifiable {
    let id: String
    let label: String
    let blurb: String
    let outputs: [String]
}

private let bertTasks: [BertTask] = [
    BertTask(id: "qa",
             label: "Answer questions",
             blurb: "Job: read a paragraph and find the exact words that answer a question. The piece on top points at where the answer starts and where it ends.",
             outputs: ["start", "end"]),
    BertTask(id: "sent",
             label: "Read the mood",
             blurb: "Job: read a movie review and decide if it\u{2019}s happy or grumpy. The piece on top is just a happy-or-sad switch.",
             outputs: ["happy", "sad"]),
    BertTask(id: "ner",
             label: "Spot the names",
             blurb: "Job: read a sentence and label which words are names of people, places, or companies. The piece on top tags each word one at a time.",
             outputs: ["person", "place", "company", "none"]),
]

struct PretrainFinetuneStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var picked: String = "qa"
    @State private var seen: Set<String> = ["qa"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("ONE BRAIN, MANY JOBS")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("BERT\u{2019}s brain already understands English. To teach it a specific job, you keep the brain and add a small job-shaped piece on top. Tap each job to see what piece sits up there.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            taskPicker
            stack
            blurb
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var taskPicker: some View {
        HStack(spacing: 8) {
            ForEach(bertTasks) { t in
                Button { pick(t.id) } label: {
                    Text(t.label)
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundStyle(picked == t.id ? .white : tealAccent)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .fill(picked == t.id ? tealAccent : tealAccent.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var stack: some View {
        VStack(spacing: 6) {
            // Head
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(amberAccent.opacity(0.20))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(amberAccent, lineWidth: 1.5))
                HStack(spacing: 6) {
                    Text(headBadge)
                        .scaledFont(size: 10, weight: .bold).tracking(1.4)
                        .foregroundStyle(amberAccent)
                    Spacer()
                    ForEach(currentTask.outputs, id: \.self) { o in
                        Text(o)
                            .scaledFont(size: 10, weight: .semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 4)
                            .background(Capsule().fill(amberAccent))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 38)
            .motionAware(.snappy(duration: 0.3), value: picked)

            Image(systemName: "arrow.up")
                .scaledFont(size: 11, weight: .bold)
                .foregroundStyle(mutedText)

            // Body
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tealAccent.opacity(0.18))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(tealAccent, lineWidth: 1.5))
                VStack(spacing: 2) {
                    Text("BERT\u{2019}S BRAIN")
                        .scaledFont(size: 11, weight: .bold).tracking(1.6)
                        .foregroundStyle(tealAccent)
                    Text("Trained for weeks on billions of sentences. Already understands English.")
                        .scaledFont(size: 10, design: .serif)
                        .italic()
                        .foregroundStyle(inkColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
            }
            .frame(height: 70)
        }
    }

    private var blurb: some View {
        Text(currentTask.blurb)
            .scaledFont(size: 13, design: .serif)
            .foregroundStyle(inkColor.opacity(0.78))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(amberAccent.opacity(0.10)))
    }

    private var statusRow: some View {
        let done = seen.count >= bertTasks.count
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Same brain, three different jobs. This is the move that made BERT famous: train once, then teach it anything."
                 : "Jobs tried: \(seen.count) of \(bertTasks.count)")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentTask: BertTask {
        bertTasks.first { $0.id == picked } ?? bertTasks[0]
    }

    private var headBadge: String {
        switch picked {
        case "qa":   return "QA HEAD"
        case "sent": return "CLASSIFIER HEAD"
        case "ner":  return "PER-TOKEN HEAD"
        default:     return "HEAD"
        }
    }

    private func pick(_ id: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) { picked = id }
        seen.insert(id)
        if seen.count >= bertTasks.count {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

import SwiftUI

// MARK: - GPT-3 bespoke interactives
//
// Hand-built interactive diagrams for the "Language Models are Few-Shot
// Learners" lesson (Brown et al., 2020). Same editorial language as the
// perceptron and attention sets: every diagram is specific to the idea it
// teaches, drawn with SwiftUI shapes, no web view. The lesson runs on one
// picture: a brilliant new hire who has read everything but is taught a new
// job not by training, only by a few examples on a note.

// Accents the GPT-3 set leans on beyond the brand teal/amber.
private let gptGreen       = Color(hex: "1f7a4d")   // a correct answer
private let gptRust        = Color(hex: "b6502a")   // a wrong answer
private let gptGreenBright = Color(hex: "3fae74")   // correct, on the dark plate
private let gptRustBright  = Color(hex: "d6764a")   // wrong, on the dark plate

// MARK: Prediction fan glyph (cover hero)
//
// A minimal living next-token prediction for the editorial cover: one context
// node fans into a spread of candidate tokens, the likeliest one bright, a
// pulse running to it. Light strokes, reads on the dark cover.

struct PredictionFanGlyph: View {
    @State private var pulse = false

    private let ink = Color(hex: "f4f1ea")
    private let probs: [CGFloat] = [1.0, 0.52, 0.34, 0.22, 0.13]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let src = CGPoint(x: w * 0.16, y: h * 0.5)
            let n = probs.count
            let cand: [CGPoint] = (0..<n).map { i in
                let t = CGFloat(i) / CGFloat(n - 1)
                return CGPoint(x: w * 0.84, y: h * (0.16 + 0.68 * t))
            }

            ZStack {
                ForEach(0..<n, id: \.self) { i in
                    Path { p in p.move(to: src); p.addLine(to: cand[i]) }
                        .stroke(tealMid.opacity(0.2 + 0.5 * probs[i]),
                                lineWidth: 1 + 3 * probs[i])
                }
                ForEach(0..<n, id: \.self) { i in
                    Circle()
                        .fill(i == 0 ? tealAccent : ink.opacity(0.45))
                        .frame(width: i == 0 ? 22 : 12, height: i == 0 ? 22 : 12)
                        .overlay(Circle().stroke(ink.opacity(0.8),
                                                 lineWidth: i == 0 ? 2 : 0))
                        .position(cand[i])
                }
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tealAccent)
                    .frame(width: 46, height: 34)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(ink.opacity(0.85), lineWidth: 2))
                    .position(src)
                Circle()
                    .fill(amberAccent)
                    .frame(width: 8, height: 8)
                    .position(x: pulse ? cand[0].x : src.x,
                              y: pulse ? cand[0].y : src.y)
                    .opacity(pulse ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

// MARK: PromptNoteArt (big-idea illustration)
//
// A sticky note holding two worked examples and one open question. The whole
// of GPT-3's "teaching": you do not retrain the hire, you just hand them a
// note.

struct PromptNoteArt: View {
    private let examples = [("sea", "ocean"), ("happy", "joyful")]

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 9) {
                Text("THE PROMPT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(mutedText)
                ForEach(examples.indices, id: \.self) { i in
                    exampleRow(examples[i].0, examples[i].1, query: false)
                }
                Rectangle().fill(borderColor).frame(height: 1)
                exampleRow("cold", "?", query: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "fffdf4"))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: 1))
                    .shadow(color: inkColor.opacity(0.08), radius: 6, y: 3))
            .rotationEffect(.degrees(-1.6))
        }
        .frame(maxWidth: .infinity)
    }

    private func exampleRow(_ a: String, _ b: String, query: Bool) -> some View {
        HStack(spacing: 9) {
            Text(a)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
            Image(systemName: "arrow.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(mutedText)
            Text(b)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(query ? tealAccent : inkColor)
                .frame(minWidth: 22)
                .padding(.horizontal, query ? 8 : 0)
                .padding(.vertical, query ? 3 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(query ? tealLight : Color.clear))
            Spacer(minLength: 0)
        }
    }
}

// MARK: TaskZooArt (the old way)
//
// Before GPT-3: one trained model per task, each with its own labelled
// dataset. A row of small machine boxes, each sitting on its own stack of
// training data.

struct TaskZooArt: View {
    private let tasks = ["Translate", "Summarize", "Answer", "Classify"]

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            ForEach(tasks.indices, id: \.self) { i in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(borderColor, lineWidth: 1))
                        .frame(height: 38)
                        .overlay(
                            Image(systemName: "cpu")
                                .font(.system(size: 14))
                                .foregroundStyle(mutedText))
                    Text(tasks[i])
                        .font(.system(size: 9, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.72))
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(amberAccent.opacity(0.5))
                                .frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: NextTokenArt (how-it-trains illustration)
//
// One context line and the spread of next-token guesses, each with its
// probability. The one boring game GPT-3 plays across the whole internet.

struct NextTokenArt: View {
    private let context = "The cat sat on the"
    private let cands: [(String, Double)] = [
        ("mat", 0.61), ("rug", 0.19), ("sofa", 0.12), ("roof", 0.08),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                Text(context)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(inkColor)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(tealLight)
                    .frame(width: 26, height: 24)
                    .overlay(Text("?")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(tealAccent))
            }
            .padding(.bottom, 1)
            ForEach(cands.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    Text(cands[i].0)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(i == 0 ? tealAccent : inkColor.opacity(0.6))
                        .frame(width: 46, alignment: .leading)
                    GeometryReader { g in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tealAccent.opacity(i == 0 ? 0.9 : 0.4))
                            .frame(width: max(4, g.size.width * CGFloat(cands[i].1)))
                    }
                    .frame(height: 14)
                    Text("\(Int(cands[i].1 * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(mutedText)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: ScaleBarsArt (scale illustration)
//
// The size jump, drawn honestly: a square-root scale so the older models
// stay visible at all, and GPT-3 still towers. The drama is the point.

struct ScaleBarsArt: View {
    private let models: [(name: String, label: String, params: Double)] = [
        ("BERT",  "340M", 0.34),
        ("GPT-2", "1.5B", 1.5),
        ("GPT-3", "175B", 175),
    ]

    var body: some View {
        GeometryReader { g in
            let maxV = 175.0
            HStack(alignment: .bottom, spacing: 18) {
                ForEach(models.indices, id: \.self) { i in
                    let frac = sqrt(models[i].params / maxV)
                    VStack(spacing: 6) {
                        Text(models[i].label)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(i == 2 ? tealAccent : mutedText)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(i == 2 ? tealAccent : inkColor.opacity(0.22))
                            .frame(height: max(7, g.size.height * 0.66 * CGFloat(frac)))
                        Text(models[i].name)
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundStyle(inkColor.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
    }
}

// MARK: DecoderStackArt (architecture illustration)
//
// GPT-3 is not a new architecture: it is the Transformer decoder from the
// last paper, the same block stacked 96 times. Tokens in at the bottom, one
// next token out at the top.

struct DecoderStackArt: View {
    var body: some View {
        VStack(spacing: 5) {
            Text("NEXT TOKEN")
                .font(.system(size: 8, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(tealAccent)
            Image(systemName: "arrow.up")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(mutedText)
            ForEach(0..<3, id: \.self) { _ in block }
            Text("\u{22EE}")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(mutedText)
            block
            Text("\u{00D7} 96 layers")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(mutedText)
            Image(systemName: "arrow.up")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(mutedText)
            Text("TOKENS IN")
                .font(.system(size: 8, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(mutedText)
        }
    }

    private var block: some View {
        Text("Masked Attention + Feed-Forward")
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundStyle(inkColor)
            .frame(maxWidth: .infinity, minHeight: 26)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(tealAccent.opacity(0.5), lineWidth: 1.3)))
    }
}

// MARK: GPT3Timeline (impact timeline)
//
// The four-step run from the first GPT to the chatbot everyone met.

struct GPT3Timeline: View {
    private struct Milestone { let year: String; let label: String; let accent: Bool }
    private let milestones: [Milestone] = [
        Milestone(year: "2018", label: "GPT-1",   accent: false),
        Milestone(year: "2019", label: "GPT-2",   accent: false),
        Milestone(year: "2020", label: "GPT-3",   accent: true),
        Milestone(year: "2022", label: "ChatGPT", accent: false),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(milestones.indices, id: \.self) { i in
                    Text(milestones[i].year)
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }
            ZStack {
                Rectangle().fill(inkColor.opacity(0.35)).frame(height: 1)
                HStack(spacing: 0) {
                    ForEach(milestones.indices, id: \.self) { i in
                        Circle()
                            .fill(milestones[i].accent ? tealAccent : inkColor.opacity(0.75))
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(paperBg, lineWidth: 2.5))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 16)
            .padding(.vertical, 6)
            HStack(spacing: 0) {
                ForEach(milestones.indices, id: \.self) { i in
                    Text(milestones[i].label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - FewShotPromptPlayground
//
// The reader switches between zero, one and three worked examples in the
// prompt and watches the same frozen model go from a wrong guess to the right
// answer. A "weights: frozen" badge never changes, which is the whole point:
// nothing was trained, only the prompt grew. Unlocks at the three-shot payoff.

struct FewShotPromptPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let modes = ["0-shot", "1-shot", "3-shot"]
    private let examples = [("sea", "mer"), ("bread", "pain"), ("cheese", "fromage")]
    private let query = "milk"
    private let shownCounts = [0, 1, 3]
    private let outputs = ["milk", "lait?", "lait"]
    private let accuracies = [9, 56, 97]

    @State private var mode = 0

    private var shownCount: Int { shownCounts[mode] }
    private var output: String { outputs[mode] }
    private var correct: Bool { mode == 2 }
    private var accuracy: Int { accuracies[mode] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("SHOW, DON\u{2019}T TRAIN")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The task: translate to French. Add worked examples to the prompt and watch the same model improve. It is never retrained, the prompt just grows.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            modeSelector
            promptPlate
            scoreRow
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(modes.indices, id: \.self) { i in
                let isSel = mode == i
                Text(modes[i])
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSel ? .white : tealAccent)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSel ? tealAccent : tealAccent.opacity(0.12)))
                    .onTapGesture { pick(i) }
            }
        }
    }

    private var promptPlate: some View {
        VStack(alignment: .leading, spacing: 7) {
            if shownCount == 0 {
                Text("(no examples)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(hex: "f4f1ea").opacity(0.35))
            }
            ForEach(0..<shownCount, id: \.self) { i in
                promptLine(examples[i].0, examples[i].1, isQuery: false)
            }
            Rectangle()
                .fill(Color(hex: "f4f1ea").opacity(0.12))
                .frame(height: 1)
                .padding(.vertical, 1)
            promptLine(query, output, isQuery: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "10131a"))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tealAccent.opacity(0.45), lineWidth: 1)
            }
        )
        .animation(.snappy(duration: 0.25), value: mode)
    }

    private func promptLine(_ a: String, _ b: String, isQuery: Bool) -> some View {
        HStack(spacing: 0) {
            Text(a + "  \u{2192}  ")
                .foregroundColor(Color(hex: "f4f1ea").opacity(0.85))
            Text(b)
                .foregroundColor(isQuery
                                 ? (correct ? gptGreenBright : gptRustBright)
                                 : tealMid)
            if isQuery {
                Text(correct ? "  \u{2713}" : "  \u{2717}")
                    .foregroundColor(correct ? gptGreenBright : gptRustBright)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var scoreRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ACCURACY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(mutedText)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(inkColor.opacity(0.08))
                        Capsule()
                            .fill(correct ? gptGreen : amberAccent)
                            .frame(width: g.size.width * CGFloat(accuracy) / 100)
                    }
                }
                .frame(height: 10)
            }
            Text("\(accuracy)%")
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(correct ? gptGreen : inkColor.opacity(0.7))
            HStack(spacing: 5) {
                Image(systemName: "lock.fill").font(.system(size: 9))
                Text("WEIGHTS\nFROZEN")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(tealAccent)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tealAccent.opacity(0.1)))
        }
        .animation(.snappy(duration: 0.25), value: mode)
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(correct ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(correct
                 ? "Three examples and the answer is right. Not one weight moved."
                 : "Add more examples to the prompt. The model itself never changes.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pick(_ i: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) { mode = i }
        if i == 2 {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - NextTokenPlayground
//
// The reader builds a sentence one token at a time, each step choosing from
// the model's ranked guesses. It makes the autoregressive loop tactile:
// generation is just "pick the next token, read it back in, repeat". Unlocks
// after three tokens have been placed.

struct NextTokenPlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let start = "The robot opened the"
    private let candidateSets: [[(String, Double)]] = [
        [("door", 0.54), ("box", 0.23), ("window", 0.15), ("file", 0.08)],
        [("and", 0.42), ("slowly", 0.27), ("then", 0.19), ("but", 0.12)],
        [("looked", 0.39), ("waited", 0.29), ("paused", 0.20), ("turned", 0.12)],
        [("inside", 0.46), ("around", 0.30), ("up", 0.14), ("away", 0.10)],
    ]

    @State private var words: [String] = []
    @State private var picks = 0

    private var sentence: String {
        ([start] + words).joined(separator: " ")
    }
    private var candidates: [(String, Double)] {
        candidateSets[min(picks, candidateSets.count - 1)]
    }
    private var done: Bool { picks >= candidateSets.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("BUILD THE SENTENCE")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The model only ever does one thing: rank the next token. Tap a guess to place it, and watch the sentence feed back into the model.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sentencePanel
            if done { donePanel } else { candidatePanel }
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sentencePanel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(sentence + " ")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(inkColor)
            if !done {
                Text("\u{25AE}")
                    .font(.system(size: 15))
                    .foregroundStyle(tealAccent)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)))
    }

    private var candidatePanel: some View {
        VStack(spacing: 8) {
            ForEach(candidates.indices, id: \.self) { i in
                let c = candidates[i]
                Button {
                    place(c.0)
                } label: {
                    HStack(spacing: 10) {
                        Text(c.0)
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(inkColor)
                            .frame(width: 74, alignment: .leading)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(inkColor.opacity(0.06))
                                Capsule()
                                    .fill(tealAccent.opacity(i == 0 ? 0.9 : 0.45))
                                    .frame(width: max(6, g.size.width * CGFloat(c.1)))
                            }
                        }
                        .frame(height: 12)
                        Text("\(Int(c.1 * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(mutedText)
                            .frame(width: 38, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(borderColor, lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var donePanel: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(tealAccent)
            Text("Four tokens, four passes through the model. That loop is all generation ever is.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(tealAccent.opacity(0.1)))
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(picks > 0 ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(picks == 0
                 ? "Tap a guess to place the next token."
                 : "Tokens placed: \(picks). Each one was read back in before the next.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func place(_ word: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) {
            words.append(word)
            picks += 1
        }
        if picks >= 3 { progress.markExplored(cardId) }
    }
}

// MARK: - ScaleEmergencePlayground
//
// The reader drags through four model sizes; a strip of capabilities flips
// from fail to pass. The jump from 13B to 175B lights arithmetic and
// reasoning at once, the emergent step that defines the paper. Unlocks once
// the reader reaches the largest model.

struct ScaleEmergencePlayground: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let sizes = ["125M", "1.3B", "13B", "175B"]
    private let capabilities = ["Grammar", "Translation", "Arithmetic", "Reasoning"]
    // pass[stage][capability]
    private let pass: [[Bool]] = [
        [true,  false, false, false],
        [true,  true,  false, false],
        [true,  true,  false, false],
        [true,  true,  true,  true ],
    ]

    @State private var stage = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)

            Text("DRAG THROUGH THE SIZES")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Same training, same task list. Drag from the small model to the large one and watch which abilities switch on.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sizeReadout
            sizeTrack
            capabilityStrip
            caption

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sizeReadout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(sizes[stage])
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(tealAccent)
            Text("parameters")
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(mutedText)
        }
    }

    private var sizeTrack: some View {
        GeometryReader { g in
            let w = g.size.width
            let knobX = CGFloat(stage) / 3 * (w - 28)
            ZStack(alignment: .leading) {
                Capsule().fill(inkColor.opacity(0.08)).frame(height: 6)
                Capsule()
                    .fill(tealAccent)
                    .frame(width: knobX + 14, height: 6)
                ForEach(sizes.indices, id: \.self) { i in
                    Circle()
                        .fill(i <= stage ? tealAccent : inkColor.opacity(0.2))
                        .frame(width: 9, height: 9)
                        .position(x: 14 + CGFloat(i) / 3 * (w - 28), y: 14)
                }
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(tealAccent, lineWidth: 2.5))
                    .shadow(color: inkColor.opacity(0.15), radius: 3, y: 1)
                    .offset(x: knobX)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let raw = (v.location.x - 14) / (w - 28)
                        let next = min(max(0, Int((raw * 3).rounded())), 3)
                        if next != stage { setStage(next) }
                    }
            )
        }
        .frame(height: 28)
    }

    private var capabilityStrip: some View {
        VStack(spacing: 8) {
            ForEach(capabilities.indices, id: \.self) { c in
                let on = pass[stage][c]
                let newlyOn = on && (stage == 0 ? false : !pass[stage - 1][c])
                HStack(spacing: 10) {
                    Image(systemName: on ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(on ? tealAccent : inkColor.opacity(0.25))
                    Text(capabilities[c])
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(on ? inkColor : inkColor.opacity(0.4))
                    Spacer()
                    if newlyOn {
                        Text("UNLOCKED")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(amberAccent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(amberAccent.opacity(0.15)))
                    }
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(on ? tealAccent.opacity(0.06) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)))
            }
        }
        .animation(.snappy(duration: 0.25), value: stage)
    }

    private var caption: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stage == 3 ? tealAccent : amberAccent)
                .frame(width: 9, height: 9)
            Text(stage == 3
                 ? "From 13B to 175B, two abilities appeared at once. Nobody trained them in."
                 : "Keep dragging. The big jump is at the largest model.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func setStage(_ s: Int) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.snappy(duration: 0.25)) { stage = s }
        if s == 3 { progress.markExplored(cardId) }
    }
}

// MARK: - FewShotScalingChart (the central finding)
//
// GPT-3's contribution is not an algorithm: it is this shape. Accuracy on the
// three prompt settings rises with model size, and the few-shot line pulls
// away from zero-shot as the model grows. The paper's core figure, rebuilt
// from SwiftUI paths. The widening gap is the whole claim: a bigger model is
// better at learning from the examples in its prompt.

struct FewShotScalingChart: View {
    private struct Series {
        let name: String
        let tint: Color
        let bold: Bool
        let pts: [CGFloat]   // accuracy 0...1 at each model size
    }
    private let xLabels = ["0.1B", "1B", "13B", "175B"]
    private let series: [Series] = [
        Series(name: "few-shot",  tint: tealAccent,  bold: true,
               pts: [0.12, 0.34, 0.58, 0.76]),
        Series(name: "one-shot",  tint: amberAccent, bold: false,
               pts: [0.11, 0.26, 0.45, 0.58]),
        Series(name: "zero-shot", tint: mutedText,   bold: false,
               pts: [0.10, 0.20, 0.33, 0.42]),
    ]

    var body: some View {
        VStack(spacing: 9) {
            chart
            xAxis
            legend
        }
    }

    private var chart: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let n = xLabels.count
            let px: (Int) -> CGFloat = { 6 + (w - 12) * CGFloat($0) / CGFloat(n - 1) }
            let py: (CGFloat) -> CGFloat = { h - 8 - (h - 14) * $0 }

            ZStack {
                // faint gridlines
                ForEach(0..<3, id: \.self) { r in
                    let yy = h * CGFloat(r) / 2
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: yy))
                        p.addLine(to: CGPoint(x: w, y: yy))
                    }
                    .stroke(borderColor, lineWidth: 0.6)
                }
                // the three series
                ForEach(series.indices, id: \.self) { s in
                    let serie = series[s]
                    Path { p in
                        for i in 0..<n {
                            let pt = CGPoint(x: px(i), y: py(serie.pts[i]))
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                    }
                    .stroke(serie.tint,
                            style: StrokeStyle(lineWidth: serie.bold ? 3 : 1.8,
                                               lineCap: .round, lineJoin: .round))
                    ForEach(0..<n, id: \.self) { i in
                        Circle()
                            .fill(serie.tint)
                            .frame(width: serie.bold ? 7 : 5,
                                   height: serie.bold ? 7 : 5)
                            .position(x: px(i), y: py(serie.pts[i]))
                    }
                }
                // the widening-gap marker at the largest model
                Path { p in
                    p.move(to: CGPoint(x: px(n - 1) - 16, y: py(series[0].pts[n - 1])))
                    p.addLine(to: CGPoint(x: px(n - 1) - 16, y: py(series[2].pts[n - 1])))
                }
                .stroke(inkColor.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }
        }
    }

    private var xAxis: some View {
        HStack(spacing: 0) {
            ForEach(xLabels.indices, id: \.self) { i in
                Text(xLabels[i])
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mutedText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(series.indices, id: \.self) { s in
                HStack(spacing: 5) {
                    Capsule()
                        .fill(series[s].tint)
                        .frame(width: 14, height: series[s].bold ? 3.5 : 2.5)
                    Text(series[s].name)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(mutedText)
                }
            }
        }
    }
}

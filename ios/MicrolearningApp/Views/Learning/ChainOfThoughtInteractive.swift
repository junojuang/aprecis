import SwiftUI

// MARK: - Chain-of-Thought bespoke interactives
//
// 2022, Wei et al. (Google). A large model already holds the reasoning; it just
// answers too fast. Show worked examples and it writes its own chain, carrying
// intermediate results forward instead of leaping to a guess. The twist: this
// only emerges at scale. Small models write fluent-but-muddled chains.
//
// The diagrams here are built around CoT's own mechanism, not a generic
// compare-two-rows template:
//   StraightVsWorkingStudio - step a reasoning chain and watch a running
//                             register carry the value forward to the answer.
//   PromptBuilderStudio      - flip the worked examples on and watch the model
//                             copy the habit on a fresh question.
//   CoTScaleStudio           - drag model size and read the model's actual chain
//                             morph from muddled to coherent as it crosses the
//                             emergence threshold.

private let cotRose = Color(hex: "d46a6a")

// MARK: - ChainOfThoughtGlyph (cover hero)
//
// A question chip, a chain of numbered step links, and a resolved answer. The
// chain draws itself left to right: the answer is reached by walking steps.

struct ChainOfThoughtGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let midY = h * 0.5
            let stepXs = [0.40, 0.55, 0.70].map { $0 * w }
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.26, y: midY))
                    p.addLine(to: CGPoint(x: w * 0.78, y: midY))
                }
                .trim(from: 0, to: t)
                .stroke(tealAccent.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                chip(text: "?", fill: Color(hex: "f4f1ea").opacity(0.10),
                     stroke: Color(hex: "f4f1ea").opacity(0.35), fg: Color(hex: "f4f1ea"))
                    .position(x: w * 0.17, y: midY)

                ForEach(Array(stepXs.enumerated()), id: \.offset) { i, x in
                    Text("\(i + 1)")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: "f4f1ea"))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(tealAccent.opacity(0.30))
                            .overlay(Circle().stroke(tealAccent, lineWidth: 1.4)))
                        .position(x: x, y: midY)
                        .opacity(t > Double(i) * 0.28 ? 1 : 0.2)
                }

                chip(text: "\u{2713}", fill: tealAccent, stroke: tealAccent, fg: .white)
                    .position(x: w * 0.85, y: midY)
                    .opacity(t > 0.85 ? 1 : 0.25)

                Text("SHOW YOUR WORKING")
                    .font(.system(size: 9, weight: .bold)).tracking(1.8)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.5, y: midY + 44)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                t = 1
            }
        }
    }

    private func chip(text: String, fill: Color, stroke: Color, fg: Color) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .serif))
            .foregroundStyle(fg)
            .frame(width: 38, height: 38)
            .background(RoundedRectangle(cornerRadius: 9).fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(stroke, lineWidth: 1.5)))
    }
}

// MARK: - StandardVsCoTArt (big-idea illustration)
//
// Bespoke to CoT: a single leap that lands on a wrong number, above a chain
// whose nodes each hold the running value as it is carried to the right answer.

struct StandardVsCoTArt: View {
    var body: some View {
        VStack(spacing: 12) {
            // The leap: question jumps straight to a wrong number.
            HStack(spacing: 8) {
                miniChip("Q", tint: mutedText)
                ZStack {
                    leapArc.stroke(cotRose.opacity(0.65),
                                   style: StrokeStyle(lineWidth: 1.6, dash: [3, 3]))
                        .frame(width: 90, height: 26)
                    Text("leap").font(.system(size: 8, weight: .bold)).tracking(0.5)
                        .foregroundStyle(cotRose).offset(y: -16)
                }
                valueChip("8", correct: false)
            }
            // The chain: each node carries the running value forward.
            HStack(spacing: 6) {
                miniChip("Q", tint: tealAccent)
                arrow
                carryNode(step: "2\u{00D7}3", value: "6")
                arrow
                carryNode(step: "5+6", value: "11")
                arrow
                valueChip("11", correct: true)
            }
        }
        .padding(.vertical, 6)
    }

    private var leapArc: Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 22))
            p.addQuadCurve(to: CGPoint(x: 90, y: 22), control: CGPoint(x: 45, y: -8))
        }
    }
    private var arrow: some View {
        Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold))
            .foregroundStyle(mutedText)
    }
    private func miniChip(_ t: String, tint: Color) -> some View {
        Text(t).font(.system(size: 12, weight: .bold, design: .serif))
            .foregroundStyle(inkColor.opacity(0.8))
            .frame(width: 30, height: 30)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(tint.opacity(0.5), lineWidth: 1)))
    }
    private func carryNode(step: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(step).font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(inkColor.opacity(0.75))
            Text("= \(value)").font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(tealAccent)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(tealAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(tealAccent.opacity(0.35), lineWidth: 1)))
    }
    private func valueChip(_ t: String, correct: Bool) -> some View {
        HStack(spacing: 3) {
            Text(t).font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(.white)
            Image(systemName: correct ? "checkmark" : "xmark")
                .font(.system(size: 8, weight: .black)).foregroundStyle(.white)
        }
        .padding(.horizontal, 9).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(correct ? tealAccent : cotRose))
    }
}

// MARK: - FewShotArt (illustration)
//
// The CoT mechanism itself: the prompt is worked examples, then your question.

struct FewShotArt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("THE PROMPT YOU SEND")
                .font(.system(size: 9, weight: .bold)).tracking(1.3)
                .foregroundStyle(mutedText)
            exemplar(q: "Q: 2 apples + 3 apples?", work: "2 and 3 make 5.", a: "A: 5", solved: true)
            exemplar(q: "Q: 4 cats + 1 cat?", work: "4 and 1 make 5.", a: "A: 5", solved: true)
            exemplar(q: "Q: your question", work: nil, a: nil, solved: false)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }

    private func exemplar(q: String, work: String?, a: String?, solved: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(q).font(.system(size: 11.5, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.85))
            if let work {
                Text(work).font(.system(size: 11, design: .serif)).italic()
                    .foregroundStyle(tealAccent)
            }
            if let a {
                Text(a).font(.system(size: 11.5, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.85))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(solved ? tealAccent.opacity(0.06) : amberAccent.opacity(0.10)))
    }
}

// MARK: - ScaleCurveArt (illustration)
//
// Bespoke emergence: two "brains" at small and large size. The small one
// scribbles a muddled chain; the large one writes clean steps. A threshold
// line marks where the skill switches on.

struct ScaleCurveArt: View {
    var body: some View {
        HStack(spacing: 10) {
            brain(title: "SMALL", lines: ["balls are 3", "so 30?"],
                  coherent: false)
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(amberAccent)
                Text("threshold").font(.system(size: 8, weight: .bold)).tracking(0.5)
                    .foregroundStyle(amberAccent)
            }
            brain(title: "LARGE", lines: ["2\u{00D7}3 = 6", "5+6 = 11"],
                  coherent: true)
        }
        .padding(.vertical, 4)
    }

    private func brain(title: String, lines: [String], coherent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12)).foregroundStyle(coherent ? tealAccent : mutedText)
                Text(title).font(.system(size: 9, weight: .bold)).tracking(1.0)
                    .foregroundStyle(coherent ? tealAccent : mutedText)
            }
            ForEach(lines, id: \.self) { l in
                Text(l)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(coherent ? inkColor.opacity(0.8) : cotRose.opacity(0.8))
                    .italic(!coherent)
            }
            HStack(spacing: 3) {
                Image(systemName: coherent ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 11)).foregroundStyle(coherent ? tealAccent : cotRose)
                Text(coherent ? "lands it" : "muddled")
                    .font(.system(size: 9, weight: .semibold)).foregroundStyle(mutedText)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill((coherent ? tealAccent : mutedText).opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke((coherent ? tealAccent : mutedText).opacity(0.3), lineWidth: 1)))
    }
}

// MARK: - StraightVsWorkingStudio (interactive 1)
//
// Bespoke: step the reasoning chain and watch a running register carry the
// value forward. The "blurt" path leaps to a wrong number; the chain accrues
// 5 -> +6 -> 11. Revealing the whole chain completes the card.

private struct CoTChainProblem {
    let prompt: String
    let blurt: String
    let start: Int
    let steps: [CoTStep]
}
private struct CoTStep {
    let thought: String     // what the model writes
    let runs: String        // running register after this step (e.g. "5 + 6 = 11")
    let value: Int          // numeric register after this step
}

private let cotChain = CoTChainProblem(
    prompt: "Roger has 5 tennis balls. He buys 2 cans, with 3 balls in each. How many balls does he have now?",
    blurt: "10",
    start: 5,
    steps: [
        CoTStep(thought: "First, the new balls: 2 cans \u{00D7} 3 each = 6.", runs: "carry 6", value: 6),
        CoTStep(thought: "Add them to the 5 he started with: 5 + 6.", runs: "5 + 6 = 11", value: 11),
    ]
)

struct StraightVsWorkingStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var revealed = 0          // how many chain steps are shown
    @State private var showedBlurt = false

    private var done: Bool { revealed >= cotChain.steps.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("WALK THE CHAIN")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The model can answer this two ways. Tap the quick guess to see it leap, then reveal the chain one thought at a time and watch the running total carry forward.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptCard
            blurtRow
            chainAndRegister
            revealButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.32), value: revealed)
        .animation(.snappy(duration: 0.3), value: showedBlurt)
    }

    private var promptCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 16)).foregroundStyle(amberAccent)
            Text(cotChain.prompt)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(amberAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(amberAccent.opacity(0.3), lineWidth: 1)))
    }

    private var blurtRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            showedBlurt = true
        } label: {
            HStack(spacing: 10) {
                Text("QUICK GUESS").font(.system(size: 9, weight: .bold)).tracking(1.3)
                    .foregroundStyle(mutedText)
                Spacer(minLength: 0)
                if showedBlurt {
                    HStack(spacing: 4) {
                        Text(cotChain.blurt).font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(inkColor)
                        Image(systemName: "xmark.circle.fill").foregroundStyle(cotRose)
                    }
                } else {
                    Text("tap to leap").font(.system(size: 12, design: .serif)).italic()
                        .foregroundStyle(tealAccent)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 11)
                .fill(showedBlurt ? cotRose.opacity(0.07) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var chainAndRegister: some View {
        HStack(alignment: .top, spacing: 12) {
            // The chain of thoughts, revealed one at a time.
            VStack(alignment: .leading, spacing: 8) {
                Text("REASONING CHAIN").font(.system(size: 9, weight: .bold)).tracking(1.3)
                    .foregroundStyle(tealAccent)
                ForEach(0..<cotChain.steps.count, id: \.self) { i in
                    thoughtBox(i: i, shown: i < revealed)
                }
                if done {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(tealAccent)
                        Text("Answer: 11").font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundStyle(inkColor)
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            register
        }
    }

    private func thoughtBox(i: Int, shown: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(i + 1)")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(shown ? .white : mutedText)
                .frame(width: 22, height: 22)
                .background(Circle().fill(shown ? tealAccent : mutedText.opacity(0.15)))
            Text(shown ? cotChain.steps[i].thought : "hidden thought")
                .font(.system(size: 13, design: .serif))
                .italic(!shown)
                .foregroundStyle(shown ? inkColor.opacity(0.85) : mutedText.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 9)
            .fill(shown ? tealAccent.opacity(0.06) : Color.white)
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(borderColor, lineWidth: 1)))
    }

    private var register: some View {
        let current = revealed == 0 ? cotChain.start : cotChain.steps[revealed - 1].value
        return VStack(spacing: 6) {
            Text("REGISTER").font(.system(size: 8, weight: .bold)).tracking(1.2)
                .foregroundStyle(mutedText)
            Text("\(current)")
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(done ? tealAccent : inkColor)
                .contentTransition(.numericText())
            Text(revealed == 0 ? "start" : cotChain.steps[revealed - 1].runs)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 92)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(tealAccent.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tealAccent.opacity(0.3), lineWidth: 1)))
    }

    @ViewBuilder
    private var revealButton: some View {
        if !done {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                revealed += 1
                if revealed >= cotChain.steps.count {
                    progress.markExplored(cardId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } label: {
                Text(revealed == 0 ? "Reveal first thought" : "Reveal next thought")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 11).fill(tealAccent))
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Each thought fed the next: the 6 carried into 5 + 6 = 11. Writing the chain is what stops the model leaping to a guess like 10."
                 : "Reveal each thought and watch the register carry the value forward.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - PromptBuilderStudio (interactive 2)
//
// The only thing CoT changes is the examples. Flip the working on and the model
// copies the habit on a fresh question: it reasons out loud and gets it right.

struct PromptBuilderStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var showWorking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("BUILD THE PROMPT")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("No retraining is involved. You just show the model a couple of examples first, and it copies their style. Flip the switch to put the working into your examples, and watch what the model does with a fresh question.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            toggleRow
            examplesCard
            modelAnswerCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: showWorking)
    }

    private var toggleRow: some View {
        Toggle(isOn: $showWorking) {
            Text("Show the working in the examples")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
        }
        .tint(tealAccent)
        .onChange(of: showWorking) { _, on in
            UISelectionFeedbackGenerator().selectionChanged()
            if on {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var examplesCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("YOUR EXAMPLES")
                .font(.system(size: 9, weight: .bold)).tracking(1.3)
                .foregroundStyle(mutedText)
            exemplar(q: "Q: 5 birds, 2 fly away. Left?",
                     work: showWorking ? "5 minus 2 is 3." : nil, a: "A: 3")
            exemplar(q: "Q: 8 sweets, eat 3. Left?",
                     work: showWorking ? "8 minus 3 is 5." : nil, a: "A: 5")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }

    private func exemplar(q: String, work: String?, a: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(q).font(.system(size: 12, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.85))
            if let work {
                Text(work).font(.system(size: 11.5, design: .serif)).italic()
                    .foregroundStyle(tealAccent)
            }
            Text(a).font(.system(size: 12, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.85))
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(tealAccent.opacity(0.05)))
    }

    private var modelAnswerCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: "cpu").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(showWorking ? tealAccent : mutedText)
                Text("NEW QUESTION: 6 marbles, lose 4, find 5. How many?")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            if showWorking {
                Text("Start with 6. Lose 4, that leaves 2. Find 5 more, so 2 plus 5 is 7.")
                    .font(.system(size: 13.5, design: .serif)).italic()
                    .foregroundStyle(tealAccent)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(tealAccent)
                    Text("A: 7").font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(inkColor)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(cotRose)
                    Text("A: 2").font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(inkColor)
                    Text("(jumped straight to a guess)")
                        .font(.system(size: 11, design: .serif)).italic()
                        .foregroundStyle(mutedText)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(showWorking ? tealAccent.opacity(0.07) : cotRose.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(showWorking ? tealAccent.opacity(0.5) : borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(showWorking ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(showWorking
                 ? "The model copied your examples: it reasoned out loud, then answered, and got it right. One prompt change, no training."
                 : "Without working in the examples, the model mimics that too: it blurts a wrong answer. Flip the switch.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - CoTScaleStudio (interactive 3)
//
// Bespoke emergence: drag model size and read the model's actual chain of
// thought morph from muddled to coherent as it crosses the threshold. The
// accuracy chip snaps up with it. Reaching the largest model completes.

private struct CoTSizeSample {
    let params: String
    let chain: [String]      // the model's written chain at this size
    let coherent: Bool
    let answer: String
    let correct: Bool
    let accuracy: Int
    let note: String
}

private let cotSizeSamples: [CoTSizeSample] = [
    CoTSizeSample(
        params: "0.4B",
        chain: ["roger has cans.", "balls is 3 and 5.", "so the answer is 30."],
        coherent: false, answer: "30", correct: false, accuracy: 5,
        note: "Tiny model. It writes a chain, but the steps do not follow from one another. Spelling out the working does not help here."),
    CoTSizeSample(
        params: "7B",
        chain: ["2 cans, 3 each.", "5 plus 3 is 8."],
        coherent: false, answer: "8", correct: false, accuracy: 11,
        note: "Bigger, and the steps read sensibly, but it still drops a step: it forgot to multiply the cans first."),
    CoTSizeSample(
        params: "60B",
        chain: ["2 cans \u{00D7} 3 = 6.", "5 + 6 = 11."],
        coherent: true, answer: "11", correct: true, accuracy: 33,
        note: "Now the chain holds together. Each step follows from the last, and it lands the right answer."),
    CoTSizeSample(
        params: "540B",
        chain: ["New balls: 2 cans \u{00D7} 3 = 6.", "Total: 5 + 6 = 11."],
        coherent: true, answer: "11", correct: true, accuracy: 57,
        note: "At full scale the chain is clean and reliable. Same prompt, but the reasoning only switched on once the model was large."),
]

struct CoTScaleStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var reachedTop = false

    private var idx: Int { min(cotSizeSamples.count - 1, max(0, Int(level.rounded()))) }
    private var sample: CoTSizeSample { cotSizeSamples[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("DRAG UP THE MODEL SIZE")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Same question, same prompt, four model sizes. Slide the size up and read the model's own chain of thought. Watch it go from muddled scribble to clean reasoning as it crosses the threshold.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sizePicker
            chainCard
            noteCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.32), value: idx)
    }

    private var sizePicker: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(cotSizeSamples.enumerated()), id: \.offset) { i, s in
                    Text(s.params)
                        .font(.system(size: 11, weight: i == idx ? .bold : .regular, design: .monospaced))
                        .foregroundStyle(i == idx ? tealAccent : mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            Slider(value: $level, in: 0...Double(cotSizeSamples.count - 1), step: 1)
                .tint(tealAccent)
                .onChange(of: level) { _, _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    if idx == cotSizeSamples.count - 1, !reachedTop {
                        reachedTop = true
                        progress.markExplored(cardId)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
        }
    }

    private var chainCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13)).foregroundStyle(sample.coherent ? tealAccent : mutedText)
                    Text("\(sample.params) model writes:")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.8))
                }
                Spacer()
                Text("\(sample.accuracy)%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(sample.coherent ? tealAccent : cotRose)
                    .contentTransition(.numericText())
            }
            Divider()
            ForEach(Array(sample.chain.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 13.5, design: .monospaced))
                    .italic(!sample.coherent)
                    .foregroundStyle(sample.coherent ? inkColor.opacity(0.85) : cotRose.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                Image(systemName: sample.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(sample.correct ? tealAccent : cotRose)
                Text("Answer: \(sample.answer)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(inkColor)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(sample.coherent ? tealAccent.opacity(0.06) : cotRose.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke((sample.coherent ? tealAccent : cotRose).opacity(0.35), lineWidth: 1)))
    }

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(sample.params)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(tealAccent.opacity(0.12)))
            Text(sample.note)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(inkColor.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(reachedTop ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(reachedTop
                 ? "The reasoning was not taught; it was latent in the big model and the prompt let it out. That sudden switch-on with size is why CoT is called an emergent ability."
                 : "Slide to the largest model to see the chain become coherent.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

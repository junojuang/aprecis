import SwiftUI

// MARK: - InstructGPT bespoke interactives
//
// 2022, OpenAI. The paper that taught a raw language model to follow human
// intent. GPT-3 was huge and knew a great deal, but it only predicted the
// next likely word, not what you actually asked for. InstructGPT closed that
// gap with a three step recipe: show good answers (SFT), let humans rank
// answers to train a reward model, then nudge the model toward what people
// preferred (RLHF). The headline: a 1.3B InstructGPT was preferred over the
// 175B GPT-3, one hundred times its size.
//
// Three interactives:
//   InstructionGapStudio - feel the gap between "next likely word" and intent.
//   RankStudio           - rank answers best to worst, the reward model's food.
//   RLHFLoopStudio       - generate, score, nudge: watch the answer get better.

// MARK: - InstructGPTGlyph (cover hero)
//
// A prompt chip on the left feeds a model box. Below, three little ranked
// tags (1,2,3) push up into the model, human feedback shaping it. On the
// right, the output resolves into a checked, aligned answer.

struct InstructGPTGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let midY = h * 0.46
            ZStack {
                // Feedback rising into the model.
                ForEach(0..<3, id: \.self) { i in
                    let x = w * (0.40 + Double(i) * 0.07)
                    Path { p in
                        p.move(to: CGPoint(x: x, y: h * 0.86))
                        p.addLine(to: CGPoint(x: w * 0.50, y: midY + 22))
                    }
                    .trim(from: 0, to: t)
                    .stroke(amberAccent.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [2, 4]))
                }

                // Prompt chip.
                chip(text: "do X", fill: Color(hex: "f4f1ea").opacity(0.10),
                     stroke: Color(hex: "f4f1ea").opacity(0.35), fg: Color(hex: "f4f1ea"), wide: true)
                    .position(x: w * 0.17, y: midY)

                // Connecting line prompt -> model.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.30, y: midY))
                    p.addLine(to: CGPoint(x: w * 0.42, y: midY))
                }
                .stroke(tealAccent.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                // Model box.
                Text("LLM")
                    .scaledFont(size: 14, weight: .bold, design: .serif)
                    .foregroundStyle(Color(hex: "f4f1ea"))
                    .frame(width: 50, height: 44)
                    .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.22))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tealAccent, lineWidth: 1.5)))
                    .position(x: w * 0.50, y: midY)

                // Aligned output chip.
                chip(text: "✓", fill: tealAccent, stroke: tealAccent, fg: .white)
                    .position(x: w * 0.82, y: midY)
                    .opacity(t > 0.6 ? 1 : 0.3)

                Path { p in
                    p.move(to: CGPoint(x: w * 0.58, y: midY))
                    p.addLine(to: CGPoint(x: w * 0.74, y: midY))
                }
                .trim(from: 0, to: t)
                .stroke(tealAccent.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                Text("HUMAN FEEDBACK")
                    .scaledFont(size: 9, weight: .bold).tracking(1.8)
                    .foregroundStyle(amberAccent)
                    .position(x: w * 0.5, y: h * 0.95)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                t = 1
            }
        }
    }

    private func chip(text: String, fill: Color, stroke: Color, fg: Color, wide: Bool = false) -> some View {
        Text(text)
            .scaledFont(size: wide ? 13 : 15, weight: .bold, design: .serif)
            .foregroundStyle(fg)
            .frame(width: wide ? 54 : 38, height: 38)
            .background(RoundedRectangle(cornerRadius: 9).fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(stroke, lineWidth: 1.5)))
    }
}

// MARK: - AlignmentGapArt (big-idea illustration)
//
// Two columns for the same prompt. Left: what a raw language model does,
// predict a plausible next word. Right: what you actually wanted. The gap
// between them is the whole problem InstructGPT set out to close.

struct AlignmentGapArt: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .scaledFont(size: 12, weight: .bold).foregroundStyle(amberAccent)
                Text("\u{201C}Explain the moon to a child.\u{201D}")
                    .scaledFont(size: 12.5, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 9).fill(amberAccent.opacity(0.08)))

            HStack(alignment: .top, spacing: 10) {
                column(tag: "RAW MODEL", tagColor: mutedText,
                       body: "\u{201C}Explain the sun to a child. Explain the stars to a child...\u{201D}",
                       note: "predicts likely next words",
                       tint: mutedText)
                column(tag: "WHAT YOU WANTED", tagColor: tealAccent,
                       body: "\u{201C}The moon is a big rock that circles the Earth and glows at night.\u{201D}",
                       note: "follows your intent",
                       tint: tealAccent)
            }
        }
        .padding(.vertical, 4)
    }

    private func column(tag: String, tagColor: Color, body: String, note: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tag).scaledFont(size: 9, weight: .bold).tracking(1.2)
                .foregroundStyle(tagColor)
            Text(body)
                .scaledFont(size: 12, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
            Text(note).scaledFont(size: 9, design: .serif).italic()
                .foregroundStyle(inkColor.opacity(0.5))
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.45), lineWidth: 1)))
    }
}

// MARK: - ThreeStepArt (the recipe, illustration)
//
// SFT -> Reward Model -> RLHF as a left to right flow, the spine of the paper.

struct ThreeStepArt: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                step(num: "1", label: "SFT", sub: "copy good\nanswers", tint: tealAccent)
                arrow()
                step(num: "2", label: "REWARD", sub: "rank, then\nscore", tint: amberAccent)
                arrow()
                step(num: "3", label: "RLHF", sub: "nudge toward\npreferred", tint: tealAccent)
            }
            Text("DEMONSTRATE \u{00B7} RANK \u{00B7} REINFORCE")
                .scaledFont(size: 9, weight: .bold).tracking(1.4)
                .foregroundStyle(mutedText)
        }
        .padding(.vertical, 4)
    }

    private func step(num: String, label: String, sub: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(num).scaledFont(size: 11, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(tint))
            Text(label).scaledFont(size: 10, weight: .bold).tracking(0.8)
                .foregroundStyle(tint)
            Text(sub).scaledFont(size: 8.5, design: .serif).italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(inkColor.opacity(0.55))
        }
        .padding(.horizontal, 8).padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.5), lineWidth: 1)))
    }

    private func arrow() -> some View {
        Image(systemName: "arrow.right")
            .scaledFont(size: 11, weight: .bold)
            .foregroundStyle(mutedText)
    }
}

// MARK: - RankArt (reward-model illustration)
//
// Four answers to one prompt, badged 1 to 4 by a human, feeding a reward
// model box that turns the ranking into a score it can hand out forever.

struct RankArt: View {
    private let ranks = ["1", "2", "3", "4"]

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(ranks.enumerated()), id: \.offset) { i, r in
                    HStack(spacing: 8) {
                        Text(r).scaledFont(size: 10, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(i == 0 ? tealAccent : (i == 3 ? amberAccent : mutedText)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inkColor.opacity(0.08))
                            .frame(width: CGFloat(74 - i * 14), height: 10)
                    }
                }
            }
            VStack(spacing: 3) {
                Image(systemName: "arrow.right")
                    .scaledFont(size: 13, weight: .bold).foregroundStyle(mutedText)
                Text("teaches").scaledFont(size: 8, weight: .semibold).tracking(0.6)
                    .foregroundStyle(mutedText)
            }
            VStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .scaledFont(size: 22).foregroundStyle(amberAccent)
                Text("REWARD\nMODEL").scaledFont(size: 9, weight: .bold).tracking(0.6)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(amberAccent)
                Text("scores any\nanswer").scaledFont(size: 8.5, design: .serif).italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(inkColor.opacity(0.55))
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(amberAccent.opacity(0.5), lineWidth: 1)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - PPOLoopArt (RLHF illustration)
//
// The reinforcement loop: the model writes an answer, the reward model scores
// it, and the score nudges the model. A small leash keeps it near the SFT
// model so it improves without drifting into nonsense.

struct PPOLoopArt: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                node("MODEL", sub: "writes answer", tint: tealAccent)
                arrow()
                node("REWARD", sub: "scores it", tint: amberAccent)
            }
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.left")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(amberAccent)
                Text("NUDGE TOWARD HIGHER SCORES \u{00B7} KEEP IT ON A LEASH")
                    .scaledFont(size: 9, weight: .bold).tracking(1.0)
                    .foregroundStyle(amberAccent)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 9).fill(amberAccent.opacity(0.10)))
        }
        .padding(.vertical, 4)
    }

    private func node(_ label: String, sub: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).scaledFont(size: 10, weight: .bold).tracking(1.2)
                .foregroundStyle(tint)
            Text(sub).scaledFont(size: 9, design: .serif).italic()
                .foregroundStyle(inkColor.opacity(0.55))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.5), lineWidth: 1)))
    }

    private func arrow() -> some View {
        Image(systemName: "arrow.right")
            .scaledFont(size: 11, weight: .bold)
            .foregroundStyle(mutedText)
    }
}

// MARK: - InstructionGapStudio (interactive 1)
//
// A prompt with two completions: what a raw next-word model produces, and what
// the user actually meant. The reader picks the one that "did what you asked".
// Choosing the helpful one twice reveals the alignment gap and completes.

private struct IGGapScene: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let prompt: String
    let raw: String        // plausible continuation, ignores intent
    let aligned: String    // follows the instruction
    let why: String        // what the aligned answer got right
}

private let igGapScenes: [IGGapScene] = [
    IGGapScene(
        prompt: "Write a short thank-you note to my aunt.",
        raw: "Write a short thank-you note to my uncle. Write a birthday card for my mum.",
        aligned: "Dear Aunt, thank you so much for the lovely gift. It made my week. Love, me.",
        why: "It actually wrote the note instead of listing more tasks."),
    IGGapScene(
        prompt: "Explain why the sky is blue, simply.",
        raw: "Explain why the sky is blue. Explain why grass is green. Explain why the sea is salty.",
        aligned: "Sunlight is made of colors. Air scatters the blue light most, so the sky looks blue.",
        why: "It answered the question in plain words a person can use."),
    IGGapScene(
        prompt: "Give me three names for a pet rabbit.",
        raw: "Here is a list of things people ask about rabbits, including diet, housing, and lifespan.",
        aligned: "Clover, Pepper, and Biscuit.",
        why: "It gave exactly what was asked: three names, nothing else."),
]

struct InstructionGapStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var sceneIdx = 0
    @State private var verdict: Bool? = nil      // true = picked aligned
    @State private var pickedRight: Set<Int> = []

    private var scene: IGGapScene { igGapScenes[sceneIdx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("WHICH ONE DID WHAT YOU ASKED?")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("A raw language model only predicts likely next words. That is not the same as doing what you asked. Both answers below are things GPT-3 might write. Tap the one that actually followed the instruction.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptCard
            candidate(isAligned: false, text: scene.raw)
            candidate(isAligned: true, text: scene.aligned)
            learnRow
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: verdict)
        .motionAware(.snappy(duration: 0.3), value: sceneIdx)
    }

    private var promptCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.bubble.fill")
                .scaledFont(size: 16).foregroundStyle(amberAccent)
            Text(scene.prompt)
                .scaledFont(size: 16, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(amberAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(amberAccent.opacity(0.3), lineWidth: 1)))
    }

    private func candidate(isAligned: Bool, text: String) -> some View {
        let chosen = verdict == isAligned && verdict != nil
        return Button {
            pick(isAligned: isAligned)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(isAligned ? "FOLLOWED THE INSTRUCTION" : "PREDICTED NEXT WORDS")
                        .scaledFont(size: 9, weight: .bold).tracking(1.4)
                        .foregroundStyle(isAligned ? tealAccent : mutedText)
                    Text(text)
                        .scaledFont(size: 14, design: .serif)
                        .foregroundStyle(inkColor.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: chosen
                      ? (isAligned ? "checkmark.circle.fill" : "xmark.circle.fill")
                      : "circle")
                    .scaledFont(size: 16)
                    .foregroundStyle(chosen ? (isAligned ? tealAccent : mutedText) : mutedText.opacity(0.5))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(chosen && isAligned ? tealAccent.opacity(0.08) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(chosen && isAligned ? tealAccent : borderColor,
                            lineWidth: chosen && isAligned ? 1.5 : 1)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var learnRow: some View {
        if let v = verdict {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: v ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .scaledFont(size: 14)
                    .foregroundStyle(v ? tealAccent : amberAccent)
                VStack(alignment: .leading, spacing: 6) {
                    Text(v
                         ? "Yes. \(scene.why)"
                         : "That one just kept predicting plausible text. It is fluent, but it ignored what you wanted.")
                        .scaledFont(size: 13, weight: .semibold, design: .serif)
                        .foregroundStyle(inkColor.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        verdict = nil
                        sceneIdx = (sceneIdx + 1) % igGapScenes.count
                    } label: {
                        Text(v ? "Next prompt \u{2192}" : "Try again")
                            .scaledFont(size: 12, weight: .semibold)
                            .foregroundStyle(tealAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill((v ? tealAccent : amberAccent).opacity(0.08)))
        }
    }

    private var statusRow: some View {
        let done = pickedRight.count >= 2
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "That gap, between predicting text and doing what you asked, is exactly what InstructGPT set out to close."
                 : "Helpful answers spotted: \(pickedRight.count) of 2")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pick(isAligned: Bool) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        verdict = isAligned
        if isAligned {
            pickedRight.insert(sceneIdx)
            if pickedRight.count >= 2 {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - RankStudio (interactive 2)
//
// The reward-model step. For one prompt the model wrote four answers. The
// reader taps them best to worst, assigning ranks. There is no single right
// order, that is the point: the reward model learns to copy whatever taste
// the labeler shows. Completing one full ranking marks the card explored.

private struct IGAnswer: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let text: String
    let tag: String
}

struct RankStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let prompt = "How do I stay calm before a big exam?"
    @State private var answers: [IGAnswer] = [
        IGAnswer(text: "Breathe slowly, sleep well, and revise a little each day so nothing piles up.", tag: "helpful"),
        IGAnswer(text: "Just don't be nervous. Exams are easy if you are smart.", tag: "dismissive"),
        IGAnswer(text: "Exams are a social construct designed by an unfair system.", tag: "off-topic"),
        IGAnswer(text: "Try a short walk and a glass of water before you start.", tag: "okay"),
    ]
    @State private var ranking: [Int] = []   // answer indices, best first
    @State private var trained = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("RANK THE ANSWERS, BEST FIRST")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("You cannot write a rule for a good answer. So InstructGPT had people rank them instead. The model wrote four replies to one prompt. Tap them in order, best first. There is no official key, the reward model just learns to copy your taste.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptCard
            ForEach(Array(answers.enumerated()), id: \.element.id) { idx, ans in
                answerRow(idx: idx, ans: ans)
            }
            controlRow
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: ranking)
    }

    private var promptCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.bubble.fill")
                .scaledFont(size: 16).foregroundStyle(amberAccent)
            Text(prompt)
                .scaledFont(size: 16, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(amberAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(amberAccent.opacity(0.3), lineWidth: 1)))
    }

    private func answerRow(idx: Int, ans: IGAnswer) -> some View {
        let rank = ranking.firstIndex(of: idx)
        let ranked = rank != nil
        return Button {
            tap(idx)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ranked ? rankColor(rank!) : Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(ranked ? rankColor(rank!) : borderColor, lineWidth: 1.5))
                    if let r = rank {
                        Text("\(r + 1)").scaledFont(size: 13, weight: .bold)
                            .foregroundStyle(.white)
                    }
                }
                Text(ans.text)
                    .scaledFont(size: 14, design: .serif)
                    .foregroundStyle(inkColor.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(ranked ? rankColor(rank!).opacity(0.07) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(ranked ? rankColor(rank!).opacity(0.6) : borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .disabled(trained)
    }

    private func rankColor(_ r: Int) -> Color {
        switch r {
        case 0:  return tealAccent
        case 3:  return amberAccent
        default: return mutedText
        }
    }

    @ViewBuilder
    private var controlRow: some View {
        if trained {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .scaledFont(size: 14).foregroundStyle(amberAccent)
                Text("Reward model trained. It now scores any new answer to look more like your number one and less like your number four, even on prompts it has never seen.")
                    .scaledFont(size: 13, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(amberAccent.opacity(0.10)))

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                ranking = []
                trained = false
                answers.shuffle()
            } label: {
                Text("Rank again")
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundStyle(tealAccent)
            }
            .buttonStyle(.plain)
        } else if !ranking.isEmpty {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                ranking = []
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward").scaledFont(size: 11, weight: .semibold)
                    Text("Clear ranking").scaledFont(size: 12, weight: .semibold)
                }
                .foregroundStyle(mutedText)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(trained ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(trained
                 ? "Do this across thousands of prompts and the reward model captures what people actually prefer, no rulebook required."
                 : "Ranked: \(ranking.count) of \(answers.count). Tap answers best to worst.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tap(_ idx: Int) {
        guard !trained, !ranking.contains(idx) else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        ranking.append(idx)
        if ranking.count == answers.count {
            trained = true
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - RLHFLoopStudio (interactive 3)
//
// The reinforcement step. Each tap, the model writes a fresh answer, the
// reward model scores it, and the policy is nudged toward higher scores. The
// answer visibly improves and the reward meter climbs. A KL "leash" note keeps
// it honest: it cannot drift too far from the sensible SFT model. Three rounds
// completes the card.

private struct IGRLStep {
    let answer: String
    let reward: Double
}

private let igRLSteps: [IGRLStep] = [
    IGRLStep(answer: "exam exam exam study study", reward: 0.12),
    IGRLStep(answer: "Study hard and you will be fine, probably.", reward: 0.44),
    IGRLStep(answer: "Break revision into small daily chunks and sleep well the night before.", reward: 0.71),
    IGRLStep(answer: "Revise a little each day, sleep properly, and take slow breaths before you start. You've got this.", reward: 0.93),
]

struct RLHFLoopStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var step = 0

    private var current: IGRLStep { igRLSteps[step] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("RLHF \u{00B7} GENERATE, SCORE, NUDGE")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Now put the reward model to work. The model writes an answer, the reward model scores it, and that score nudges the model toward replies people prefer. Tap to run a round and watch the answer get better.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            answerCard
            rewardMeter
            leashNote
            runButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.35), value: step)
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("THE MODEL'S ANSWER")
                .scaledFont(size: 9, weight: .bold).tracking(1.4)
                .foregroundStyle(mutedText)
            Text("\u{201C}\(current.answer)\u{201D}")
                .scaledFont(size: 15, design: .serif)
                .foregroundStyle(inkColor.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }

    private var rewardMeter: some View {
        HStack(spacing: 10) {
            Text("REWARD")
                .scaledFont(size: 9, weight: .bold).tracking(1.4)
                .foregroundStyle(mutedText)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(inkColor.opacity(0.07))
                    Capsule().fill(LinearGradient(colors: [amberAccent, tealAccent],
                                                  startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(current.reward))
                }
            }
            .frame(height: 8)
            Text(String(format: "%.2f", current.reward))
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundStyle(inkColor.opacity(0.7))
                .frame(width: 44, alignment: .trailing)
        }
    }

    private var leashNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .scaledFont(size: 11, weight: .semibold).foregroundStyle(tealAccent)
            Text("A KL leash keeps each step close to the sensible SFT model, so it improves without drifting into gibberish.")
                .scaledFont(size: 11, design: .serif).italic()
                .foregroundStyle(inkColor.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var runButton: some View {
        if step < igRLSteps.count - 1 {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                step += 1
                if step >= igRLSteps.count - 1 {
                    progress.markExplored(cardId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath").scaledFont(size: 13)
                    Text("Run a round").scaledFont(size: 13, weight: .semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(Capsule().fill(tealAccent))
            }
            .buttonStyle(.plain)
        } else {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                step = 0
            } label: {
                Text("Reset").scaledFont(size: 12, weight: .semibold).foregroundStyle(tealAccent)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        let done = step >= igRLSteps.count - 1
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "From noise to a genuinely helpful reply, all by chasing the reward model's score. This loop, run at scale, is what made a 1.3B model beat the 175B GPT-3 on what people prefer."
                 : "Rounds run: \(step) of \(igRLSteps.count - 1)")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

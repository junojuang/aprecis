import SwiftUI

// MARK: - Least-to-Most bespoke interactives
//
// 2022, Zhou et al. (Google). "Least-to-Most Prompting Enables Complex
// Reasoning in Large Language Models." A chain of thought solves a problem in
// one pass; least-to-most splits it into two stages. First decompose the hard
// problem into a list of simpler subquestions ordered easiest-first. Then solve
// them in sequence, feeding each answer into the next. Because the model never
// faces more than one small step, it generalises to problems deeper than any in
// its examples.
//
// Diagrams built around the two stages:
//   DecomposeStudio  - break one hard problem into ordered subquestions.
//   SolveLadderStudio- climb the subquestions, each answer feeding the next.
//   DepthStudio      - a test deeper than the examples: a chain stalls at the
//                      depth it saw, decomposition keeps going.

private let l2mRose = Color(hex: "d46a6a")

// MARK: - LeastToMostGlyph (cover hero)
//
// A big problem block splits into a descending staircase of smaller blocks
// that climb to a checked answer.

struct LeastToMostGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let steps = 3
            ZStack {
                // Big problem block at top-left.
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "f4f1ea").opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "f4f1ea").opacity(0.35), lineWidth: 1.4))
                    .frame(width: w * 0.26, height: h * 0.2)
                    .position(x: w * 0.2, y: h * 0.24)
                // Descending rungs.
                ForEach(0..<steps, id: \.self) { i in
                    let x = w * (0.36 + Double(i) * 0.16)
                    let y = h * (0.4 + Double(i) * 0.16)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(tealAccent.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(tealAccent, lineWidth: 1.3))
                        .frame(width: w * 0.18, height: h * 0.12)
                        .position(x: x, y: y)
                        .opacity(t > Double(i) * 0.3 ? 1 : 0.2)
                }
                Image(systemName: "checkmark.circle.fill")
                    .scaledFont(size: 22).foregroundStyle(tealAccent)
                    .position(x: w * 0.84, y: h * 0.86)
                    .opacity(t > 0.85 ? 1 : 0.2)
                Text("EASIEST STEP FIRST")
                    .scaledFont(size: 9, weight: .bold).tracking(1.8)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.5, y: h * 0.96)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) { t = 1 }
        }
    }
}

// MARK: - DecomposeVsChainArt (big-idea illustration)
//
// Chain: one block, one leap. Least-to-most: the block fans into ordered
// subquestions before any answering happens.

struct DecomposeVsChainArt: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CHAIN OF THOUGHT").scaledFont(size: 9, weight: .bold).tracking(1.3)
                    .foregroundStyle(mutedText)
                HStack(spacing: 6) {
                    block("hard problem", tint: mutedText, wide: true)
                    Image(systemName: "arrow.right").scaledFont(size: 9, weight: .bold).foregroundStyle(mutedText)
                    block("answer in one go", tint: mutedText, wide: true)
                }
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(mutedText.opacity(0.05)))

            VStack(alignment: .leading, spacing: 6) {
                Text("LEAST TO MOST").scaledFont(size: 9, weight: .bold).tracking(1.3)
                    .foregroundStyle(tealAccent)
                HStack(spacing: 6) {
                    block("hard problem", tint: tealAccent, wide: true)
                    Image(systemName: "arrow.right").scaledFont(size: 9, weight: .bold).foregroundStyle(tealAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        block("sub 1", tint: tealAccent, wide: false)
                        block("sub 2", tint: tealAccent, wide: false)
                        block("sub 3", tint: tealAccent, wide: false)
                    }
                }
                Text("decompose first, then solve in order")
                    .scaledFont(size: 10, design: .serif).italic().foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
    private func block(_ s: String, tint: Color, wide: Bool) -> some View {
        Text(s).scaledFont(size: 10.5, weight: .semibold, design: .serif)
            .foregroundStyle(inkColor.opacity(0.8))
            .padding(.horizontal, 9).padding(.vertical, 6)
            .frame(maxWidth: wide ? .infinity : nil, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.5), lineWidth: 1)))
    }
}

// MARK: - SubstitutionArt (illustration)
//
// Shows the carry: a solved subanswer is slotted into the next subquestion.

struct SubstitutionArt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            rung(q: "Q1: marbles in the bags?", a: "12", solved: true)
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right").scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(amberAccent)
                Text("the 12 slots into the next question")
                    .scaledFont(size: 10, design: .serif).italic().foregroundStyle(mutedText)
            }
            .padding(.leading, 12)
            rung(q: "Q2: 5 + 12 = ?", a: "17", solved: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }
    private func rung(q: String, a: String, solved: Bool) -> some View {
        HStack(spacing: 10) {
            Text(q).scaledFont(size: 12, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
            Spacer(minLength: 0)
            Text(a).scaledFont(size: 13, weight: .bold, design: .monospaced).foregroundStyle(.white)
                .frame(width: 34, height: 28)
                .background(RoundedRectangle(cornerRadius: 7).fill(tealAccent))
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(tealAccent.opacity(0.06)))
    }
}

// MARK: - DecomposeStudio (interactive 1)
//
// Stage one: break a hard problem into ordered subquestions, easiest first.
// Tap to peel off each subquestion. No answers yet, just the plan. Revealing
// all of them completes the card.

private struct L2MSub {
    let question: String
    let answer: String
    let work: String
}

private let l2mSubs: [L2MSub] = [
    L2MSub(question: "How many marbles are in the 3 bags?", answer: "12", work: "3 bags \u{00D7} 4 each = 12"),
    L2MSub(question: "How many after adding them to the 5 she had?", answer: "17", work: "5 + 12 = 17"),
    L2MSub(question: "How many after she gives 6 away?", answer: "11", work: "17 - 6 = 11"),
]

struct DecomposeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var revealed = 0

    private var done: Bool { revealed >= l2mSubs.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("BREAK IT DOWN FIRST")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Before solving anything, least-to-most plans. Tap to break this problem into a list of smaller questions, ordered easiest first. Notice there are no answers yet, just the plan.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            problemCard
            subsList
            revealButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: revealed)
    }

    private var problemCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "questionmark.circle.fill").scaledFont(size: 16).foregroundStyle(amberAccent)
            Text("Amy has 5 marbles. She buys 3 bags with 4 marbles each, then gives 6 away. How many does she have now?")
                .scaledFont(size: 15, weight: .semibold, design: .serif).foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(amberAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(amberAccent.opacity(0.3), lineWidth: 1)))
    }

    private var subsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<l2mSubs.count, id: \.self) { i in
                if i < revealed {
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)").scaledFont(size: 12, weight: .bold, design: .serif).foregroundStyle(.white)
                            .frame(width: 24, height: 24).background(Circle().fill(tealAccent))
                        Text(l2mSubs[i].question)
                            .scaledFont(size: 14, design: .serif).foregroundStyle(inkColor.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(11).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tealAccent.opacity(0.25), lineWidth: 1)))
                }
            }
        }
    }

    @ViewBuilder
    private var revealButton: some View {
        if !done {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                revealed += 1
                if done { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
            } label: {
                Text(revealed == 0 ? "Find the first subquestion" : "Find the next subquestion")
                    .scaledFont(size: 14, weight: .semibold).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 11).fill(tealAccent))
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "That is the decomposition stage. The model wrote a plan of simpler questions before answering a single one, each one a small step toward the goal."
                 : "Peel off each subquestion to build the plan.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - SolveLadderStudio (interactive 2)
//
// Stage two: climb the subquestions in order. Each answer is slotted into the
// next subquestion before it is solved. Solving all rungs completes the card.

struct SolveLadderStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var solved = 0

    private var done: Bool { solved >= l2mSubs.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("CLIMB THE LADDER")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Now solve the subquestions in order. Each answer is carried into the next question before you solve it, so the model only ever faces one small step at a time.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            ladder
            solveButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.32), value: solved)
    }

    private var ladder: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<l2mSubs.count, id: \.self) { i in
                rung(i: i)
            }
            if done {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(tealAccent)
                    Text("Final answer: 11 marbles").scaledFont(size: 14, weight: .bold, design: .serif)
                        .foregroundStyle(inkColor)
                }
                .padding(.top, 2)
            }
        }
    }

    private func rung(i: Int) -> some View {
        let isSolved = i < solved
        let isCurrent = i == solved
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(i + 1)").scaledFont(size: 12, weight: .bold, design: .serif)
                    .foregroundStyle(isSolved || isCurrent ? .white : mutedText)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(isSolved ? tealAccent : (isCurrent ? amberAccent : mutedText.opacity(0.15))))
                Text(l2mSubs[i].question)
                    .scaledFont(size: 13.5, design: .serif)
                    .foregroundStyle(isSolved || isCurrent ? inkColor.opacity(0.85) : mutedText.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if isSolved {
                    Text(l2mSubs[i].answer).scaledFont(size: 13, weight: .bold, design: .monospaced)
                        .foregroundStyle(.white).frame(width: 34, height: 26)
                        .background(RoundedRectangle(cornerRadius: 7).fill(tealAccent))
                }
            }
            if isSolved {
                Text(l2mSubs[i].work)
                    .scaledFont(size: 11.5, design: .monospaced).foregroundStyle(tealAccent)
                    .padding(.leading, 34)
            }
        }
        .padding(11).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(isSolved ? tealAccent.opacity(0.06) : (isCurrent ? amberAccent.opacity(0.08) : Color.white))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    @ViewBuilder
    private var solveButton: some View {
        if !done {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                solved += 1
                if done { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
            } label: {
                Text("Solve subquestion \(solved + 1)")
                    .scaledFont(size: 14, weight: .semibold).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 11).fill(tealAccent))
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Each rung used the answer below it: 12 fed into 5 + 12 = 17, which fed into 17 - 6 = 11. The hard problem dissolved into three easy ones."
                 : "Solve each rung; its answer carries up into the next.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - DepthStudio (interactive 3)
//
// The payoff: compositional generalisation. The examples in the prompt were
// shallow (2 steps). Drag the test problem deeper. A plain chain mimics the
// depth it saw and stalls; least-to-most decomposes to any depth and holds.
// Reaching the deepest setting completes.

private struct L2MDepth {
    let steps: Int
    let chain: Int   // accuracy
    let l2m: Int
    let note: String
}

private let l2mDepths: [L2MDepth] = [
    L2MDepth(steps: 2, chain: 90, l2m: 95,
             note: "Two steps, exactly as deep as the examples. Both methods handle it fine."),
    L2MDepth(steps: 3, chain: 60, l2m: 93,
             note: "One step deeper than anything shown. The chain starts to slip; the decomposition does not."),
    L2MDepth(steps: 5, chain: 22, l2m: 90,
             note: "Now well beyond the example depth. The chain mostly fails; least-to-most just adds more rungs."),
    L2MDepth(steps: 8, chain: 4, l2m: 86,
             note: "Far deeper than training. A single chain collapses, while decomposition still solves it one small step at a time."),
]

struct DepthStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var reachedDeep = false

    private var idx: Int { min(l2mDepths.count - 1, max(0, Int(level.rounded()))) }
    private var d: L2MDepth { l2mDepths[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("GO DEEPER THAN THE EXAMPLES")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The examples in the prompt were only two steps deep. Drag the test problem deeper. A plain chain tends to copy the depth it saw, while least-to-most just keeps decomposing.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            depthPicker
            bars
            noteCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.32), value: idx)
    }

    private var depthPicker: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(l2mDepths.enumerated()), id: \.offset) { i, p in
                    Text("\(p.steps) steps")
                        .scaledFont(size: 11, weight: i == idx ? .bold : .regular, design: .monospaced)
                        .foregroundStyle(i == idx ? tealAccent : mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            Slider(value: $level, in: 0...Double(l2mDepths.count - 1), step: 1)
                .tint(tealAccent)
                .onChange(of: level) { _, _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    if idx == l2mDepths.count - 1, !reachedDeep {
                        reachedDeep = true
                        progress.markExplored(cardId)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
        }
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: 26) {
            bar(label: "Chain", value: d.chain, tint: l2mRose)
            bar(label: "Least to most", value: d.l2m, tint: tealAccent)
        }
        .frame(height: 150).frame(maxWidth: .infinity).padding(.vertical, 6)
    }

    private func bar(label: String, value: Int, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)%").scaledFont(size: 13, weight: .bold, design: .monospaced)
                .foregroundStyle(tint).contentTransition(.numericText())
            GeometryReader { g in
                VStack { Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.8))
                        .frame(height: max(6, g.size.height * CGFloat(value) / 100))
                }
            }
            .frame(width: 64)
            Text(label).scaledFont(size: 10, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.7)).multilineTextAlignment(.center).frame(width: 84)
        }
    }

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(d.steps) STEPS").scaledFont(size: 9, weight: .bold).tracking(1.0)
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(tealAccent.opacity(0.12)))
            Text(d.note).scaledFont(size: 13, design: .serif).foregroundStyle(inkColor.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(reachedDeep ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(reachedDeep
                 ? "This is compositional generalisation: by reducing any problem to a chain of one-step subproblems, least-to-most solves cases far deeper than the examples it was shown."
                 : "Drag to the deepest problem to see the gap open.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

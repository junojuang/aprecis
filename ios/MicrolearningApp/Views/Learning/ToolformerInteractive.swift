import SwiftUI

// MARK: - Toolformer bespoke interactives
//
// 2023, Schick et al. (Meta). "Toolformer: Language Models Can Teach Themselves
// to Use Tools." The model learns, in a self-supervised way, to insert API
// calls into its own text. It samples candidate calls at many positions,
// executes them, and keeps only the ones whose results make the following
// tokens easier to predict. It is then fine-tuned on that filtered data, so at
// inference it reaches for a calculator, a search box, a calendar, or a
// translator on its own.
//
// Diagrams built around the mechanism:
//   InlineCallStudio  - the model splices an [API call] into a sentence.
//   SelfFilterStudio  - keep only calls that lower the loss on what comes next.
//   ToolboxStudio     - match each sentence to the tool the model would call.

private let tfRose = Color(hex: "d46a6a")
private let tfBlue = Color(hex: "6a8caf")

// MARK: - ToolformerGlyph (cover hero)
//
// A line of text with a bracketed API call glowing in the middle, its result
// flowing back into the sentence.

struct ToolformerGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let midY = h * 0.46
            ZStack {
                // Text baseline.
                ForEach(0..<2, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "f4f1ea").opacity(0.25))
                        .frame(width: w * 0.16, height: 5)
                        .position(x: w * (0.22 + Double(i) * 0.12), y: midY)
                }
                // The API call chip in the middle.
                Text("[Calc \u{2192} 29%]")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(tealAccent.opacity(0.9)))
                    .scaleEffect(0.9 + 0.1 * t)
                    .position(x: w * 0.55, y: midY)
                ForEach(0..<2, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "f4f1ea").opacity(0.25))
                        .frame(width: w * 0.1, height: 5)
                        .position(x: w * (0.74 + Double(i) * 0.1), y: midY)
                }
                Text("THE MODEL CALLS ITS OWN TOOLS")
                    .font(.system(size: 9, weight: .bold)).tracking(1.3)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.5, y: h * 0.78)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { t = 1 }
        }
    }
}

// MARK: - WithoutVsWithToolArt (big-idea illustration)
//
// Same sentence, no tool: a wrong number. With a tool: the call is inlined and
// the number is right.

struct WithoutVsWithToolArt: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NO TOOL").font(.system(size: 9, weight: .bold)).tracking(1.3).foregroundStyle(tfRose)
                (Text("400 of 1400 passed, about ")
                 + Text("35%").foregroundColor(tfRose).bold()
                 + Text(" of them."))
                    .font(.system(size: 13, design: .serif)).foregroundStyle(inkColor.opacity(0.85))
                Text("a confident, wrong guess").font(.system(size: 10, design: .serif)).italic().foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tfRose.opacity(0.05)))

            VStack(alignment: .leading, spacing: 6) {
                Text("WITH A TOOL").font(.system(size: 9, weight: .bold)).tracking(1.3).foregroundStyle(tealAccent)
                (Text("400 of 1400 passed, about ")
                 + Text("[Calc(400/1400)\u{2192}29%]").font(.system(size: 12, design: .monospaced)).foregroundColor(tealAccent)
                 + Text(" 29% of them."))
                    .font(.system(size: 13, design: .serif)).foregroundStyle(inkColor.opacity(0.85))
                Text("the call is run, the result spliced in").font(.system(size: 10, design: .serif)).italic().foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ToolboxArt (illustration)
//
// The small toolbox Toolformer learned: calculator, search, calendar,
// translator, each with a one-line job.

struct ToolboxArt: View {
    private let tools: [(String, String, String)] = [
        ("plusminus.circle.fill", "Calculator", "arithmetic"),
        ("magnifyingglass.circle.fill", "Search / QA", "look up a fact"),
        ("calendar.circle.fill", "Calendar", "today's date"),
        ("globe", "Translate", "across languages"),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(tools.enumerated()), id: \.offset) { _, t in
                HStack(spacing: 10) {
                    Image(systemName: t.0).font(.system(size: 16)).foregroundStyle(tealAccent)
                    Text(t.1).font(.system(size: 13, weight: .semibold, design: .serif)).foregroundStyle(inkColor.opacity(0.85))
                        .frame(width: 96, alignment: .leading)
                    Text(t.2).font(.system(size: 11.5, design: .serif)).italic().foregroundStyle(mutedText)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }
}

// MARK: - InlineCallStudio (interactive 1)
//
// Step a sentence that needs a calculation. Tap to insert the API call, then
// to execute it; the result splices into the text and the wrong guess is
// replaced. Completing both steps completes the card.

struct InlineCallStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var stage = 0   // 0 = guess, 1 = call inserted, 2 = executed

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("SPLICE IN A CALL")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The model is writing a sentence with a number it cannot reliably do in its head. Watch it reach for a calculator mid-sentence, run the call, and drop the result back into the text.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sentenceCard
            actionButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.32), value: stage)
    }

    private var sentenceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE MODEL WRITES").font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(mutedText)
            Group {
                if stage == 0 {
                    (Text("Out of 1400 entrants, 400 passed, which is about ")
                     + Text("35%").foregroundColor(tfRose).bold()
                     + Text("."))
                } else if stage == 1 {
                    (Text("Out of 1400 entrants, 400 passed, which is about ")
                     + Text("[Calculator(400 / 1400)]").font(.system(size: 14, design: .monospaced)).foregroundColor(amberAccent)
                     + Text(" ?"))
                } else {
                    (Text("Out of 1400 entrants, 400 passed, which is about ")
                     + Text("[Calculator(400 / 1400) \u{2192} 0.29]").font(.system(size: 13, design: .monospaced)).foregroundColor(tealAccent)
                     + Text(" ")
                     + Text("29%").foregroundColor(tealAccent).bold()
                     + Text("."))
                }
            }
            .font(.system(size: 15, design: .serif)).foregroundStyle(inkColor.opacity(0.88))
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: stage == 2 ? "checkmark.circle.fill" : (stage == 0 ? "xmark.circle.fill" : "hourglass"))
                    .foregroundStyle(stage == 2 ? tealAccent : (stage == 0 ? tfRose : amberAccent))
                Text(stage == 2 ? "grounded by the tool" : (stage == 0 ? "guessed, and wrong" : "call inserted, not yet run"))
                    .font(.system(size: 11, design: .serif)).italic().foregroundStyle(mutedText)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(stage == 2 ? tealAccent.opacity(0.06) : (stage == 0 ? tfRose.opacity(0.05) : amberAccent.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke((stage == 2 ? tealAccent : (stage == 0 ? tfRose : amberAccent)).opacity(0.35), lineWidth: 1)))
    }

    @ViewBuilder
    private var actionButton: some View {
        if stage < 2 {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                stage += 1
                if stage == 2 { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
            } label: {
                Text(stage == 0 ? "Insert an API call" : "Run the call")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 11).fill(stage == 0 ? amberAccent : tealAccent))
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(stage == 2 ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(stage == 2
                 ? "The call is just text the model wrote, run by an external tool, with the result pasted back. The model decides where a tool would help and writes the call itself."
                 : "Insert the call, then run it, and watch the wrong guess become a real answer.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - SelfFilterStudio (interactive 2)
//
// How Toolformer trains itself. At one position it samples candidate calls,
// runs them, and keeps only the call whose result makes the next words easier
// to predict (lowers the loss). Tap each candidate to see its effect, then keep
// the helpful one. Keeping the right call completes the card.

private struct TFCandidate {
    let label: String
    let result: String
    let lossDrop: Int      // 0..100, how much it helps predict the continuation
    let keep: Bool
    let note: String
}

private let tfCandidates: [TFCandidate] = [
    TFCandidate(label: "No call", result: "\u{2014}", lossDrop: 12, keep: false,
                note: "The baseline. Without help the model must guess the percentage, and often gets it wrong."),
    TFCandidate(label: "Calculator(400 / 1400)", result: "0.29", lossDrop: 88, keep: true,
                note: "This result makes the next words, \"29%\", easy to predict. A big drop in loss, so this call is worth keeping."),
    TFCandidate(label: "Calculator(1400 - 400)", result: "1000", lossDrop: 8, keep: false,
                note: "A valid call, but 1000 has nothing to do with the percentage that follows, so it does not help prediction. Discard it."),
]

struct SelfFilterStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var tapped: Set<Int> = []
    @State private var kept: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("KEEP ONLY WHAT HELPS")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Nobody labelled where tools should go. The model finds out itself: it tries candidate calls and keeps a call only if its result makes the next words easier to predict. Tap each to see, then keep the useful one.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            contextCard
            candidates
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: tapped)
        .animation(.snappy(duration: 0.3), value: kept)
    }

    private var contextCard: some View {
        Text("\u{201C}\u{2026} 400 passed, which is about ___ % of them.\u{201D}")
            .font(.system(size: 14, weight: .semibold, design: .serif)).foregroundStyle(inkColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 11).fill(tfBlue.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(tfBlue.opacity(0.3), lineWidth: 1)))
    }

    private var candidates: some View {
        VStack(spacing: 8) {
            ForEach(Array(tfCandidates.enumerated()), id: \.offset) { i, c in
                candidateRow(i: i, c: c)
            }
        }
    }

    private func candidateRow(i: Int, c: TFCandidate) -> some View {
        let shown = tapped.contains(i)
        let isKept = kept == i
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            tapped.insert(i)
            if shown {
                // second tap on a shown candidate = decide to keep it
                kept = i
                if c.keep {
                    progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 10) {
                    Text(c.label).font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(inkColor.opacity(0.85))
                    if shown {
                        Text("\u{2192} \(c.result)").font(.system(size: 12, design: .monospaced)).foregroundStyle(mutedText)
                    }
                    Spacer(minLength: 0)
                    if isKept {
                        Image(systemName: c.keep ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(c.keep ? tealAccent : tfRose)
                    }
                }
                if shown {
                    HStack(spacing: 8) {
                        Text("HELPS PREDICT").font(.system(size: 8, weight: .bold)).tracking(0.8).foregroundStyle(mutedText)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(mutedText.opacity(0.12)).frame(height: 8)
                                Capsule().fill(c.keep ? tealAccent : tfRose)
                                    .frame(width: max(6, g.size.width * CGFloat(c.lossDrop) / 100), height: 8)
                            }
                        }
                        .frame(height: 10)
                        Text("\(c.lossDrop)%").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.keep ? tealAccent : mutedText)
                    }
                    Text(c.note).font(.system(size: 12, design: .serif)).foregroundStyle(inkColor.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                    if kept == nil {
                        Text("tap again to keep this call")
                            .font(.system(size: 10, weight: .semibold)).foregroundStyle(tealAccent)
                    }
                } else {
                    Text("tap to run it").font(.system(size: 11, design: .serif)).italic().foregroundStyle(tealAccent)
                }
            }
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 11)
                .fill(isKept ? (c.keep ? tealAccent.opacity(0.08) : tfRose.opacity(0.06)) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .stroke(isKept ? (c.keep ? tealAccent : tfRose) : borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        let good = kept != nil && tfCandidates[kept!].keep
        return HStack(spacing: 8) {
            Circle().fill(good ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(good
                 ? "That is the whole training signal: keep a call only when its result lowers the loss on what comes next. No human ever labelled where tools belong."
                 : "Run the candidates, then keep the call whose result best helps predict the next words.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - ToolboxStudio (interactive 3)
//
// Match each sentence to the tool the model should call. Two rounds; both
// correct completes the card.

private struct TFMatch {
    let sentence: String
    let tools: [String]
    let correct: Int
    let note: String
}

private let tfMatches: [TFMatch] = [
    TFMatch(sentence: "\u{201C}The meeting is 18 days from today, on ___.\u{201D}",
            tools: ["Calculator", "Calendar", "Translate"], correct: 1,
            note: "Working out a future date needs to know today's date, so the model calls the calendar."),
    TFMatch(sentence: "\u{201C}The French word for \u{2018}library\u{2019} is ___.\u{201D}",
            tools: ["Calculator", "Calendar", "Translate"], correct: 2,
            note: "A word in another language is a translation task, so the model calls the translator."),
]

struct ToolboxStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var idx = 0
    @State private var picked: Int? = nil
    @State private var solved: Set<Int> = []

    private var m: TFMatch { tfMatches[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("PICK THE RIGHT TOOL")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Toolformer learned a small toolbox and when to reach for each one. Read the sentence and choose the tool the model would call to fill the blank.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text(m.sentence)
                .font(.system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 11).fill(tfBlue.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(tfBlue.opacity(0.3), lineWidth: 1)))

            HStack(spacing: 8) {
                ForEach(Array(m.tools.enumerated()), id: \.offset) { i, t in
                    toolButton(i: i, name: t)
                }
            }

            if let p = picked { feedback(p) }
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: picked)
        .animation(.snappy(duration: 0.3), value: idx)
    }

    private func toolButton(i: Int, name: String) -> some View {
        let isPicked = picked == i
        let isRight = i == m.correct
        return Button {
            guard picked == nil else { return }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            picked = i
            if isRight {
                solved.insert(idx)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if solved.count >= tfMatches.count { progress.markExplored(cardId) }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        } label: {
            Text(name).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(isPicked ? .white : inkColor.opacity(0.8))
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(isPicked ? (isRight ? tealAccent : tfRose) : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .disabled(picked != nil)
    }

    private func feedback(_ p: Int) -> some View {
        let right = p == m.correct
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: right ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14)).foregroundStyle(right ? tealAccent : amberAccent)
            VStack(alignment: .leading, spacing: 6) {
                Text(right ? m.note : "Not quite. Look at what the blank actually needs.")
                    .font(.system(size: 13, weight: .semibold, design: .serif)).foregroundStyle(inkColor.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    if right { if idx < tfMatches.count - 1 { idx += 1; picked = nil } }
                    else { picked = nil }
                } label: {
                    Text(right ? (idx < tfMatches.count - 1 ? "Next sentence \u{2192}" : "Done") : "Try again")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(tealAccent)
                }
                .buttonStyle(.plain)
                .disabled(right && idx >= tfMatches.count - 1)
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill((right ? tealAccent : amberAccent).opacity(0.08)))
    }

    private var statusRow: some View {
        let done = solved.count >= tfMatches.count
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Different blanks need different tools, and the model learned to tell them apart from its own data, then call the right one unprompted."
                 : "Sentences matched: \(solved.count) of \(tfMatches.count)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

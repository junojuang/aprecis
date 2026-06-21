import SwiftUI

// MARK: - Grokking bespoke interactives
//
// 2022, Power et al. (OpenAI). "Grokking: Generalization Beyond Overfitting on
// Small Algorithmic Datasets." Train a small network on a task like modular
// arithmetic and something strange happens. It memorises the training set fast
// (train accuracy hits 100%, validation stays at chance) and looks hopelessly
// overfit. Then, tens of thousands of steps later, long after most people would
// have stopped, validation accuracy suddenly snaps to near 100%. The model has
// "grokked" the rule. Weight decay is what pushes it from memorising to
// generalising.
//
// Diagrams built around the phenomenon:
//   GrokCurveStudio          - slide through training time, watch the late leap.
//   MemorizeVsGeneralizeStudio - a lookup table vs a learned rule on unseen pairs.
//   WeightDecayStudio        - the regulariser that decides whether it groks.

private let gkRose = Color(hex: "d46a6a")
private let gkBlue = Color(hex: "6a8caf")

// MARK: - GrokkingGlyph (cover hero)
//
// A long flat low line that suddenly leaps near the end, with a spark at the
// top: validation accuracy doing nothing for ages, then grokking.

struct GrokkingGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let base = h * 0.74
            let top = h * 0.26
            let kneeX = w * 0.66
            ZStack {
                // Flat-then-leap validation curve, drawn progressively.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.1, y: base))
                    p.addLine(to: CGPoint(x: kneeX, y: base))
                    p.addCurve(to: CGPoint(x: w * 0.88, y: top),
                               control1: CGPoint(x: kneeX + w * 0.06, y: base),
                               control2: CGPoint(x: w * 0.78, y: top))
                }
                .trim(from: 0, to: t)
                .stroke(tealAccent, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))

                // Faint train curve: high almost immediately (the memorisation).
                Path { p in
                    p.move(to: CGPoint(x: w * 0.1, y: base))
                    p.addCurve(to: CGPoint(x: w * 0.24, y: top),
                               control1: CGPoint(x: w * 0.13, y: base),
                               control2: CGPoint(x: w * 0.18, y: top))
                    p.addLine(to: CGPoint(x: w * 0.88, y: top))
                }
                .stroke(mutedText.opacity(0.35), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 4]))

                // The spark at the moment of grokking.
                Image(systemName: "sparkles")
                    .font(.system(size: 20)).foregroundStyle(amberAccent)
                    .position(x: w * 0.88, y: top - 2)
                    .opacity(t > 0.92 ? 1 : 0)
                    .scaleEffect(t > 0.92 ? 1 : 0.4)

                Text("IT CLICKS, EVENTUALLY")
                    .font(.system(size: 9, weight: .bold)).tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.5, y: h * 0.93)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { t = 1 }
        }
    }
}

// MARK: - OverfitVsGrokArt (big-idea illustration)
//
// The textbook story (stop at overfitting) vs grokking (keep going, it
// generalises far later).

struct OverfitVsGrokArt: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("THE TEXTBOOK STORY").font(.system(size: 9, weight: .bold)).tracking(1.3).foregroundStyle(gkRose)
                HStack(spacing: 6) {
                    chip("train 100%", tint: mutedText)
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(mutedText)
                    chip("val stuck", tint: gkRose)
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(mutedText)
                    chip("STOP: overfit", tint: gkRose)
                }
                Text("most training would end right here")
                    .font(.system(size: 10, design: .serif)).italic().foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(gkRose.opacity(0.05)))

            VStack(alignment: .leading, spacing: 6) {
                Text("GROKKING").font(.system(size: 9, weight: .bold)).tracking(1.3).foregroundStyle(tealAccent)
                HStack(spacing: 6) {
                    chip("train 100%", tint: mutedText)
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(mutedText)
                    chip("keep going", tint: gkBlue)
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(mutedText)
                    chip("val 100%", tint: tealAccent)
                }
                Text("generalisation arrives long after overfitting")
                    .font(.system(size: 10, design: .serif)).italic().foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
    private func chip(_ s: String, tint: Color) -> some View {
        Text(s).font(.system(size: 10.5, weight: .semibold)).foregroundStyle(tint)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}

// MARK: - TableVsRuleArt (illustration)
//
// Memorising is a lookup table with holes; grokking is a rule that fills them.

struct TableVsRuleArt: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("MEMORISE").font(.system(size: 9, weight: .bold)).tracking(1.0).foregroundStyle(gkRose)
                grid(filledOnly: true)
                Text("holes on unseen pairs").font(.system(size: 9, design: .serif)).italic().foregroundStyle(mutedText)
            }
            .padding(10).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(gkRose.opacity(0.05)))

            VStack(spacing: 6) {
                Text("GROK").font(.system(size: 9, weight: .bold)).tracking(1.0).foregroundStyle(tealAccent)
                grid(filledOnly: false)
                Text("the rule fills every cell").font(.system(size: 9, design: .serif)).italic().foregroundStyle(mutedText)
            }
            .padding(10).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
    private func grid(filledOnly: Bool) -> some View {
        let n = 5
        return VStack(spacing: 3) {
            ForEach(0..<n, id: \.self) { r in
                HStack(spacing: 3) {
                    ForEach(0..<n, id: \.self) { c in
                        let seen = (r + c) % 2 == 0
                        let on = filledOnly ? seen : true
                        RoundedRectangle(cornerRadius: 2)
                            .fill(on ? (filledOnly ? gkRose.opacity(0.6) : tealAccent.opacity(0.6)) : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(borderColor, lineWidth: 0.8))
                            .frame(width: 15, height: 15)
                    }
                }
            }
        }
    }
}

// MARK: - GrokCurveStudio (interactive 1)
//
// Slide through training time on a log axis. Train accuracy hits 100% almost
// immediately; validation sits at chance for ages, then snaps up. Reaching the
// final step (after the leap) completes the card.

private struct GrokStep {
    let label: String
    let train: Int
    let val: Int
    let note: String
}

private let grokSteps: [GrokStep] = [
    GrokStep(label: "100 steps", train: 25, val: 4,
             note: "Early on the model is bad at everything. It has not even memorised the training set yet."),
    GrokStep(label: "1k steps", train: 100, val: 5,
             note: "It has memorised the training data: perfect on what it has seen, no better than chance on what it hasn't. Classic overfitting."),
    GrokStep(label: "10k steps", train: 100, val: 6,
             note: "Tens of thousands of steps later, still just memorising. Most people would have stopped long ago, calling it overfit and done."),
    GrokStep(label: "100k steps", train: 100, val: 72,
             note: "Then, long after the training loss flatlined, validation accuracy suddenly starts to climb. The model is beginning to grok."),
    GrokStep(label: "1M steps", train: 100, val: 99,
             note: "It now generalises almost perfectly. The same network that looked hopelessly overfit has discovered the underlying rule."),
]

struct GrokCurveStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var reachedGrok = false

    private var idx: Int { min(grokSteps.count - 1, max(0, Int(level.rounded()))) }
    private var s: GrokStep { grokSteps[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("FAST FORWARD THE TRAINING")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("This is one small model learning modular arithmetic. Drag through training time and watch the two accuracies. One shoots up at once; the other does something very strange.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            stepPicker
            bars
            noteCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.32), value: idx)
    }

    private var stepPicker: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(grokSteps.enumerated()), id: \.offset) { i, st in
                    Text(st.label)
                        .font(.system(size: 9.5, weight: i == idx ? .bold : .regular, design: .monospaced))
                        .foregroundStyle(i == idx ? tealAccent : mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            Slider(value: $level, in: 0...Double(grokSteps.count - 1), step: 1)
                .tint(tealAccent)
                .onChange(of: level) { _, _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    if idx == grokSteps.count - 1, !reachedGrok {
                        reachedGrok = true
                        progress.markExplored(cardId)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
        }
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: 26) {
            bar(label: "Train", value: s.train, tint: mutedText)
            bar(label: "Validation", value: s.val, tint: s.val >= 50 ? tealAccent : gkRose)
        }
        .frame(height: 150).frame(maxWidth: .infinity).padding(.vertical, 6)
    }

    private func bar(label: String, value: Int, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)%").font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(tint).contentTransition(.numericText())
            GeometryReader { g in
                VStack { Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.8))
                        .frame(height: max(6, g.size.height * CGFloat(value) / 100))
                }
            }
            .frame(width: 66)
            Text(label).font(.system(size: 10.5, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.7))
        }
    }

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(s.label.uppercased()).font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(tealAccent.opacity(0.12)))
            Text(s.note).font(.system(size: 13, design: .serif)).foregroundStyle(inkColor.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(reachedGrok ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(reachedGrok
                 ? "That late jump is grokking: generalisation that arrives long after the model has memorised the data and looks overfit. The training curve gives no hint it is coming."
                 : "Drag all the way to the end to see what happens long after overfitting.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - MemorizeVsGeneralizeStudio (interactive 2)
//
// What actually changed at the grok point. Before: a lookup table that nails
// seen pairs and guesses on unseen ones. After: a rule that gets unseen pairs
// right too. Toggle the phase; flipping to "after" completes the card.

private struct GrokQuery {
    let prompt: String       // "9 + 6 (mod 13)"
    let answer: String       // correct answer
    let seen: Bool
    let memorizedAnswer: String   // what the memorising model says
}

private let grokQueries: [GrokQuery] = [
    GrokQuery(prompt: "2 + 3 (mod 13)", answer: "5", seen: true,  memorizedAnswer: "5"),
    GrokQuery(prompt: "7 + 4 (mod 13)", answer: "11", seen: true, memorizedAnswer: "11"),
    GrokQuery(prompt: "9 + 6 (mod 13)", answer: "2", seen: false, memorizedAnswer: "7"),
    GrokQuery(prompt: "11 + 8 (mod 13)", answer: "6", seen: false, memorizedAnswer: "0"),
]

struct MemorizeVsGeneralizeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var grokked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("WHAT CHANGED AT THE LEAP")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Before grokking the model is a lookup table: it nails pairs it was trained on and guesses on the rest. Flip to after, and the same model answers pairs it has never seen, because it found the rule.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            toggleRow
            queryList
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: grokked)
    }

    private var toggleRow: some View {
        Toggle(isOn: $grokked) {
            Text(grokked ? "After grokking (1M steps)" : "Before grokking (1k steps)")
                .font(.system(size: 14, weight: .semibold, design: .serif)).foregroundStyle(inkColor)
        }
        .tint(tealAccent)
        .onChange(of: grokked) { _, on in
            UISelectionFeedbackGenerator().selectionChanged()
            if on { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }

    private var queryList: some View {
        VStack(spacing: 8) {
            ForEach(Array(grokQueries.enumerated()), id: \.offset) { _, q in
                row(q)
            }
        }
    }

    private func row(_ q: GrokQuery) -> some View {
        // After grokking everything is correct; before, only seen pairs are.
        let correct = grokked || q.seen
        let shown = correct ? q.answer : q.memorizedAnswer
        return HStack(spacing: 10) {
            Text(q.seen ? "SEEN" : "UNSEEN")
                .font(.system(size: 8, weight: .bold)).tracking(0.8)
                .foregroundStyle(q.seen ? gkBlue : amberAccent)
                .frame(width: 52, alignment: .leading)
            Text(q.prompt)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(inkColor.opacity(0.85))
            Spacer(minLength: 0)
            Text("= \(shown)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(correct ? tealAccent : gkRose)
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? tealAccent : gkRose)
        }
        .padding(11).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(correct ? tealAccent.opacity(0.05) : gkRose.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(grokked ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(grokked
                 ? "Generalisation means getting unseen cases right. Memorising stores answers; grokking learns the function that produces them, so the blanks fill in on their own."
                 : "The unseen pairs are wrong, because a lookup table has no entry for them. Flip the switch.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - WeightDecayStudio (interactive 3)
//
// Grokking is not automatic. Weight decay (pressure toward simpler weights) is
// what tips the model from memorising to generalising. Slide through settings;
// landing on the one that actually groks completes the card.

private struct DecaySetting {
    let label: String
    let valAcc: Int
    let verdict: String
    let groks: Bool
    let note: String
}

private let decaySettings: [DecaySetting] = [
    DecaySetting(label: "None", valAcc: 5, verdict: "Never groks", groks: false,
                 note: "With no pressure to simplify, the network is happy to stay a lookup table forever. Train is perfect, validation never moves."),
    DecaySetting(label: "Tiny", valAcc: 64, verdict: "Groks slowly", groks: false,
                 note: "A little weight decay eventually nudges it toward a rule, but it takes far longer and lands lower."),
    DecaySetting(label: "Just right", valAcc: 99, verdict: "Groks", groks: true,
                 note: "Enough pressure toward simple weights tips the model off the memorising solution and onto the rule. This is the sweet spot."),
    DecaySetting(label: "Too high", valAcc: 18, verdict: "Underfits", groks: false,
                 note: "Crank it too far and the weights are punished so hard the model can't even fit the training data, let alone generalise."),
]

struct WeightDecayStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var foundIt = false

    private var idx: Int { min(decaySettings.count - 1, max(0, Int(level.rounded()))) }
    private var d: DecaySetting { decaySettings[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("THE KNOB THAT DECIDES")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Grokking is not luck. Weight decay, a gentle pull toward simpler weights, is what tips the model from memorising to generalising. Dial it and find the setting that actually groks.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            picker
            outcome
            noteCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.32), value: idx)
    }

    private var picker: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(decaySettings.enumerated()), id: \.offset) { i, st in
                    Text(st.label)
                        .font(.system(size: 9.5, weight: i == idx ? .bold : .regular))
                        .foregroundStyle(i == idx ? tealAccent : mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            Slider(value: $level, in: 0...Double(decaySettings.count - 1), step: 1)
                .tint(tealAccent)
                .onChange(of: level) { _, _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    if d.groks, !foundIt {
                        foundIt = true
                        progress.markExplored(cardId)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
        }
    }

    private var outcome: some View {
        VStack(spacing: 8) {
            HStack {
                Text("WEIGHT DECAY: \(d.label.uppercased())")
                    .font(.system(size: 10, weight: .bold)).tracking(1.0).foregroundStyle(inkColor.opacity(0.7))
                Spacer()
                Text(d.verdict)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(d.groks ? tealAccent : gkRose)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill((d.groks ? tealAccent : gkRose).opacity(0.12)))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(mutedText.opacity(0.12)).frame(height: 14)
                    Capsule().fill((d.groks ? tealAccent : gkRose).opacity(0.85))
                        .frame(width: max(10, g.size.width * CGFloat(d.valAcc) / 100), height: 14)
                }
            }
            .frame(height: 16)
            HStack {
                Text("validation accuracy")
                    .font(.system(size: 10, design: .serif)).italic().foregroundStyle(mutedText)
                Spacer()
                Text("\(d.valAcc)%").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(d.groks ? tealAccent : gkRose).contentTransition(.numericText())
            }
        }
        .padding(13).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 11).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(borderColor, lineWidth: 1)))
    }

    private var noteCard: some View {
        Text(d.note)
            .font(.system(size: 13, design: .serif)).foregroundStyle(inkColor.opacity(0.78))
            .fixedSize(horizontal: false, vertical: true)
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(foundIt ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(foundIt
                 ? "Grokking depends on regularisation. The pressure to use simpler weights is what makes the rule a better deal than the lookup table, so the model finally switches."
                 : "Try each setting. Only one actually tips the model into generalising.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

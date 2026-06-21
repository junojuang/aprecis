import SwiftUI

// MARK: - ReAct bespoke interactives
//
// 2022, Yao et al. (Princeton / Google). "ReAct: Synergizing Reasoning and
// Acting in Language Models." A model that only reasons can talk itself into a
// confident wrong answer. ReAct interleaves Thought (reasoning) with Action
// (calling a tool such as search) and Observation (what the tool returns),
// looping until it finishes. Reasoning decides what to look up; observations
// keep the reasoning honest, cutting hallucination.
//
// Diagrams built around the loop:
//   ReActLoopStudio   - step a Thought -> Action -> Observation trace to an answer.
//   GroundVsGuessStudio- reason-only hallucinates; ReAct looks it up and corrects.
//   ActionMenuStudio  - choose the right action; a wrong one wastes a step.

private let raRose = Color(hex: "d46a6a")

private enum ReActKind {
    case thought, action, observation, finish
    var tag: String {
        switch self {
        case .thought: return "THOUGHT"
        case .action: return "ACTION"
        case .observation: return "OBSERVATION"
        case .finish: return "FINISH"
        }
    }
    var icon: String {
        switch self {
        case .thought: return "brain.head.profile"
        case .action: return "magnifyingglass"
        case .observation: return "eye.fill"
        case .finish: return "checkmark.seal.fill"
        }
    }
    var tint: Color {
        switch self {
        case .thought: return amberAccent
        case .action: return tealAccent
        case .observation: return Color(hex: "6a8caf")
        case .finish: return tealAccent
        }
    }
}

// MARK: - ReActGlyph (cover hero)
//
// Two nodes, a brain (think) and a tool (act), joined in a loop with an
// observation arrow feeding back. The loop draws itself.

struct ReActGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cx = w * 0.5, cy = h * 0.46, r = min(w, h) * 0.22
            let think = CGPoint(x: cx - r, y: cy)
            let act = CGPoint(x: cx + r, y: cy)
            ZStack {
                // Loop arc.
                Circle()
                    .trim(from: 0, to: t)
                    .stroke(tealAccent.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                    .frame(width: r * 2.1, height: r * 2.1)
                    .position(x: cx, y: cy)
                node(icon: "brain.head.profile", tint: amberAccent, at: think)
                node(icon: "wrench.and.screwdriver.fill", tint: tealAccent, at: act)
                Text("think").scaledFont(size: 9, weight: .bold).foregroundStyle(amberAccent)
                    .position(x: think.x, y: think.y + r + 4)
                Text("act").scaledFont(size: 9, weight: .bold).foregroundStyle(tealAccent)
                    .position(x: act.x, y: act.y + r + 4)
                Text("REASON, THEN ACT, THEN LOOK")
                    .scaledFont(size: 9, weight: .bold).tracking(1.4)
                    .foregroundStyle(tealAccent)
                    .position(x: w * 0.5, y: h * 0.92)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: false)) { t = 1 }
        }
    }
    private func node(icon: String, tint: Color, at p: CGPoint) -> some View {
        Image(systemName: icon).scaledFont(size: 18).foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Circle().fill(tint.opacity(0.85)))
            .position(x: p.x, y: p.y)
    }
}

// MARK: - ReasonOnlyVsReActArt (big-idea illustration)
//
// Reason-only: a straight line of thoughts to a confident wrong answer.
// ReAct: thoughts broken by an action and an observation that corrects course.

struct ReasonOnlyVsReActArt: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("REASON ONLY").scaledFont(size: 9, weight: .bold).tracking(1.3).foregroundStyle(raRose)
                HStack(spacing: 6) {
                    pill("thought", .thought); seg; pill("thought", .thought); seg
                    Text("guess").scaledFont(size: 11, weight: .bold, design: .serif).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(raRose))
                }
                Text("no way to check, so it can drift").scaledFont(size: 10, design: .serif).italic()
                    .foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(raRose.opacity(0.05)))

            VStack(alignment: .leading, spacing: 6) {
                Text("REACT").scaledFont(size: 9, weight: .bold).tracking(1.3).foregroundStyle(tealAccent)
                HStack(spacing: 6) {
                    pill("thought", .thought); seg; pill("action", .action); seg; pill("obs", .observation)
                }
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.down.right").scaledFont(size: 10, weight: .bold).foregroundStyle(tealAccent)
                    Text("grounded").scaledFont(size: 11, weight: .bold, design: .serif).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(tealAccent))
                }
                Text("the observation keeps it honest").scaledFont(size: 10, design: .serif).italic()
                    .foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
    private var seg: some View {
        Image(systemName: "arrow.right").scaledFont(size: 8, weight: .bold).foregroundStyle(mutedText)
    }
    private func pill(_ s: String, _ k: ReActKind) -> some View {
        Text(s).scaledFont(size: 10, weight: .semibold).foregroundStyle(k.tint)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(Capsule().fill(k.tint.opacity(0.12)))
    }
}

// MARK: - LoopTraceArt (illustration)
//
// A compact vertical trace: thought, action, observation, repeating, then finish.

struct LoopTraceArt: View {
    private let rows: [(ReActKind, String)] = [
        (.thought, "I need the height of each."),
        (.action, "Search[Eiffel Tower height]"),
        (.observation, "330 m"),
        (.thought, "330 is taller. Done."),
        (.finish, "Eiffel Tower"),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                HStack(spacing: 8) {
                    Image(systemName: r.0.icon).scaledFont(size: 11).foregroundStyle(r.0.tint).frame(width: 16)
                    Text(r.0.tag).scaledFont(size: 8, weight: .bold).tracking(0.8).foregroundStyle(r.0.tint).frame(width: 74, alignment: .leading)
                    Text(r.1).scaledFont(size: 11.5, design: .serif).foregroundStyle(inkColor.opacity(0.82))
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }
}

// MARK: - ReActLoopStudio (interactive 1)
//
// Step a real ReAct trace. Each tap advances Thought -> Action -> Observation,
// looping until Finish. Reaching Finish completes the card.

private struct ReActStep {
    let kind: ReActKind
    let text: String
}

private let reactTrace: [ReActStep] = [
    ReActStep(kind: .thought, text: "I need the height of the Eiffel Tower and the Statue of Liberty, then compare."),
    ReActStep(kind: .action, text: "Search[Eiffel Tower height]"),
    ReActStep(kind: .observation, text: "The Eiffel Tower is about 330 m tall."),
    ReActStep(kind: .thought, text: "Now I need the Statue of Liberty, including its pedestal."),
    ReActStep(kind: .action, text: "Search[Statue of Liberty height with pedestal]"),
    ReActStep(kind: .observation, text: "About 93 m tall including the pedestal."),
    ReActStep(kind: .thought, text: "330 m is much greater than 93 m, so the Eiffel Tower is taller."),
    ReActStep(kind: .finish, text: "Eiffel Tower"),
]

struct ReActLoopStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var shown = 0

    private var done: Bool { shown >= reactTrace.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("RUN THE LOOP")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Which is taller, the Eiffel Tower or the Statue of Liberty? The model cannot just know. Step the loop: it thinks, acts by searching, reads what comes back, and thinks again.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            trace
            stepButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: shown)
    }

    private var trace: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<reactTrace.count, id: \.self) { i in
                if i < shown { stepRow(reactTrace[i]) }
            }
        }
    }

    private func stepRow(_ s: ReActStep) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: s.kind.icon).scaledFont(size: 14).foregroundStyle(s.kind.tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.kind.tag).scaledFont(size: 9, weight: .bold).tracking(1.2).foregroundStyle(s.kind.tint)
                Text(s.text).scaledFont(size: 14, design: s.kind == .action ? .monospaced : .serif)
                    .foregroundStyle(inkColor.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(s.kind == .observation ? s.kind.tint.opacity(0.08) : s.kind.tint.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(s.kind.tint.opacity(0.3), lineWidth: 1)))
    }

    @ViewBuilder
    private var stepButton: some View {
        if !done {
            let next = reactTrace[shown].kind
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                shown += 1
                if done { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
            } label: {
                Text("Next: \(next.tag.capitalized)")
                    .scaledFont(size: 14, weight: .semibold).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 11).fill(next.tint))
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Thought, action, observation, repeat. The reasoning decided what to search, and the observations supplied facts the model could not have known on its own."
                 : "Advance the loop and watch reasoning and acting take turns.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - GroundVsGuessStudio (interactive 2)
//
// Toggle whether the model may look things up. Off: it reasons from memory and
// gives a common wrong answer. On: an action and observation correct it.
// Turning it on completes the card.

struct GroundVsGuessStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var canLookUp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("LET IT CHECK")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Question: what is the capital of Australia? It is a famous trap. Flip the switch to let the model act, not just reason, and watch the answer change.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            toggleRow
            answerCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: canLookUp)
    }

    private var toggleRow: some View {
        Toggle(isOn: $canLookUp) {
            Text("Allow the model to look things up")
                .scaledFont(size: 14, weight: .semibold, design: .serif).foregroundStyle(inkColor)
        }
        .tint(tealAccent)
        .onChange(of: canLookUp) { _, on in
            UISelectionFeedbackGenerator().selectionChanged()
            if on { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if canLookUp {
                row(.thought, "I should not trust my memory on this. Let me check.")
                row(.action, "Search[capital of Australia]")
                row(.observation, "The capital of Australia is Canberra.")
                row(.finish, "Canberra")
            } else {
                row(.thought, "Australia's biggest, most famous city is Sydney, so that must be it.")
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(raRose)
                    Text("Sydney").scaledFont(size: 15, weight: .bold, design: .serif).foregroundStyle(inkColor)
                    Text("(confident, and wrong)").scaledFont(size: 11, design: .serif).italic().foregroundStyle(mutedText)
                }
                .padding(.top, 2)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(canLookUp ? tealAccent.opacity(0.06) : raRose.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke((canLookUp ? tealAccent : raRose).opacity(0.35), lineWidth: 1)))
    }

    private func row(_ k: ReActKind, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: k.icon).scaledFont(size: 12).foregroundStyle(k.tint).frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(k.tag).scaledFont(size: 8, weight: .bold).tracking(1.0).foregroundStyle(k.tint)
                Text(text).scaledFont(size: 13, design: k == .action ? .monospaced : .serif)
                    .foregroundStyle(inkColor.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(canLookUp ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(canLookUp
                 ? "Acting grounded the answer. Instead of leaning on a plausible-sounding memory, the model fetched the fact and corrected itself. That is how ReAct cuts hallucination."
                 : "Reasoning alone produced a confident, wrong guess. Flip the switch to let it check.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - ActionMenuStudio (interactive 3)
//
// At each step the model must pick an action from a small menu. The right one
// moves the task forward; a wrong one wastes a step. Two rounds; getting both
// right completes the card.

private struct ReActChoice {
    let prompt: String          // the current thought / situation
    let options: [String]
    let correct: Int
    let wrongNote: String
    let rightNote: String
}

private let reactChoices: [ReActChoice] = [
    ReActChoice(
        prompt: "Thought: I don't know the director of this film yet.",
        options: ["Finish[my best guess]", "Search[film director]", "Thought: think harder"],
        correct: 1,
        wrongNote: "You still lack the fact. Guessing or just thinking harder cannot conjure it; you need to act.",
        rightNote: "Right. When a fact is missing, the useful move is to act and fetch it."),
    ReActChoice(
        prompt: "Observation: the director is Greta Gerwig. That was the only thing you needed.",
        options: ["Search[Greta Gerwig again]", "Finish[Greta Gerwig]", "Search[something unrelated]"],
        correct: 1,
        wrongNote: "You already have the answer. Another search just wastes a step.",
        rightNote: "Right. Once the observation answers the question, the move is to finish."),
]

struct ActionMenuStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var idx = 0
    @State private var picked: Int? = nil
    @State private var solved: Set<Int> = []

    private var choice: ReActChoice { reactChoices[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("PICK THE NEXT ACTION")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Acting well means choosing the right move, not just any move. Read the situation and pick what ReAct should do next.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptCard
            options
            if let p = picked { feedback(p) }
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: picked)
        .motionAware(.snappy(duration: 0.3), value: idx)
    }

    private var promptCard: some View {
        Text(choice.prompt)
            .scaledFont(size: 14, weight: .semibold, design: .serif).foregroundStyle(inkColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 11).fill(Color(hex: "6a8caf").opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "6a8caf").opacity(0.3), lineWidth: 1)))
    }

    private var options: some View {
        VStack(spacing: 8) {
            ForEach(Array(choice.options.enumerated()), id: \.offset) { i, opt in
                let isPicked = picked == i
                let isRight = i == choice.correct
                Button {
                    guard picked == nil else { return }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    picked = i
                    if isRight {
                        solved.insert(idx)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        if solved.count >= reactChoices.count { progress.markExplored(cardId) }
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(opt).scaledFont(size: 13.5, design: .monospaced).foregroundStyle(inkColor.opacity(0.85))
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        if isPicked {
                            Image(systemName: isRight ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isRight ? tealAccent : raRose)
                        }
                    }
                    .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(isPicked ? (isRight ? tealAccent.opacity(0.08) : raRose.opacity(0.06)) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(isPicked ? (isRight ? tealAccent : raRose) : borderColor, lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .disabled(picked != nil)
            }
        }
    }

    private func feedback(_ p: Int) -> some View {
        let right = p == choice.correct
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: right ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .scaledFont(size: 14).foregroundStyle(right ? tealAccent : amberAccent)
            VStack(alignment: .leading, spacing: 6) {
                Text(right ? choice.rightNote : choice.wrongNote)
                    .scaledFont(size: 13, weight: .semibold, design: .serif).foregroundStyle(inkColor.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    if right {
                        if idx < reactChoices.count - 1 { idx += 1; picked = nil }
                    } else { picked = nil }
                } label: {
                    Text(right ? (idx < reactChoices.count - 1 ? "Next situation \u{2192}" : "Done") : "Try again")
                        .scaledFont(size: 12, weight: .semibold).foregroundStyle(tealAccent)
                }
                .buttonStyle(.plain)
                .disabled(right && idx >= reactChoices.count - 1)
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill((right ? tealAccent : amberAccent).opacity(0.08)))
    }

    private var statusRow: some View {
        let done = solved.count >= reactChoices.count
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Acting is a decision in itself: search when a fact is missing, finish when you have it. Choosing actions well is what makes the loop efficient."
                 : "Situations solved: \(solved.count) of \(reactChoices.count)")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

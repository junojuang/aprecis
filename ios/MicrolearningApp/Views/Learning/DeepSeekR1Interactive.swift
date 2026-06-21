import SwiftUI

// MARK: - DeepSeek-R1 bespoke interactives
//
// 2025, DeepSeek-AI. The reasoning model that learned to think by being
// rewarded for right answers, not by copying worked solutions. These visuals
// follow the story: a reward shapes behaviour, a group of samples is its own
// yardstick (GRPO), and harder problems make the model think longer until it
// spontaneously starts checking itself (the "aha moment").
//
// Three interactives:
//   RewardSignalStudio - reward the answer, watch which habit the model keeps.
//   GRPOGroupStudio    - sample a group, the group's own average is the judge.
//   AhaThinkingStudio  - drag up the difficulty, watch the thinking grow + self-check.

// MARK: - DeepSeekR1Glyph (cover hero)
//
// A question chip on the left. A dashed "thinking" ribbon stretches across to
// a glowing reward star, which resolves into a check. Reads in one beat: a
// reward at the end is the only thing pulling the long thinking into being.

struct DeepSeekR1Glyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let midY = h * 0.5
            ZStack {
                // Thinking ribbon: a dashed line that draws itself left→right.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.20, y: midY))
                    p.addLine(to: CGPoint(x: w * 0.74, y: midY))
                }
                .trim(from: 0, to: t)
                .stroke(style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [3, 5]))
                .foregroundStyle(tealAccent.opacity(0.8))

                // Question chip.
                chip(text: "?", fill: Color(hex: "f4f1ea").opacity(0.10),
                     stroke: Color(hex: "f4f1ea").opacity(0.35), fg: Color(hex: "f4f1ea"))
                    .position(x: w * 0.16, y: midY)

                // Reward star pulsing at the end of the ribbon.
                Image(systemName: "star.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(amberAccent)
                    .scaleEffect(1.0 + 0.16 * sin(t * .pi * 2))
                    .shadow(color: amberAccent.opacity(0.6), radius: 10)
                    .position(x: w * 0.82, y: midY - 30)

                // Resolved answer chip with a check.
                chip(text: "✓", fill: tealAccent, stroke: tealAccent, fg: .white)
                    .position(x: w * 0.84, y: midY)
                    .opacity(t > 0.7 ? 1 : 0.25)

                Text("REWARD")
                    .font(.system(size: 9, weight: .bold)).tracking(1.8)
                    .foregroundStyle(amberAccent)
                    .position(x: w * 0.82, y: midY - 54)
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

// MARK: - RewardLoopArt (big-idea illustration)
//
// A loop: model → answer → reward → back to model. The reward arrow is amber
// and labelled "right / wrong". The shape of the card is the whole idea: the
// only teacher is the score on the final answer.

struct RewardLoopArt: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                node("MODEL", sub: "tries an answer", tint: tealAccent)
                arrow()
                node("ANSWER", sub: "its attempt", tint: inkColor.opacity(0.7))
                arrow()
                node("SCORE", sub: "right or wrong", tint: amberAccent)
            }
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(amberAccent)
                Text("REWARD FLOWS BACK · KEEP WHAT WORKED")
                    .font(.system(size: 9, weight: .bold)).tracking(1.2)
                    .foregroundStyle(amberAccent)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 9).fill(amberAccent.opacity(0.10)))
        }
        .padding(.vertical, 4)
    }

    private func node(_ label: String, sub: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundStyle(tint)
            Text(sub).font(.system(size: 9, design: .serif)).italic()
                .foregroundStyle(inkColor.opacity(0.55))
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.5), lineWidth: 1)))
    }

    private func arrow() -> some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(mutedText)
    }
}

// MARK: - GRPOGroupArt (illustration)
//
// One question, four sampled answers, a dashed baseline at the group average.
// Answers above the line get a teal up-tick; below get an amber down-tick.

struct GRPOGroupArt: View {
    private let scores: [Double] = [0.9, 0.7, 0.35, 0.15]

    var body: some View {
        let avg = scores.reduce(0, +) / Double(scores.count)
        return VStack(alignment: .leading, spacing: 8) {
            Text("ONE QUESTION → A GROUP OF TRIES")
                .font(.system(size: 9, weight: .bold)).tracking(1.2)
                .foregroundStyle(mutedText)
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let barW = w / CGFloat(scores.count) - 12
                ZStack(alignment: .bottomLeading) {
                    // Baseline (group average).
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * (1 - avg)))
                        p.addLine(to: CGPoint(x: w, y: h * (1 - avg)))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [4, 3]))
                    .foregroundStyle(inkColor.opacity(0.45))

                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Array(scores.enumerated()), id: \.offset) { i, s in
                            let above = s >= avg
                            VStack(spacing: 3) {
                                Image(systemName: above ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(above ? tealAccent : amberAccent)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(above ? tealAccent.opacity(0.7) : amberAccent.opacity(0.55))
                                    .frame(width: barW, height: max(6, h * CGFloat(s)))
                            }
                        }
                    }
                }
            }
            .frame(height: 96)
            Text("Above the dashed average → reinforce. Below → discourage.")
                .font(.system(size: 11, design: .serif)).italic()
                .foregroundStyle(inkColor.opacity(0.6))
        }
    }
}

// MARK: - AhaLoopArt (illustration)
//
// A thinking ribbon that runs forward, then loops back on itself - the moment
// the model writes "wait, let me re-check" mid-solution.

struct AhaLoopArt: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.08, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.5))
                    p.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.78),
                                   control: CGPoint(x: w * 0.78, y: h * 0.64))
                    p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.78))
                }
                .stroke(style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [3, 5]))
                .foregroundStyle(tealAccent.opacity(0.85))

                Text("wait, re-check")
                    .font(.system(size: 11, weight: .semibold, design: .serif)).italic()
                    .foregroundStyle(amberAccent)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(amberAccent.opacity(0.12)))
                    .position(x: w * 0.7, y: h * 0.28)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(amberAccent)
                    .position(x: w * 0.92, y: h * 0.78)
            }
        }
    }
}

// MARK: - DistillArt (illustration)
//
// A big "teacher" brain on the left hands its reasoning down to three small
// student models, which now reason too.

struct DistillArt: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 34))
                    .foregroundStyle(tealAccent)
                Text("R1").font(.system(size: 11, weight: .bold)).foregroundStyle(tealAccent)
                Text("teacher").font(.system(size: 9, design: .serif)).italic()
                    .foregroundStyle(inkColor.opacity(0.55))
            }
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(mutedText)
                Text("its reasoning").font(.system(size: 8, weight: .semibold)).tracking(0.8)
                    .foregroundStyle(mutedText)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["1.5B", "7B", "32B"], id: \.self) { size in
                    HStack(spacing: 7) {
                        Image(systemName: "brain")
                            .font(.system(size: 14)).foregroundStyle(amberAccent)
                        Text("small model · \(size)")
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(inkColor.opacity(0.75))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - RewardSignalStudio (interactive 1)
//
// A problem with two candidate answers: a fast guess and a worked-out, checked
// solution. The reader hands the reward to one. Rewarding the worked answer
// teaches the model the habit that actually earns points: think, then verify.
// Exploration completes after the reader rewards the right approach twice.

private struct R1RewardScene: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let prompt: String
    let quick: String          // fast, shallow attempt (wrong)
    let worked: String         // long, checked attempt (right)
    let learn: String          // what the model keeps when worked is rewarded
}

private let r1RewardScenes: [R1RewardScene] = [
    R1RewardScene(
        prompt: "What is 17 × 24?",
        quick: "\u{2248} 400. Looks about right.",
        worked: "17 \u{00D7} 24 = 17 \u{00D7} 25 \u{2212} 17 = 425 \u{2212} 17 = 408. Check: 408 \u{00F7} 24 = 17. \u{2713}",
        learn: "Break it down, then check the answer back."),
    R1RewardScene(
        prompt: "Is 91 a prime number?",
        quick: "Yes, it looks prime.",
        worked: "Try small factors: 91 = 7 \u{00D7} 13. So no, 91 is not prime.",
        learn: "Test the claim before committing to it."),
    R1RewardScene(
        prompt: "Next in the sequence: 2, 6, 12, 20, __ ?",
        quick: "26.",
        worked: "Gaps are 4, 6, 8, growing by 2. Next gap is 10, so 20 + 10 = 30.",
        learn: "Find the rule, don't guess from the surface."),
]

struct RewardSignalStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var sceneIdx = 0
    @State private var verdict: Bool? = nil      // which candidate was rewarded: true = worked
    @State private var rewardedRight: Set<Int> = []

    private var scene: R1RewardScene { r1RewardScenes[sceneIdx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("HAND OUT THE REWARD")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The model tried this problem two ways. You are the reward. Give the point to the answer you'd keep. That single choice is the only thing teaching it how to think.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptCard
            candidate(isWorked: false, text: scene.quick)
            candidate(isWorked: true, text: scene.worked)
            learnRow
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: verdict)
        .animation(.snappy(duration: 0.3), value: sceneIdx)
    }

    private var promptCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 16)).foregroundStyle(amberAccent)
            Text(scene.prompt)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(amberAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(amberAccent.opacity(0.3), lineWidth: 1)))
    }

    private func candidate(isWorked: Bool, text: String) -> some View {
        let chosen = verdict == isWorked && verdict != nil
        let isRightChoice = isWorked
        return Button {
            reward(isWorked: isWorked)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(isWorked ? "WORKED IT OUT" : "QUICK GUESS")
                        .font(.system(size: 9, weight: .bold)).tracking(1.4)
                        .foregroundStyle(isWorked ? tealAccent : mutedText)
                    Text(text)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: chosen
                      ? (isRightChoice ? "star.fill" : "xmark.circle.fill")
                      : "star")
                    .font(.system(size: 16))
                    .foregroundStyle(chosen ? (isRightChoice ? amberAccent : mutedText) : mutedText.opacity(0.5))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(chosen && isRightChoice ? tealAccent.opacity(0.08) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(chosen && isRightChoice ? tealAccent : borderColor,
                            lineWidth: chosen && isRightChoice ? 1.5 : 1)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var learnRow: some View {
        if let v = verdict {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: v ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(v ? tealAccent : amberAccent)
                VStack(alignment: .leading, spacing: 6) {
                    Text(v
                         ? "Rewarded. The model keeps this habit: \(scene.learn)"
                         : "That answer was wrong, so no point. The model learns to do less of that.")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        verdict = nil
                        sceneIdx = (sceneIdx + 1) % r1RewardScenes.count
                    } label: {
                        Text(v ? "Next problem \u{2192}" : "Try again")
                            .font(.system(size: 12, weight: .semibold))
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
        let done = rewardedRight.count >= 2
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "You rewarded the worked-out answer twice. Do this a few million times and the model teaches itself to reason. No worked examples ever shown."
                 : "Right answers rewarded: \(rewardedRight.count) of 2")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reward(isWorked: Bool) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        verdict = isWorked
        if isWorked {
            rewardedRight.insert(sceneIdx)
            if rewardedRight.count >= 2 {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - GRPOGroupStudio (interactive 2)
//
// One hard question. Tap to sample a GROUP of answers, each with a score. The
// group's own average is the dashed baseline - no separate judge network.
// Above-average answers are reinforced, below-average ones discouraged. Sample
// a second group to see the baseline is always relative to the group itself.

private struct R1GroupSample: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let answers: [(label: String, score: Double)]
}

private let r1Groups: [R1GroupSample] = [
    R1GroupSample(answers: [
        ("0.875 \u{2713}", 0.95),
        ("7/8",            0.90),
        ("0.75",           0.30),
        ("1/2",            0.10),
    ]),
    R1GroupSample(answers: [
        ("0.5",            0.20),
        ("0.875 \u{2713}", 0.95),
        ("0.6",            0.35),
        ("0.8",            0.55),
    ]),
]

struct GRPOGroupStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var groupIdx = 0
    @State private var seen: Set<Int> = [0]

    private var group: R1GroupSample { r1Groups[groupIdx] }
    private var avg: Double {
        group.answers.map(\.score).reduce(0, +) / Double(group.answers.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("GRPO · LEARN FROM THE GROUP")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("For one question, the model writes a whole group of answers. Each gets a score. The group's own average (dashed line) becomes the bar to beat, with no separate judge model needed. Beat the average, get reinforced.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            questionCard
            groupChart
            sampleButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.35), value: groupIdx)
    }

    private var questionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 16)).foregroundStyle(amberAccent)
            Text("Flip a fair coin 3 times. P(at least one head)?")
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

    private var groupChart: some View {
        let a = avg
        return VStack(alignment: .leading, spacing: 8) {
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                ZStack(alignment: .bottomLeading) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * (1 - a)))
                        p.addLine(to: CGPoint(x: w, y: h * (1 - a)))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [4, 3]))
                    .foregroundStyle(inkColor.opacity(0.5))

                    Text("group avg")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(inkColor.opacity(0.55))
                        .position(x: w - 34, y: h * (1 - a) - 9)

                    HStack(alignment: .bottom, spacing: 14) {
                        ForEach(Array(group.answers.enumerated()), id: \.offset) { _, ans in
                            let above = ans.score >= a
                            VStack(spacing: 4) {
                                Image(systemName: above ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(above ? tealAccent : amberAccent)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(above ? tealAccent.opacity(0.75) : amberAccent.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: max(8, h * CGFloat(ans.score) * 0.82))
                                Text(ans.label)
                                    .font(.system(size: 9, weight: .medium, design: .serif))
                                    .foregroundStyle(inkColor.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .frame(height: 130)
        }
    }

    private var sampleButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            groupIdx = (groupIdx + 1) % r1Groups.count
            seen.insert(groupIdx)
            if seen.count >= r1Groups.count {
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "dice.fill").font(.system(size: 13))
                Text("Sample another group")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(Capsule().fill(tealAccent))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        let done = seen.count >= r1Groups.count
        return HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Different group, different average, same rule. The baseline is free: it's just the group's mean. That's the trick that lets GRPO skip the heavy critic network PPO needs."
                 : "Groups sampled: \(seen.count) of \(r1Groups.count)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - AhaThinkingStudio (interactive 3)
//
// Drag the difficulty up. The model's thinking ribbon gets longer, the token
// count climbs, and at the hardest setting a self-check ("wait, let me
// re-check") appears on its own - the emergent "aha moment" of R1-Zero.

private struct R1Difficulty: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let label: String
    let tokens: Int
    let trace: [String]
    let aha: Bool
}

private let r1Difficulties: [R1Difficulty] = [
    R1Difficulty(label: "Warm-up", tokens: 40, trace: [
        "2 + 2 = 4.",
    ], aha: false),
    R1Difficulty(label: "Easy", tokens: 120, trace: [
        "Need 12% of 250.",
        "10% is 25, 2% is 5, so 30.",
    ], aha: false),
    R1Difficulty(label: "Tricky", tokens: 380, trace: [
        "A train leaves at 60 mph, another at 40 mph, 200 mi apart.",
        "Closing speed = 100 mph.",
        "Time = 200 / 100 = 2 hours.",
    ], aha: false),
    R1Difficulty(label: "Hard", tokens: 1100, trace: [
        "Find all x: x\u{00B2} \u{2212} 5x + 6 = 0.",
        "Factor: (x \u{2212} 2)(x \u{2212} 3) = 0, so x = 2 or 3.",
        "Wait, let me re-check by plugging back in.",
        "2\u{00B2} \u{2212} 10 + 6 = 0 \u{2713}.  3\u{00B2} \u{2212} 15 + 6 = 0 \u{2713}.",
        "Both check out. Answer: x \u{2208} {2, 3}.",
    ], aha: true),
]

struct AhaThinkingStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var reachedHard = false

    private var idx: Int { min(r1Difficulties.count - 1, max(0, Int(level.rounded()))) }
    private var diff: R1Difficulty { r1Difficulties[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("DRAG UP THE DIFFICULTY")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Nobody told the model to think longer on hard problems. It discovered that on its own, just chasing the reward. Slide up the difficulty and watch the thinking grow until it starts checking its own work.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            difficultyPicker
            tokenMeter
            traceCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: idx)
    }

    private var difficultyPicker: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(r1Difficulties.enumerated()), id: \.offset) { i, d in
                    Text(d.label)
                        .font(.system(size: 11, weight: i == idx ? .bold : .regular))
                        .foregroundStyle(i == idx ? tealAccent : mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            Slider(value: $level, in: 0...Double(r1Difficulties.count - 1), step: 1)
                .tint(tealAccent)
                .onChange(of: level) { _, _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    if idx == r1Difficulties.count - 1, !reachedHard {
                        reachedHard = true
                        progress.markExplored(cardId)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
        }
    }

    private var tokenMeter: some View {
        HStack(spacing: 10) {
            Text("THINKING")
                .font(.system(size: 9, weight: .bold)).tracking(1.4)
                .foregroundStyle(mutedText)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(inkColor.opacity(0.07))
                    Capsule().fill(LinearGradient(colors: [tealAccent, amberAccent],
                                                  startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(min(1, Double(diff.tokens) / 1100.0)))
                }
            }
            .frame(height: 8)
            Text("\(diff.tokens) tok")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(inkColor.opacity(0.7))
                .frame(width: 64, alignment: .trailing)
        }
    }

    private var traceCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(tealAccent)
                Text("THE MODEL'S SCRATCHPAD")
                    .font(.system(size: 10, weight: .bold)).tracking(1.4)
                    .foregroundStyle(tealAccent)
            }
            ForEach(Array(diff.trace.enumerated()), id: \.offset) { _, line in
                let isAha = line.lowercased().hasPrefix("wait")
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(isAha ? amberAccent : tealAccent.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(line)
                        .font(.system(size: 13, design: .serif))
                        .italic(isAha)
                        .foregroundStyle(isAha ? amberAccent : inkColor.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if diff.aha {
                Text("\u{2191} That self-check appeared on its own. The paper calls it the \u{201C}aha moment.\u{201D}")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(amberAccent)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(reachedHard ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(reachedHard
                 ? "From one line to a checked, multi-step solution, all emergent. Longer thinking on harder problems was never programmed; the reward pulled it out."
                 : "Slide all the way to Hard to see the aha moment.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
